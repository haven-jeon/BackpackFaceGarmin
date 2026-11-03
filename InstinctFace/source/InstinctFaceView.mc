import Toybox.ActivityMonitor;
import Toybox.Activity;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// 백패킹용 워치 페이스 (Instinct 3 Solar 176x176 1bpp, 우상단 서브스크린 113,0,62x62)
//
//  ┌──────────────┬─(sub)─┐
//  │ 10월 27일 화  │ 2:10  │  ← 일몰(밤이면 일출)까지 남은 시간, 링 = 지금 태양광 충전 세기
//  │  [top1]      │ 일몰  │
//  │  [top2]      └───────┘  ← 정보 칸 3개 (기본: 일출·일몰 / 오늘 기온 범위 / 지명)
//  │  [top3]                │
//  ┌────────────────────────┐
//  │ ≈≈≈ ● ≈≈≈ 🦌 ≈≈≈≈≈≈≈≈ │  ← 하늘(물결 띠)을 가로지르는 해 = 일출~일몰 진행, 능선 위 고라니 (한 시간마다 자리 이동)
//  │ /\/\/\ 10:42 /\/\/\/\ │  ← 산맥 위 시각 (파타고라니 오마주 배너), 숫자 안 산그리메
//  └────────────────────────┘
//  │ [row1]  [row2]  [row3] │  ← 정보 칸 3개 (기본: 고도 / 오늘 오른 높이 / 기온)
//  │ [low1]  [low3]  [low2] │  ← 정보 칸 3개 (기본: 배터리 일수 / 걸음 수 / 체력)
//  │     ☁ 흐려짐            │  ← 3시간 기압 추세로 본 날씨 전망 (폭풍 가능성이면 반전 경고)
//  └────────────────────────┘
// 정보 칸은 폰의 Garmin Connect 앱 > 워치 페이스 설정에서 고른다 (resources/settings).
class InstinctFaceView extends WatchUi.WatchFace {

    hidden var _sub = null;          // 서브스크린 영역 (없는 기기면 null)
    hidden var _solarDrawn = -1;     // 서브스크린 링에 마지막으로 그린 태양광 세기
    const SOLAR_STEP = 5;            // 링을 다시 그릴 태양광 세기 변화 (%p)
    hidden var _slots as Array<Number> = Slots.DEFAULTS;   // 칸마다 보일 정보 (Slots.mc, 폰 설정)
    hidden var _kor = null;          // 한글 비트맵 폰트 (design/gen_korfont.py). 시계 언어와 무관하게 한글을 그린다

    hidden var _glyph as Array<WatchUi.BitmapResource or Null> = [null, null, null, null];   // 시각 숫자 캐시
    hidden var _glyphDigit as Array<Number> = [-1, -1, -1, -1];
    hidden var _colon = null;
    hidden var _banner = null;       // 하늘·산맥 배너
    hidden var _deer = null;         // 고라니 (지금 자리의 비트맵)
    hidden var _deerHour = -1;       // 고라니 자리를 고른 시각(시 단위). 한 시간마다 자리를 옮긴다
    hidden var _deerX = 0;
    hidden var _deerY = 0;

    // 일출·일몰 캐시 (현지 날짜가 바뀌거나 위치를 처음 얻을 때 다시 계산)
    hidden var _sunDay = -1;
    hidden var _rise = null;         // 오늘 일출 (unix 초)
    hidden var _set = null;          // 오늘 일몰
    hidden var _riseNext = null;     // 내일 일출
    hidden var _setPrev = null;      // 어제 일몰 (새벽에 밤 비율 계산용)
    hidden var _sunLoc = null;       // 지금 값을 계산한 위치 [lat, lon]
    hidden var _locAt = -1;          // 마지막으로 위치를 확인한 시각

