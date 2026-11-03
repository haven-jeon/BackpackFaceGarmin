import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Weather;
import Toybox.WatchUi;

// 정보 칸: 칸마다 무엇을 보일지 폰의 Garmin Connect 앱 설정(resources/settings)에서 고른다.
// 값은 properties.xml 의 list 값과 같아야 한다.
module Slots {

    enum {
        NONE = 0,
        ALTITUDE = 1,     // ▲ 1,371m
        ASCENT = 2,       // ↑ 620m
        BATTERY = 3,      // ▭ 5d (☀)
        BODY = 4,         // BB 85  (바디 배터리)
        SUNTIMES = 5,     // 6:51-17:40
        STEPS = 6,        // 👣 8,432
        DISTANCE = 7,     // 거리 5.2km
        HEART = 8,        // ♥ 72
        TEMP = 9,         // 🌡 12°  (폰 날씨)
        NOTIFY = 10,      // 🔔 3
        TEMP_RANGE = 11,  // 3~14°  (오늘 최저~최고, 폰 날씨)
        PLACE = 12        // 지금 있는 곳의 지명 (산 정상 3km 안이면 산 이름)
    }

    // top1~3: 좌상단 세 줄, row1~3: 아래 첫 줄에 나란히, low1·low3·low2: 아래 둘째 줄 왼쪽·가운데·오른쪽
    // 키 이름을 바꾸면 시계·시뮬레이터에 저장된 예전 값이 무시되고 새 기본값이 쓰인다 (배치를 바꿀 때 이용)
    const KEYS = ["top1", "top2", "top3", "row1", "row2", "row3", "low1", "low2", "low3"];
    const DEFAULTS = [SUNTIMES, TEMP_RANGE, PLACE, ALTITUDE, ASCENT, TEMP, BATTERY, BODY, STEPS];

    function load() as Array<Number> {
        var out = [] as Array<Number>;
        for (var i = 0; i < KEYS.size(); i++) {
            var v = Application.Properties.getValue(KEYS[i]);
            out.add(v instanceof Number ? v : DEFAULTS[i]);
        }
        return out;
    }

    // (cx, y) 가운데 정렬로 칸 하나를 그린다. y는 글자 윗변. sun = [오늘 일출, 오늘 일몰] (unix 초 또는 null)
    function draw(dc as Dc, font as Graphics.FontType, type as Number, cx as Number, y as Number, sun as Array) as Void {
        if (type == NONE) { return; }
        var c = content(type, sun);
        var f = font;
        if (type == PLACE) { c[0] = fit(dc, f, c[0] as String, PLACE_MAX_W); }
        drawAt(dc, f, type, c, cx - width(dc, f, c, true) / 2, y, true);
    }

    // 여러 칸을 한 줄에 gap 간격으로 이어서 (cx 가운데 정렬로) 그린다. 없음(NONE) 칸은 건너뛴다.
    // 폭이 빠듯한 줄이라 배터리 뒤 태양광 충전 해는 그리지 않고, maxW를 넘으면 간격을 2px로 좁힌다
    function drawRow(dc as Dc, font as Graphics.FontType, types as Array<Number>, cx as Number, y as Number,
            sun as Array, gap as Number, maxW as Number) as Void {
        var cs = [] as Array;
        var ws = [] as Array<Number>;
        var total = 0;
        for (var i = 0; i < types.size(); i++) {
            if (types[i] == NONE) { continue; }
            var c = content(types[i], sun);
            var cw = width(dc, font, c, false);
            total += (cs.size() > 0 ? gap : 0) + cw;
            cs.add([types[i], c]);
            ws.add(cw);
        }
        if (total > maxW && cs.size() > 1 && gap > 2) {
            total -= (gap - 2) * (cs.size() - 1);
            gap = 2;
        }
        var x = cx - total / 2;
        for (var i = 0; i < cs.size(); i++) {
            var t = cs[i][0] as Number;
            drawAt(dc, font, t, cs[i][1] as Array, x, y, false);
            x += ws[i] + gap;
        }
    }

