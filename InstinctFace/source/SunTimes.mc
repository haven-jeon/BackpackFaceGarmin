import Toybox.Activity;
import Toybox.Application;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Weather;

// 일출·일몰을 기기 안에서 계산한다 (오차 1~2분).
// 며칠씩 폰 연결 없이 산에 있어도 동작하도록 마지막으로 알게 된 위치를 Storage에 보관한다.
module SunTimes {

    // 위치 [lat, lon] (도). 날씨 → 활동 GPS → 저장값 순으로 찾는다.
    function getLocation() as Array<Double> or Null {
        var loc = null;
        if (Toybox has :Weather) {
            var cond = Weather.getCurrentConditions();
            if (cond != null) { loc = cond.observationLocationPosition; }
        }
        if (loc == null) {
            var act = Activity.getActivityInfo();
            if (act != null) { loc = act.currentLocation; }
        }

        var saved = Application.Storage.getValue("loc") as Array<Double>?;
        if (loc == null) { return saved != null ? saved : fallbackLocation(); }

        var deg = loc.toDegrees();
        var cur = [deg[0].toDouble(), deg[1].toDouble()];
        // 플래시 쓰기를 줄이려고 5km 넘게 바뀐 경우에만 저장
        if (saved == null || distanceKm(saved, cur) > 5.0) {
            Application.Storage.setValue("loc", cur);
        }
        return cur;
    }

    // 두 위치 [lat, lon] 사이 거리(km). 수 km~수백 km에서는 평면 근사로 충분하다.
    function distanceKm(a as Array<Double>, b as Array<Double>) as Float {
        var dy = (a[0] - b[0]) * 110.57d;
        var dx = (a[1] - b[1]) * 111.32d * Math.cos(Math.toRadians((a[0] + b[0]) / 2.0d));
        return Math.sqrt(dx * dx + dy * dy).toFloat();
    }

    // 시뮬레이터 확인용: 디버그 빌드에서만 위치가 없으면 서울을 쓴다. 릴리스 빌드(-r)에서는 null.
    (:debug)
    function fallbackLocation() as Array<Double> or Null {
        return [37.57d, 126.98d];
    }

    (:release)
    function fallbackLocation() as Array<Double> or Null {
        return null;
    }

    // 시각 t(unix 초)에 가장 가까운 태양 남중일의 일출(rising=true) 또는 일몰 시각. 백야/극야면 null.
    // 자정 근처 t는 전날로 잡히므로 현지 정오를 넣을 것.
    function event(lat as Double, lon as Double, t as Number, rising as Boolean) as Number or Null {
        var jd = t.toDouble() / 86400.0d + 2440587.5d;
        var n = (jd + lon / 360.0d - 2451545.0d + 0.5d).toLong().toDouble();
        var jStar = n - lon / 360.0d;
        var mDeg = norm360(357.5291d + 0.98560028d * jStar);
        var mr = Math.toRadians(mDeg);
        var c = 1.9148d * Math.sin(mr) + 0.02d * Math.sin(2 * mr) + 0.0003d * Math.sin(3 * mr);
        var lr = Math.toRadians(norm360(mDeg + c + 282.9372d));
        var jTransit = 2451545.0d + jStar + 0.0053d * Math.sin(mr) - 0.0069d * Math.sin(2 * lr);
        var sinDec = Math.sin(lr) * Math.sin(Math.toRadians(23.44d));
        var cosDec = Math.sqrt(1.0d - sinDec * sinDec);
        var latR = Math.toRadians(lat);
        var cosW = (Math.sin(Math.toRadians(-0.833d)) - Math.sin(latR) * sinDec) / (Math.cos(latR) * cosDec);
        if (cosW > 1.0d || cosW < -1.0d) { return null; }
        var w = Math.toDegrees(Math.acos(cosW)) / 360.0d;
        var j = rising ? jTransit - w : jTransit + w;
        return ((j - 2440587.5d) * 86400.0d).toNumber();
    }

    function norm360(x as Double) as Double {
        var r = x - 360.0d * (x / 360.0d).toLong();
        if (r < 0) { r += 360.0d; }
        return r;
    }
}
