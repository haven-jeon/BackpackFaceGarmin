import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

// 기기 폰트에 기호 글리프가 없어 아이콘을 도형으로 그린다. 모두 (x, y) 중심 기준, 176 화면에서 약 12px.
// 좌표는 176 화면 기준 px로 적고 k()로 화면 배율(Layout.ICON_K / 4)을 곱한다
module Icons {

    function k(v as Number) as Number {
        return v * Layout.ICON_K / 4;
    }

    function sun(dc as Dc, x as Number, y as Number) as Void {
        dc.fillCircle(x, y, k(2));
        dc.drawLine(x, y - k(5), x, y - k(3));
        dc.drawLine(x, y + k(4), x, y + k(6));
        dc.drawLine(x - k(5), y, x - k(3), y);
        dc.drawLine(x + k(4), y, x + k(6), y);
        dc.drawPoint(x - k(4), y - k(4));
        dc.drawPoint(x + k(4), y - k(4));
        dc.drawPoint(x - k(4), y + k(4));
        dc.drawPoint(x + k(4), y + k(4));
    }

    function mountain(dc as Dc, x as Number, y as Number) as Void {
        dc.fillPolygon([[x - k(7), y + k(5)], [x - k(2), y - k(4)], [x + k(1), y], [x + k(3), y - k(2)], [x + k(7), y + k(5)]]);
    }

    // 작은 위쪽 화살표 (누적 상승)
    function up(dc as Dc, x as Number, y as Number) as Void {
        dc.fillPolygon([[x - k(4), y], [x, y - k(5)], [x + k(4), y]]);
        dc.drawLine(x, y, x, y + k(5));
    }

    // 배터리 외곽 + 잔량
    function battery(dc as Dc, x as Number, y as Number, pct as Number) as Void {
        dc.drawRectangle(x - k(7), y - k(4), k(13), k(9));
        dc.fillRectangle(x + k(6), y - k(2), k(2), k(5));
        var fill = k(11) * pct / 100;
        if (fill > 0) { dc.fillRectangle(x - k(6), y - k(3), fill, k(7)); }
    }

    function heart(dc as Dc, x as Number, y as Number) as Void {
        dc.fillCircle(x - k(3), y - k(2), k(3));
        dc.fillCircle(x + k(3), y - k(2), k(3));
        dc.fillPolygon([[x - k(6), y - k(1)], [x + k(6), y - k(1)], [x, y + k(6)]]);
    }

    function thermometer(dc as Dc, x as Number, y as Number) as Void {
        dc.drawRoundedRectangle(x - k(2), y - k(7), k(5), k(10), k(2));
        dc.fillCircle(x, y + k(4), k(3));
        dc.fillRectangle(x - k(1), y - k(2), k(3), k(5));
    }

    // 번개 (폭풍 가능성)
    function bolt(dc as Dc, x as Number, y as Number) as Void {
        dc.fillPolygon([[x + k(2), y - k(7)], [x - k(4), y + k(1)], [x, y + k(1)], [x - k(2), y + k(7)], [x + k(4), y - k(1)], [x, y - k(1)]]);
    }

    // 기압 추세 화살표. trend: -2 급강하, -1 하강, 0 유지, 1 상승, 2 급상승
    function trend(dc as Dc, x as Number, y as Number, t as Number) as Void {
        var dy = k([6, 4, 0, -4, -6][t + 2]);
        var x0 = x - k(6);
        var y0 = y - dy;
        var x1 = x + k(5);
        var y1 = y + dy;
        dc.setPenWidth(k(2));
        dc.drawLine(x0, y0, x1, y1);
        dc.setPenWidth(1);
        // 화살촉: 진행 방향에 수직인 짧은 선분 두 개 대신 작은 삼각형
        var len = Math.sqrt(((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0)).toFloat());
        var ux = (x1 - x0) / len;
        var uy = (y1 - y0) / len;
        var a = k(2);
        var b = k(4);
        dc.fillPolygon([
            [x1 + ux * a, y1 + uy * a],
            [x1 - ux * b - uy * b, y1 - uy * b + ux * b],
            [x1 - ux * b + uy * b, y1 - uy * b - ux * b]
        ]);
    }
}