    // 칸 내용 [글자, 아이콘 심볼, 한글 이름표]. 아이콘·이름표는 없으면 null
    function content(type as Number, sun as Array) as Array {
        var text = "--";
        var icon = null;      // 아이콘 그리는 함수 심볼
        var label = null;     // 아이콘 대신 앞에 붙는 한글 이름표

        if (type == ALTITUDE) {
            var a = altitude();
            text = a == null ? "--" : groupThousands(a.toNumber()) + "m";
            icon = :mountain;
        } else if (type == ASCENT) {
            // 위 화살표가 '오른 높이'를 뜻하므로 + 는 붙이지 않는다
            var c = ActivityMonitor.getInfo().metersClimbed;
            text = (c == null ? "0" : groupThousands(c.toNumber())) + "m";
            icon = :up;
        } else if (type == BATTERY) {
            var stats = System.getSystemStats();
            var days = (stats has :batteryInDays) ? stats.batteryInDays : null;
            text = days != null ? days.toNumber().toString() + "d" : stats.battery.toNumber().toString() + "%";
            icon = :battery;
        } else if (type == BODY) {
            var bb = bodyBattery();
            text = bb == null ? "--" : bb.toString();
            label = "BB";
        } else if (type == SUNTIMES) {
            // 가장 긴 칸이라 아이콘 없이, 시 앞자리 0도 뗀다 (6:51-17:40)
            text = hhmm(sun[0]) + "-" + hhmm(sun[1]);
        } else if (type == STEPS) {
            var st = ActivityMonitor.getInfo().steps;
            // 만 보부터는 칸 폭을 넘지 않게 12.3k
            text = st == null ? "--" : (st < 10000 ? groupThousands(st) : (st / 1000.0).format("%.1f") + "k");
            icon = :steps;
        } else if (type == DISTANCE) {
            var cm = ActivityMonitor.getInfo().distance;   // cm
            text = cm == null ? "--" : (cm / 100000.0).format("%.1f") + "km";
            label = "거리";
        } else if (type == HEART) {
            var hr = heartRate();
            text = hr == null ? "--" : hr.toString();
            icon = :heart;
        } else if (type == TEMP) {
            var t = temperature();
            text = t == null ? "--" : t.toString() + "°";
            icon = :thermo;
        } else if (type == NOTIFY) {
            text = System.getDeviceSettings().notificationCount.toString();
            icon = :bell;
        } else if (type == TEMP_RANGE) {
            var r = temperatureRange();
            text = r == null ? "--" : r[0].toString() + "~" + r[1].toString() + "°";
            icon = :thermo;
        } else if (type == PLACE) {
            var n = placeName();
            text = n == null ? "--" : n;
        }
        return [text, icon, label];
    }

    // 아이콘(또는 이름표) 앞머리 폭
    function headWidth(dc as Dc, font as Graphics.FontType, c as Array) as Number {
        if (c[2] != null) { return dc.getTextWidthInPixels(c[2], font) + 3; }
        if (c[1] == :steps || c[1] == :bell) { return 14; }   // 12px 이모지 + 2px
        return c[1] != null ? 15 : 0;
    }

    // solar: 배터리 칸 뒤에 태양광 충전 해를 붙일지
    function width(dc as Dc, font as Graphics.FontType, c as Array, solar as Boolean) as Number {
        var w = headWidth(dc, font, c) + dc.getTextWidthInPixels(c[0], font);
        if (solar && c[1] == :battery && solarCharging()) { w += 14; }
        return w;
    }

    // x는 칸 왼쪽 끝
    function drawAt(dc as Dc, font as Graphics.FontType, type as Number, c as Array, x as Number, y as Number,
            solar as Boolean) as Void {
        var text = c[0];
        var icon = c[1];
        var label = c[2];
        var lw = headWidth(dc, font, c);
        var iy = y + 6;
        if (label != null) {
            dc.drawText(x, y, font, label, Graphics.TEXT_JUSTIFY_LEFT);
        } else if (icon == :mountain) {
            Icons.mountain(dc, x + 6, iy);
        } else if (icon == :up) {
            Icons.up(dc, x + 6, iy);
        } else if (icon == :battery) {
            Icons.battery(dc, x + 6, iy, System.getSystemStats().battery.toNumber());
        } else if (icon == :heart) {
            Icons.heart(dc, x + 6, iy);
        } else if (icon == :thermo) {
            Icons.thermometer(dc, x + 6, iy);
        } else if (icon == :steps) {
            dc.drawBitmap(x, y + 1, emoji(Rez.Drawables.EmojiSteps));
        } else if (icon == :bell) {
            dc.drawBitmap(x, y + 1, emoji(Rez.Drawables.EmojiBell));
        }
        dc.drawText(x + lw, y, font, text, Graphics.TEXT_JUSTIFY_LEFT);

        // 태양광 충전 중이면 배터리 칸 뒤에 해
        if (solar && icon == :battery && solarCharging()) {
            Icons.sun(dc, x + lw + dc.getTextWidthInPixels(text, font) + 8, iy);
        }
    }

    function solarCharging() as Boolean {
        var stats = System.getSystemStats();
        var solar = (stats has :solarIntensity) ? stats.solarIntensity : null;
        return solar != null && solar > 0;
    }

    // 12px 흑백 이모지 비트맵 (design/gen_emoji.py). 처음 쓸 때 한 번만 읽는다.
    var _emoji as Dictionary<ResourceId, WatchUi.BitmapResource> = {};

