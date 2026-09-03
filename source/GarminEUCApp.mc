import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Communications;
using Toybox.Timer;
using Toybox.StringUtil;
import Toybox.Position;
class GarminEUCApp extends Application.AppBase {
  private var psMenuView;
  private var psMenuDelegate;
  private var activityRecordView;
  private var mainTimer;
  private var startupTimer;
  function initialize() {
    // Garmin reports a nominal 128 KiB heap as 131072 bytes.
    eucData.limitedMemory = System.getSystemStats().totalMemory <= 131072;
    AppBase.initialize();
    // alarmsTimer = new Timer.Timer();
  }

  // onStart() is called on application start up
  function onStart(state as Dictionary?) as Void {
    // Sandbox zone
    // Varia.targetObject = fakeVaria(3);
    // end of sandbox

    //  alarmsTimer.start(method(:onUpdateTimer), eucData.updateDelay, true);

    // check if using GPS speed
  }

  // onStop() is called when your application is exiting
  function onStop(state as Dictionary?) as Void {
    if (psMenuDelegate != null) {
      if (eucData.activityAutorecording == true) {
        var activityRecordView = psMenuDelegate.getActivityView();
        if (activityRecordView != null) {
          if (activityRecordView.isSessionRecording()) {
            activityRecordView.stopRecording();
          }
        }
      }
      psMenuDelegate.unpair();
    }
  }

  // Return the initial view of your application here
  function getInitialView() {
    // Instinct 3 can throw if Application.Properties is read before the first
    // view is active. Show the existing loading view, then initialize once the
    // UI event loop is running.
    psMenuView = new ECMessageView(null);
    startupTimer = new Timer.Timer();
    startupTimer.start(method(:finishStartup), 500, false);
    return [psMenuView];
  } // Timer callback for various alarms & update UI

  function finishStartup() as Void {
    if (startupTimer != null) {
      startupTimer.stop();
      startupTimer = null;
    }

    // Instinct 3 firmware can fail inside Application.Properties.getValue().
    // Load and use AppBase's compatible property interface instead.
    Application.getApp().loadProperties();
    checkSettingsURL();
    if (eucData.JSONFetch.equals("")) {
      resetApp();
      WatchUi.switchToView(
        psMenuView,
        psMenuDelegate,
        WatchUi.SLIDE_IMMEDIATE
      );
    }
  }

  function resetApp() {
    //   System.println("reset");

    psMenuView = profileSelector.createPSMenu();
    psMenuDelegate = profileSelector.createPSDelegate();
    if (mainTimer != null) {
      mainTimer.stopTimer();
    }
    mainTimer = new MainTimer(psMenuDelegate);
    mainTimer.startTimer();

    // WatchUi.switchToView(psMenuView, psMenuDelegate, WatchUi.SLIDE_IMMEDIATE);
  }
  function getPSDelegate() {
    return psMenuDelegate;
  }
  function getPSView() {
    return psMenuView;
  }
}
