import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class InstinctFaceApp extends Application.AppBase {

    hidden var _view = null;

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        _view = new InstinctFaceView();
        return [ _view ];
    }

    // 폰 Garmin Connect 앱에서 정보 칸 설정을 바꾸면 바로 반영
    function onSettingsChanged() as Void {
        if (_view != null) { _view.loadSettings(); }
        WatchUi.requestUpdate();
    }
}
