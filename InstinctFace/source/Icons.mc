import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

// 기기 폰트에 기호 글리프가 없어 아이콘을 도형으로 그린다. 모두 (x, y) 중심 기준, 약 12px.
module Icons {

    function sun(dc as Dc, x as Number, y as Number) as Void {
        dc.fillCircle(x, y, 2);
        dc.drawLine(x, y - 5, x, y - 3);
        dc.drawLine(x, y + 4, x, y + 6);
        dc.drawLine(x - 5, y, x - 3, y);
        dc.drawLine(x + 4, y, x + 6, y);
        dc.drawPoint(x - 4, y - 4);
        dc.drawPoint(x + 4, y - 4);
        dc.drawPoint(x - 4, y + 4);
        dc.drawPoint(x + 4, y + 4);
    }

    function mountain(dc as Dc, x as Number, y as Number) as Void {
        dc.fillPolygon([[x - 7, y + 5], [x - 2, y - 4], [x + 1, y], [x + 3, y - 2], [x + 7, y + 5]]);
    }

    // 작은 위쪽 화살표 (누적 상승)
    function up(dc as Dc, x as Number, y as Number) as Void {
        dc.fillPolygon([[x - 4, y], [x, y - 5], [x + 4, y]]);
        dc.drawLine(x, y, x, y + 5);
    }

    // 배터리 외곽 + 잔량
    function battery(dc as Dc, x as Number, y as Number, pct as Number) as Void {
        dc.drawRectangle(x - 7, y - 4, 13, 9);
        dc.fillRectangle(x + 6, y - 2, 2, 5);
        var fill = 11 * pct / 100;
        if (fill > 0) { dc.fillRectangle(x - 6, y - 3, fill, 7); }
    }

    function heart(dc as Dc, x as Number, y as Number) as Void {
        dc.fillCircle(x - 3, y - 2, 3);
        dc.fillCircle(x + 3, y - 2, 3);
        dc.fillPolygon([[x - 6, y - 1], [x + 6, y - 1], [x, y + 6]]);
    }

    function thermometer(dc as Dc, x as Number, y as Number) as Void {
        dc.drawRoundedRectangle(x - 2, y - 7, 5, 10, 2);
        dc.fillCircle(x, y + 4, 3);
        dc.fillRectangle(x - 1, y - 2, 3, 5);
    }

    // 번개 (폭풍 가능성)
    function bolt(dc as Dc, x as Number, y as Number) as Void {
        dc.fillPolygon([[x + 2, y - 7], [x - 4, y + 1], [x, y + 1], [x - 2, y + 7], [x + 4, y - 1], [x, y - 1]]);
    }

    // 기압 추세 화살표. trend: -2 급강하, -1 하강, 0 유지, 1 상승, 2 급상승
    function trend(dc as Dc, x as Number, y as Number, t as Number) as Void {
        var dy = [6, 4, 0, -4, -6][t + 2];
        var x0 = x - 6;
        var y0 = y - dy;
        var x1 = x + 5;
        var y1 = y + dy;
        dc.setPenWidth(2);
        dc.drawLine(x0, y0, x1, y1);
        dc.setPenWidth(1);
        // 화살촉: 진행 방향에 수직인 짧은 선분 두 개 대신 작은 삼각형
        var len = Math.sqrt(((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0)).toFloat());
        var ux = (x1 - x0) / len;
        var uy = (y1 - y0) / len;
        dc.fillPolygon([
            [x1 + ux * 2, y1 + uy * 2],
            [x1 - ux * 4 - uy * 4, y1 - uy * 4 + ux * 4],
            [x1 - ux * 4 + uy * 4, y1 - uy * 4 - ux * 4]
        ]);
    }
}
