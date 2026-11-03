import Toybox.Activity;
import Toybox.Application;
import Toybox.Attention;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Weather;

// 코스 목적지까지 남은 거리·상승고도로 도착 예상 시간을 구하고,
// 일몰까지 남는 여유를 "+1:23" / "-0:15" 형태로 보여주는 데이터 필드.
// 코스 내비게이션이 아닐 때는 일몰까지 남은 시간을 "~2:10"으로 표시.
class SunsetMarginField extends WatchUi.SimpleDataField {

    hidden var _sunset = null;        // 일몰 시각 (unix 초)
    hidden var _lastCalc = 0;
    hidden var _alerted = false;

    hidden var _baseKmh = 4.0;        // 평지 보행 속도
    hidden var _ascentMph = 400.0;    // 시간당 상승고도
    hidden var _alertMin = 30;        // 경고 기준 (분)
    hidden var _autoCal = true;

    function initialize() {
        SimpleDataField.initialize();
        label = "SUNSET MGN";
        loadSettings();
    }

    function compute(info as Activity.Info) as Numeric or Duration or String or Null {
        var now = Time.now().value();

        // 일몰 계산은 1분마다, GPS 잡기 전에는 5초마다 재시도
        if ((_sunset == null && now - _lastCalc >= 5) || now - _lastCalc >= 60) {
            loadSettings();
            _sunset = calcSunset(info, now);
            _lastCalc = now;
        }
        if (_sunset == null) {
            return "NO GPS";
        }

        var toSunsetMin = (_sunset - now) / 60;
        var dist = info.distanceToDestination;   // m, 코스 내비게이션 중에만 값 있음
        if (dist == null) {
            return "~" + fmt(toSunsetMin);
        }

        var margin = toSunsetMin - estimateMinutes(info, dist.toFloat());
        checkAlert(margin);
        return (margin < 0 ? "-" : "+") + fmt(margin);
    }

    // ---- 도착 예상 시간 (나이스미스 규칙 + 개인 페이스 보정) ----
    hidden function estimateMinutes(info as Activity.Info, distM as Float) as Number {
        var remAscent = 0.0;
        if (info has :elevationAtDestination) {
            var dest = info.elevationAtDestination;
            var alt = info.altitude;
            if (dest != null && alt != null && dest > alt) {
                remAscent = (dest - alt).toFloat();
            }
        }
        var hours = (distM / 1000.0) / _baseKmh + remAscent / _ascentMph;
        hours = hours * paceFactor(info);
        return (hours * 60).toNumber();
    }

    // 지금까지 실제로 걸린 시간 ÷ 나이스미스 예측 시간 = 내 페이스 계수
    // (타이머가 돌고 있는 동안의 휴식도 포함되므로 실제 행동 패턴이 반영됨)
    hidden function paceFactor(info as Activity.Info) as Float {
        if (!_autoCal) { return 1.0; }
        var done = info.elapsedDistance;
        var t = info.timerTime;
        if (done == null || t == null || done < 1000 || t < 900000) {
            return 1.0;   // 1km·15분 이전엔 보정하지 않음
        }
        var asc = info.totalAscent == null ? 0 : info.totalAscent;
        var pred = (done / 1000.0) / _baseKmh + asc / _ascentMph;
        if (pred <= 0) { return 1.0; }
        var f = (t / 3600000.0) / pred;
        if (f < 0.6) { f = 0.6; }
        if (f > 2.5) { f = 2.5; }
        return f.toFloat();
    }

    // ---- 일몰 시각 ----
    hidden function calcSunset(info as Activity.Info, now as Number) {
        var loc = info.currentLocation;
        if (loc == null) { return null; }

        if (Toybox has :Weather) {
            if (Weather has :getSunset) {
                var m = Weather.getSunset(loc, Time.now());
                if (m != null) { return m.value(); }
            }
        }
        var deg = loc.toDegrees();
        return solarSunset(deg[0].toDouble(), deg[1].toDouble(), now);
    }

    // 일출몰 방정식 근사 (오차 수 분 이내). lon은 동경이 +.
    hidden function solarSunset(lat as Double, lon as Double, now as Number) as Number {
        var jd = now.toDouble() / 86400.0d + 2440587.5d;
        var n = (jd + lon / 360.0d - 2451545.0d + 0.5d).toLong().toDouble(); // 현지 날짜
        var jStar = n - lon / 360.0d;
        var mDeg = norm360(357.5291d + 0.98560028d * jStar);
        var mr = Math.toRadians(mDeg);
        var c = 1.9148d * Math.sin(mr) + 0.02d * Math.sin(2 * mr) + 0.0003d * Math.sin(3 * mr);
        var lr = Math.toRadians(norm360(mDeg + c + 282.9372d));
        var jTransit = 2451545.0d + jStar + 0.0053d * Math.sin(mr) - 0.0069d * Math.sin(2 * lr);
        var sinDec = Math.sin(lr) * Math.sin(Math.toRadians(23.44d));
        var cosDec = Math.sqrt(1.0d - sinDec * sinDec);
        var latR = Math.toRadians(lat);
        var cosW = (Math.sin(Math.toRadians(-0.833d)) - Math.sin(latR) * sinDec)
                   / (Math.cos(latR) * cosDec);
        if (cosW > 1.0d) { cosW = 1.0d; }
        if (cosW < -1.0d) { cosW = -1.0d; }
        var jSet = jTransit + Math.toDegrees(Math.acos(cosW)) / 360.0d;
        return ((jSet - 2440587.5d) * 86400.0d).toNumber();
    }

    hidden function norm360(x as Double) as Double {
        var r = x - 360.0d * (x / 360.0d).toLong();
        if (r < 0) { r += 360.0d; }
        return r;
    }

    // ---- 경고: 여유가 기준 아래로 떨어지면 한 번 진동 ----
    hidden function checkAlert(margin as Number) as Void {
        if (margin < _alertMin && !_alerted) {
            _alerted = true;
            if (Attention has :vibrate) {
                Attention.vibrate([ new Attention.VibeProfile(100, 800) ]);
            }
            if (Attention has :playTone) {
                Attention.playTone(Attention.TONE_ALERT_HI);
            }
        } else if (margin > _alertMin + 10) {
            _alerted = false;   // 여유가 다시 생기면 재무장
        }
    }

    // ---- 유틸 ----
    hidden function fmt(min as Number) as String {
        var a = min.abs();
        return Lang.format("$1$:$2$", [a / 60, (a % 60).format("%02d")]);
    }

    hidden function loadSettings() as Void {
        _baseKmh = readNum("baseSpeed", 4.0).toFloat();
        _ascentMph = readNum("ascentRate", 400).toFloat();
        _alertMin = readNum("alertMin", 30).toNumber();
        var ac = Application.Properties.getValue("autoCalibrate");
        _autoCal = (ac instanceof Boolean) ? ac : true;
        if (_baseKmh <= 0) { _baseKmh = 4.0; }
        if (_ascentMph <= 0) { _ascentMph = 400.0; }
    }

    hidden function readNum(key as String, def as Numeric) as Numeric {
        var v = Application.Properties.getValue(key);
        return (v instanceof Number || v instanceof Float) ? v : def;
    }
}