    function emoji(id as ResourceId) as WatchUi.BitmapResource {
        var b = _emoji.get(id);
        if (b == null) {
            b = WatchUi.loadResource(id) as WatchUi.BitmapResource;
            _emoji.put(id, b);
        }
        return b;
    }

    // ================= 데이터 =================

    function altitude() as Float or Null {
        if ((Toybox has :SensorHistory) && (SensorHistory has :getElevationHistory)) {
            var s = SensorHistory.getElevationHistory({ :period => 1 }).next();
            if (s != null && s.data != null) { return s.data; }
        }
        var act = Activity.getActivityInfo();
        return act != null ? act.altitude : null;
    }

    function bodyBattery() as Number or Null {
        if ((Toybox has :SensorHistory) && (SensorHistory has :getBodyBatteryHistory)) {
            var s = SensorHistory.getBodyBatteryHistory({ :period => 1 }).next();
            if (s != null && s.data != null) { return s.data.toNumber(); }
        }
        return null;
    }

    function heartRate() as Number or Null {
        var act = Activity.getActivityInfo();
        if (act != null && act.currentHeartRate != null) { return act.currentHeartRate; }
        if (ActivityMonitor has :getHeartRateHistory) {
            var s = ActivityMonitor.getHeartRateHistory(1, true).next();
            if (s != null && s.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) { return s.heartRate; }
        }
        return null;
    }

    // 폰에서 받은 날씨. 산에서 폰 연결이 끊기면 시계에는 마지막 값이 그대로 남으므로,
    // 관측한 지 WEATHER_MAX_AGE가 지난 값은 쓰지 않는다 (기온이 "--"로 바뀐다)
    const WEATHER_MAX_AGE = 3 * 3600;

    function freshConditions() as Weather.CurrentConditions or Null {
        if (!(Toybox has :Weather)) { return null; }
        var c = Weather.getCurrentConditions();
        if (c == null) { return null; }
        var obs = c.observationTime;
        if (obs != null && Time.now().value() - obs.value() > WEATHER_MAX_AGE) { return null; }
        return c;
    }

    // 지금 기온(°C). 날씨가 없거나 오래됐으면 null
    function temperature() as Number or Null {
        var c = freshConditions();
        if (c == null || c.temperature == null) { return null; }
        return c.temperature.toNumber();
    }

    // 오늘 최저·최고 기온(°C) [low, high]. 날씨가 없거나 오래됐으면 null
    function temperatureRange() as Array<Number> or Null {
        var c = freshConditions();
        if (c == null || c.lowTemperature == null || c.highTemperature == null) { return null; }
        return [c.lowTemperature.toNumber(), c.highTemperature.toNumber()];
    }

    // 지명은 표를 불러와 찾으므로, 10분마다 위치를 보고 300m 넘게 옮겼을 때만 다시 찾는다
    var _placeAt = null as Number?;
    var _placeLoc = null as Array<Double>?;
    var _place = null as String?;

    function placeName() as String or Null {
        var now = Time.now().value();
        if (_placeAt != null && now - _placeAt < 600) { return _place; }
        _placeAt = now;
        var loc = SunTimes.getLocation();
        if (loc == null) { return _place; }
        if (_placeLoc != null && SunTimes.distanceKm(_placeLoc, loc) < 0.3) { return _place; }
        _placeLoc = loc;
        _place = Places.nearest(loc);
        return _place;
    }

    // 좌상단 줄에서 서브스크린 테두리에 걸리지 않는 폭
    const PLACE_MAX_W = 96;

    // 폭을 넘으면 쉼표 앞부분만 ("Jung-gu, Seoul" → "Jung-gu"), 그래도 넘으면 뒤를 자른다
    function fit(dc as Dc, font as Graphics.FontType, text as String, maxW as Number) as String {
        if (dc.getTextWidthInPixels(text, font) <= maxW) { return text; }
        var comma = text.find(",");
        if (comma != null) { text = text.substring(0, comma) as String; }
        while (text.length() > 1 && dc.getTextWidthInPixels(text, font) > maxW) {
            text = text.substring(0, text.length() - 1) as String;
        }
        return text;
    }

    // ================= 유틸 =================

    function hhmm(t as Number or Null) as String {
        if (t == null) { return "--:--"; }
        var g = Gregorian.info(new Time.Moment(t), Time.FORMAT_SHORT);
        return Lang.format("$1$:$2$", [g.hour, g.min.format("%02d")]);
    }

    // 8432 → "8,432", -120 → "-120"
    function groupThousands(n as Number) as String {
        var a = n.abs();
        var s = a < 1000 ? a.toString() : (a / 1000).toString() + "," + (a % 1000).format("%03d");
        return n < 0 ? "-" + s : s;
    }
}
