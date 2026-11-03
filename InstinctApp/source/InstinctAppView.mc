import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// 버튼 입력 확인용 최소 앱: UP/DOWN으로 숫자 증감, GPS(START) 버튼으로 0으로 초기화.
class InstinctAppView extends WatchUi.View {

    var count = 0;

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        dc.drawText(w / 2, h / 4, Graphics.FONT_SMALL, "UP/DOWN", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(w / 2, h / 2, Graphics.FONT_NUMBER_MEDIUM, count.toString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(w / 2, h * 3 / 4, Graphics.FONT_XTINY, "GPS: reset", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class InstinctAppDelegate extends WatchUi.BehaviorDelegate {

    hidden var _view as InstinctAppView;

    function initialize(view as InstinctAppView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onPreviousPage() as Boolean {
        _view.count += 1;
        WatchUi.requestUpdate();
        return true;
    }

    function onNextPage() as Boolean {
        _view.count -= 1;
        WatchUi.requestUpdate();
        return true;
    }

    function onSelect() as Boolean {
        _view.count = 0;
        WatchUi.requestUpdate();
        return true;
    }
}
