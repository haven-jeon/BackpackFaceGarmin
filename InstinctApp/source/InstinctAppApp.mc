import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class InstinctAppApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        var view = new InstinctAppView();
        return [ view, new InstinctAppDelegate(view) ];
    }
}
