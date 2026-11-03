import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

// 위치 → 지명. 시계는 폰 날씨의 지명(observationLocationName)을 주지 않아서 앱에 넣은 표에서 찾는다.
// 표는 design/gen_places.py 가 만든다 (전국 시·군·구 + 산림청 100대 명산).
// 표를 통째로 들고 있으면 메모리가 모자라서, 찾을 때만 좌표 표(2KB)와 이름 한 묶음을 불러온다
module Places {

    const MOUNTAIN_KM = 3.0;   // 정상에서 이 거리 안이면 산 이름
    const FAR_KM = 80.0;       // 가장 가까운 시·군·구 중심이 이보다 멀면 국내가 아닌 것으로 본다 (신안·진도 섬은 60km 넘게 떨어짐)

    // 위치 [lat, lon] (도)의 지명. 국내가 아니면 null
    function nearest(loc as Array<Double>) as String or Null {
        var d = WatchUi.loadResource(Rez.JsonData.PlacePoints) as Dictionary;
        var m = d["m"] as Number;
        var pts = d["p"] as Array<Number>;
        d = null;
        var la = loc[0] * 1000.0d - 30000;
        var lo = loc[1] * 1000.0d - 120000;
        var k = Math.cos(Math.toRadians(loc[0]));
        var best = [-1, -1];
        var bestD = [0.0d, 0.0d];   // 거리(km)의 제곱. [산, 시·군·구]
        for (var i = 0; i < pts.size(); i++) {
            var dy = (pts[i] / 65536 - la) * 0.11057d;
            var dx = (pts[i] % 65536 - lo) * 0.11132d * k;
            var dd = dy * dy + dx * dx;
            var g = i < m ? 0 : 1;
            if (best[g] < 0 || dd < bestD[g]) { best[g] = i; bestD[g] = dd; }
        }
        pts = null;
        var idx = -1;
        if (best[0] >= 0 && bestD[0] <= MOUNTAIN_KM * MOUNTAIN_KM) { idx = best[0]; }
        else if (best[1] >= 0 && bestD[1] <= FAR_KM * FAR_KM) { idx = best[1]; }
        if (idx < 0) { return null; }
        var names = WatchUi.loadResource(PlaceChunks.names(idx / PlaceChunks.SIZE)) as Array<String>;
        return names[idx % PlaceChunks.SIZE];
    }
}
