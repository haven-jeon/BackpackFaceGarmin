import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class SunsetMarginApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        return [ new SunsetMarginField() ];
    }

    // 폰 Connect IQ 앱에서 설정을 바꾸면 다음 계산 때 반영됨
    function onSettingsChanged() as Void {
        WatchUi.requestUpdate();
    }
}
