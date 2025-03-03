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
  function initialize() {
    eucData.limitedMemory = System.getSystemStats().totalMemory < 128000;
    AppBase.initialize();
    // alarmsTimer = new Timer.Timer();
  }

  // onStart() is called on application start up
  function onStart(state as Dictionary?) as Void {
    //if setting change was detected it means checkSettingsURL was already called
    checkSettingsURL();
   

    // REMINDER !!! --------------------------------------------------------------------------
    //eucData.useProfileSelector is set inside checkSettingsURL even if not using json config !!
    // ---------------------------------------------------------------------------------------

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
    // System.println("initView :" + eucData.JSONFetch);
    if (!eucData.JSONFetch.equals("")) {
      psMenuView = new ECMessageView(null);
      return [psMenuView];
    } else {
      psMenuView = profileSelector.createPSMenu();
      psMenuDelegate = profileSelector.createPSDelegate();
      mainTimer = new MainTimer(psMenuDelegate);
      mainTimer.startTimer();
      return [psMenuView, psMenuDelegate];
    }
  } // Timer callback for various alarms & update UI
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