    // 기압 추세 캐시 (10분마다)
    hidden var _baroAt = -1;
    hidden var _baroTrend = null;    // -2..2, 판단할 수 없으면 null
    hidden var _baroNote = "측정 중";  // 판단할 수 없을 때 표시할 이유
    // 움직였는지 판단용 걸음 기록 [시각, 누적 걸음] (기압 판정과 함께 10분마다, 최근 3시간만)
    hidden var _stepLog as Array<Array<Number>> = [];
    hidden var _stepBase = 0;        // 자정에 걸음 수가 0으로 돌아가도 이어지게 더해 둔 값
    hidden var _stepRaw = 0;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Dc) as Void {
        if (WatchUi has :getSubscreen) {
            _sub = WatchUi.getSubscreen();
        }
        _kor = WatchUi.loadResource(Rez.Fonts.Kor);
        _colon = WatchUi.loadResource(Rez.Drawables.TColon);
        _banner = WatchUi.loadResource(Rez.Drawables.Banner);
        loadSettings();
    }

    // 폰에서 칸 설정을 바꾸면 App.onSettingsChanged 에서 불린다
    function loadSettings() as Void {
        _slots = Slots.load();
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        // 글자 배경을 투명으로 둬야 위아래 줄이 서로 덮지 않는다
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_SHORT);
        updateSun(now.value(), info.day);

        drawTopLeft(dc, info);
        drawSubscreen(dc, w, now.value());
        drawBanner(dc, now.value());
        drawTime(dc, w);
        drawBottomSlots(dc, w);
        drawBaro(dc, w, h, now.value());
    }

    // 절전 중에도 1초마다 불린다. Connect IQ에는 태양광 값이 바뀔 때 알려 주는 이벤트가 없어서
    // 여기서 값을 확인하고, 그린 값과 SOLAR_STEP 이상 차이 날 때만 서브스크린을 다시 그린다.
    // 해를 향하면 링이 바로 반응하고, 값이 조금씩 출렁일 때는 그리지 않는다 (onUpdate는 절전 중 1분에 한 번뿐)
    function onPartialUpdate(dc as Dc) as Void {
        if (_sub == null) { return; }
        var s = solarNow();
        var diff = s - _solarDrawn;
        if (diff.abs() < SOLAR_STEP && !(s == 0 && _solarDrawn > 0)) { return; }
        dc.setClip(_sub.x, _sub.y, _sub.width, _sub.height);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(_sub.x, _sub.y, _sub.width, _sub.height);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        drawSubscreen(dc, dc.getWidth(), Time.now().value());
        dc.clearClip();
    }

    // 지금 태양광 충전 세기 0~100 (지원하지 않는 기기면 0)
    hidden function solarNow() as Number {
        var stats = System.getSystemStats();
        var s = (stats has :solarIntensity) ? stats.solarIntensity : null;
        if (s == null || s < 0) { return 0; }
        return s > 100 ? 100 : s.toNumber();
    }

    // ---- 좌상단: 날짜 + 정보 칸 3개 (top1~3) ----
    hidden function drawTopLeft(dc as Dc, info as Gregorian.Info) as Void {
        var cx = 58;
        // FORMAT_SHORT: month 1~12, day_of_week 1(일)~7(토)
        var week = ["일", "월", "화", "수", "목", "금", "토"];
        dc.drawText(cx, 12, _kor,
            Lang.format("$1$월 $2$일 $3$", [info.month, info.day, week[(info.day_of_week as Number) - 1]]),
            Graphics.TEXT_JUSTIFY_CENTER);
        // 줄 간격 13px. 셋째 줄 아래로는 배너 위로 튀어나온 고라니 머리(y=64~)가 있어 더 내릴 수 없다
        for (var i = 0; i < 3; i++) {
            Slots.draw(dc, _kor, _slots[i], cx, 25 + 13 * i, [_rise, _set]);
        }
    }

    // ---- 서브스크린: 다음 일몰/일출까지 남은 시간 + 태양광 충전 세기 링 ----
    hidden function drawSubscreen(dc as Dc, w as Number, now as Number) as Void {
        var cx = (_sub != null) ? _sub.x + _sub.width / 2 : w - 32;
        var cy = (_sub != null) ? _sub.y + _sub.height / 2 : 32;
        var r = (_sub != null) ? _sub.width / 2 - 2 : 29;

        // 지금이 낮이면 [일출, 일몰], 밤이면 [직전 일몰, 다음 일출] 구간
        var rising = false;
        var from = _rise;
        var to = _set;
        if (_rise != null && now < _rise) {
            rising = true; from = _setPrev; to = _rise;
        } else if (_set != null && now >= _set) {
            rising = true; from = _set; to = _riseNext;
        }

        // 둘레 바: 지금 태양광 충전 세기 (0~100%). 12시 방향에서 시계 방향으로, 실내·밤에는 비어 있다
        dc.setPenWidth(1);
        dc.drawCircle(cx, cy, r);
        var solar = solarNow();
        _solarDrawn = solar;
        if (solar > 0) {
            var frac = solar / 100.0;
            dc.setPenWidth(4);
            dc.drawArc(cx, cy, r - 3, Graphics.ARC_CLOCKWISE, 90, frac >= 1.0 ? 90.01 : 90 - 360 * frac);
            dc.setPenWidth(1);
        }

        if (from != null && to != null && to > from) {
            var left = (to - now) / 60;
            dc.drawText(cx, cy - 9, Graphics.FONT_MEDIUM,
                Lang.format("$1$:$2$", [left / 60, (left % 60).format("%02d")]),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            dc.drawText(cx, cy - 9, Graphics.FONT_MEDIUM, "--:--",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
        // 아이콘은 9px로 작아 텐트처럼 보여서 글자로. 링 안쪽이 아래로 갈수록 좁아 숫자 바로 밑에 둔다
        dc.drawText(cx, cy + 3, _kor, rising ? "일출" : "일몰", Graphics.TEXT_JUSTIFY_CENTER);
    }

    // ---- 파타고라니 배너: 물결 띠 하늘 + 산맥 + 고라니, 해가 하늘을 가로지른다 ----
    // 배너·고라니 비트맵과 배치 상수(Banner.mc)는 design/gen_banner.py 로 생성
    hidden function drawBanner(dc as Dc, now as Number) as Void {
        dc.drawBitmap(Banner.X, Banner.Y, _banner);

        // 해: 낮에는 흰 테두리 + 검정 원, 밤에는 일출(또는 일몰) 쪽 끝에 속이 빈 원
        var sunX = (Banner.SKY_X0 + Banner.SKY_X1) / 2;
        if (_rise != null && _set != null) {
            var frac = (now - _rise).toFloat() / (_set - _rise);
            var day = frac >= 0.0 && frac < 1.0;
            if (frac < 0.0) { frac = 0.0; }
            if (frac > 1.0) { frac = 1.0; }
            var px = Banner.SKY_X0 + ((Banner.SKY_X1 - Banner.SKY_X0) * frac).toNumber();
            sunX = px;
            var py = Banner.SUN_Y_LOW - ((Banner.SUN_Y_LOW - Banner.SUN_Y_HIGH) * Math.sin(Math.PI * frac)).toNumber();
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(px, py, 4);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            if (day) {
                dc.fillCircle(px, py, 2);
            } else {
                dc.drawCircle(px, py, 2);
            }
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }

        // 고라니는 해 위에 (해가 지나갈 때 가려지도록)
        placeDeer(now, sunX);
        dc.drawBitmap(_deerX, _deerY, _deer);
    }

    // 한 시간마다 능선 위 자리를 무작위로 옮긴다. 늘 해 쪽을 바라보고, 해와 겹치지 않는 자리만 고른다.
    // 자리·자리별 비트맵은 design/gen_banner.py 가 능선 꼴에 맞춰 미리 만든다 (Banner.DEER_L / DEER_R)
    hidden function placeDeer(now as Number, sunX as Number) as Void {
        var hour = now / 3600;
        if (hour == _deerHour && _deer != null) { return; }
        _deerHour = hour;

        // 해 왼쪽에 서면 오른쪽(해)을 보고, 해 오른쪽에 서면 왼쪽을 본다
        var picks = [] as Array<Array<Number>>;     // [오른쪽 보기 0/1, 자리 번호]
        for (var side = 0; side < 2; side++) {
            var spots = side == 1 ? Banner.DEER_R : Banner.DEER_L;
            for (var i = 0; i < spots.size(); i++) {
                var cx = spots[i][0] + spots[i][2] / 2;
                if ((side == 1 && cx < sunX - 14) || (side == 0 && cx > sunX + 14)) { picks.add([side, i]); }
            }
        }
        if (picks.size() == 0) { picks.add([0, 0]); }

        // 시각으로 정한 의사 난수: 같은 시간 안에서는 그대로, 시간이 바뀌면 다른 자리
        var r = ((hour.toLong() * 1103515245l + 12345l) / 65536l) % picks.size();
        var p = picks[r.toNumber()];
        var right = p[0] == 1;
        var spot = (right ? Banner.DEER_R : Banner.DEER_L)[p[1]];
        _deerX = spot[0];
        _deerY = spot[1];
        _deer = null;                               // 이전 비트맵을 먼저 놓아 메모리를 아낀다
        _deer = WatchUi.loadResource(Banner.deerIds(right)[p[1]]);
    }

    // ---- 시각: 산 위에 흰 슬랩 세리프, 숫자 안에 산그리메 (design/gen_banner.py 로 생성한 자리별 비트맵) ----
    hidden function drawTime(dc as Dc, w as Number) as Void {
        var clock = System.getClockTime();
        var hour = clock.hour;
        if (!System.getDeviceSettings().is24Hour) {
            hour = hour % 12;
            if (hour == 0) { hour = 12; }
        }
        var x0 = w / 2 - Banner.DIGIT_W / 2;
        var digits = [hour / 10, hour % 10, clock.min / 10, clock.min % 10];
        for (var i = 0; i < 4; i++) {
            dc.drawBitmap(x0 + Banner.DIGIT_XS[i], Banner.DIGIT_Y, glyph(i, digits[i]));
        }
        dc.drawBitmap(x0 + Banner.COLON_X, Banner.DIGIT_Y, _colon);
    }

    // 자리마다 지금 보이는 숫자 비트맵 하나만 들고 있다가 숫자가 바뀔 때만 새로 읽는다
    hidden function glyph(pos as Number, d as Number) as WatchUi.BitmapResource {
        if (_glyphDigit[pos] != d) {
            _glyph[pos] = WatchUi.loadResource(Banner.digitIds()[pos][d]);
            _glyphDigit[pos] = d;
        }
        return _glyph[pos] as WatchUi.BitmapResource;
    }

    // ---- 배너 아래: 정보 칸 3칸 x 2줄 (row1~3 / low1·low3·low2) ----
    hidden function drawBottomSlots(dc as Dc, w as Number) as Void {
        var sun = [_rise, _set];
        // 두 줄 모두 세 칸을 나란히. 화면 아래 모서리가 좁아지므로 배너 바로 밑으로 바짝 붙였다
        // 첫 줄(폭 약 155px) 기본값: 고도 · 오늘 오른 높이 · 기온
        Slots.drawRow(dc, _kor, [_slots[3], _slots[4], _slots[5]], w / 2, 136, sun, 5, 155);
        // 둘째 줄(폭 약 138px) 기본값: 배터리 · 걸음 수 · 체력
        Slots.drawRow(dc, _kor, [_slots[6], _slots[8], _slots[7]], w / 2, 148, sun, 4, 138);
    }

    // ---- 날씨 전망: 3시간 기압 추세를 아이콘 + 단어로 ----
    hidden function drawBaro(dc as Dc, w as Number, h as Number, now as Number) as Void {
        if (_baroAt < 0 || now - _baroAt >= 600) {
            logSteps(now);
            updateBaro(now);
            _baroAt = now;
        }
        var y = 161;
        var str = _baroNote;
        if (_baroTrend != null) {
            str = ["폭풍 주의", "흐려짐", "유지", "맑아짐", "맑아짐"][_baroTrend + 2];
        }
        var fh = dc.getFontHeight(_kor);
        var tw = dc.getTextWidthInPixels(str, _kor);
        var total = tw + 18;
        var x = w / 2 - total / 2;
        var cy = y + fh / 2;

        // 폭풍 가능성은 반전해서 멀리서도 눈에 띄게
        var warn = _baroTrend != null && _baroTrend <= -2;
        if (warn) {
            dc.fillRoundedRectangle(x - 5, y, total + 10, fh + 1, 4);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        }
        if (_baroTrend == null) {
            dc.drawText(x + 6, y, _kor, "~", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (_baroTrend >= 1) {
            Icons.sun(dc, x + 6, cy);
        } else if (_baroTrend == 0) {
            Icons.trend(dc, x + 6, cy, 0);
        } else if (_baroTrend == -1) {
            // 기온이 0°C 이하면 눈, 아니면 비 (기온은 폰 날씨, 없으면 비)
            var t = Slots.temperature();
            dc.drawBitmap(x, y + 1, Slots.emoji(t != null && t <= 0 ? Rez.Drawables.EmojiSnow : Rez.Drawables.EmojiDrop));
        } else {
            Icons.bolt(dc, x + 6, cy);
        }
        dc.drawText(x + 18, y, _kor, str, Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    // ================= 데이터 =================

    // 날짜가 바뀌면 다시 계산하고, 그 사이에는 1시간마다 위치를 확인해 5km 넘게 이동했을 때만 다시 계산한다
    hidden function updateSun(now as Number, day as Number) as Void {
        var newDay = _sunDay != day || _set == null;
        if (!newDay && now - _locAt < 3600) { return; }
        _locAt = now;
        var loc = SunTimes.getLocation();
        if (loc == null) { return; }
        if (!newDay && _sunLoc != null && SunTimes.distanceKm(_sunLoc, loc) <= 5.0) { return; }
        _sunLoc = loc;
        var lat = loc[0];
        var lon = loc[1];
        // 현지 정오를 기준으로 계산한다. 자정 직후 시각을 넣으면 SunTimes.event가 어제 날짜를 고른다
        var noon = Time.today().value() + 12 * 3600;
        _rise = SunTimes.event(lat, lon, noon, true);
        _set = SunTimes.event(lat, lon, noon, false);
        _riseNext = SunTimes.event(lat, lon, noon + 86400, true);
        _setPrev = SunTimes.event(lat, lon, noon - 86400, false);
        _sunDay = day;
    }

    // 3시간 기압 변화(hPa)로 추세 판정.
    // 시계 고도도 기압으로 계산하므로, 한자리에 있어도 기압이 크게 떨어지면 고도가 바뀐 것처럼 보인다.
    // 그래서 고도가 50m 넘게 바뀌었을 때 걸음 수로 실제로 움직였는지 본다:
    //   걸음이 STILL_STEPS 미만이고 고도 변화가 150m 이하면 → 제자리. 기압 변화는 날씨로 본다 (폭풍 놓치지 않게)
    //   그 밖(걸었거나, 걷지 않았는데 150m 넘게 바뀜 = 차량 이동 등) → "이동 중"
    //   걸음 기록이 2시간이 안 되면 (워치 페이스가 막 시작됨) → "이동 중"
    hidden function updateBaro(now as Number) as Void {
        _baroTrend = null;
        _baroNote = "기압계 없음";
        if (!(Toybox has :SensorHistory) || !(SensorHistory has :getPressureHistory)) { return; }

        var period = new Time.Duration(3 * 3600);
        var p = SensorHistory.getPressureHistory({ :period => period, :order => SensorHistory.ORDER_NEWEST_FIRST });
        var newest = null;
        var oldest = null;
        var s = p.next();
        while (s != null) {
            if (s.data != null) {
                if (newest == null) { newest = s; }
                oldest = s;
            }
            s = p.next();
        }
        if (newest == null) { return; }

        _baroNote = "측정 중";
        var span = newest.when.value() - oldest.when.value();
        if (span < 2 * 3600) { return; }   // 2시간 이상 쌓여야 판단

        var e = SensorHistory.getElevationHistory({ :period => period });
        var eMin = e.getMin();
        var eMax = e.getMax();
        if (eMin != null && eMax != null && eMax - eMin > 50) {
            var walked = stepsSince(now - 3 * 3600);
            if (walked == null || walked >= STILL_STEPS || eMax - eMin > 150) {
                _baroNote = "이동 중";
                return;
            }
        }

        var d = (newest.data - oldest.data) / 100.0 * (3 * 3600.0 / span);   // hPa / 3h
        if (d <= -3.0) { _baroTrend = -2; }
        else if (d <= -1.0) { _baroTrend = -1; }
        else if (d < 1.0) { _baroTrend = 0; }
        else if (d < 3.0) { _baroTrend = 1; }
        else { _baroTrend = 2; }
    }

    const STILL_STEPS = 500;         // 3시간 동안 이보다 적게 걸었으면 제자리로 본다

    hidden function logSteps(now as Number) as Void {
        var raw = ActivityMonitor.getInfo().steps;
        if (raw == null) { return; }
        if (raw < _stepRaw) { _stepBase += _stepRaw; }   // 자정에 0으로 돌아감
        _stepRaw = raw;
        _stepLog.add([now, _stepBase + raw]);
        while (_stepLog.size() > 0 && now - _stepLog[0][0] > 3 * 3600 + 600) {
            _stepLog = _stepLog.slice(1, null);
        }
    }

    // t0 이후 걸음 수. 기록이 2시간 미만이면 판단할 수 없어 null
    hidden function stepsSince(t0 as Number) as Number or Null {
        var first = null;
        for (var i = 0; i < _stepLog.size(); i++) {
            if (_stepLog[i][0] >= t0) { first = _stepLog[i]; break; }
        }
        var last = _stepLog.size() > 0 ? _stepLog[_stepLog.size() - 1] : null;
        if (first == null || last == null || last[0] - first[0] < 2 * 3600) { return null; }
        return last[1] - first[1];
    }

    // ================= 유틸 =================

}
