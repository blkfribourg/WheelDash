import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
using Toybox.Timer;
class GarminEUCApp extends Application.AppBase {
  private var view;
  private var delegate;
  private var eucBleDelegate;
  private var queue;
  private var EUCSettingsDict;
  // private var updateDelay = 100;
  private var alarmsTimer;
  private var menu;
  private var menu2Delegate;
  private var activityAutosave;
  private var activityAutorecording;
  private var activityrecordview;

  function initialize() {
    AppBase.initialize();
    alarmsTimer = new Timer.Timer();
  }

  // onStart() is called on application start up
  function onStart(state as Dictionary?) as Void {
    eucData.setSettings(
      AppStorage.getSetting("updateDelay"),
      AppStorage.getSetting("rotationSpeed_PWM"),
      AppStorage.getSetting("rotationVoltage_PWM"),
      AppStorage.getSetting("powerFactor_PWM"),
      AppStorage.getSetting("voltageCorrectionFactor"),
      AppStorage.getSetting("speedCorrectionFactor"),
      AppStorage.getSetting("actionButton"),
      AppStorage.getSetting("alarmThreshold_PWM"),
      AppStorage.getSetting("alarmThreshold_speed")
    );
    eucData.wheelBrand = AppStorage.getSetting("wheelBrand");
    rideStatsInit();
    activityAutorecording = AppStorage.getSetting("activityRecordingOnStartup");
    activityAutosave = AppStorage.getSetting("activitySavingOnExit");

    alarmsTimer.start(method(:onUpdateTimer), eucData.updateDelay, true);
  }

  // onStop() is called when your application is exiting
  function onStop(state as Dictionary?) as Void {
    if (activityAutorecording == true || activityAutosave == true) {
      if (delegate != null && activityrecordview == null) {
        activityrecordview = delegate.getActivityView();
      }
      if (activityrecordview != null) {
        if (activityrecordview.isSessionRecording()) {
          activityrecordview.stopRecording();
          System.println("Activity saved");
        }
      }
    }
  }

  // Return the initial view of your application here
  function getInitialView() as Array<Views or InputDelegates>? {
    queue = new BleQueue();
    var profileManager = new eucPM();

    if (Toybox has :BluetoothLowEnergy) {
      // depending on EUC brand :
      profileManager.setGotwayOrLeaperkim();
      eucBleDelegate = new eucBLEDelegate(
        profileManager,
        queue,
        frameDecoder.init()
      );
      BluetoothLowEnergy.setDelegate(eucBleDelegate);
      profileManager.registerProfiles();
    }
    view = new GarminEUCView();
    EUCSettingsDict = getEUCSettingsDict(); // in helper function
    menu = createSettingsMenu(EUCSettingsDict.getConfigLabels(), "Settings");
    menu2Delegate = new GarminEUCMenu2Delegate_generic(
      menu,
      eucBleDelegate,
      queue,
      view,
      EUCSettingsDict
    );

    delegate = new GarminEUCDelegate(
      view,
      menu,
      menu2Delegate,
      eucBleDelegate,
      queue
    );

    return [view, delegate] as Array<Views or InputDelegates>;
  }
  // Timer callback for various alarms & update UI
  function onUpdateTimer() {
    // automatic recording ------------------
    // a bit hacky maybe ...
    if (activityAutorecording == true) {
      if (delegate != null && activityrecordview == null) {
        //System.println("initialize autorecording");
        activityrecordview = delegate.getActivityView();
      }
      if (
        activityrecordview != null &&
        eucBleDelegate.paired == true &&
        !activityrecordview.isSessionRecording()
      ) {
        activityrecordview.startRecording();
        //System.println("autorecord started");
      }
    }
    // -------------------------

    eucData.correctedSpeed = eucData.getCorrectedSpeed();
    eucData.calculatedPWM = eucData.getCalculatedtPWM();
    EUCAlarms.speedAlarmCheck();
    if (menu2Delegate.requestSubLabelsUpdate == true) {
      menu2Delegate.updateSublabels();
    }
    var statsIndex = 0;
    if (rideStats.showAverageMovingSpeedStatistic) {
      rideStats.avgSpeed();
      rideStats.statsArray[statsIndex] =
        "Avg Spd: " + valueRound(eucData.avgMovingSpeed, "%.1f").toString();
      //System.println(rideStats.statsArray[statsIndex]);
      statsIndex++;
    }
    if (rideStats.showTopSpeedStatistic) {
      rideStats.topSpeed();
      rideStats.statsArray[statsIndex] =
        "Top Spd:" + valueRound(eucData.topSpeed, "%.1f").toString();
      //System.println(rideStats.statsArray[statsIndex]);
      statsIndex++;
    }
    if (rideStats.showWatchBatteryConsumptionStatistic) {
      rideStats.watchBatteryUsage();
      rideStats.statsArray[statsIndex] =
        "Wtch btry/h:" +
        valueRound(eucData.watchBatteryUsage, "%.1f").toString();
      //System.println(rideStats.statsArray[statsIndex]);
      statsIndex++;
    }

    WatchUi.requestUpdate();
  }

  function rideStatsInit() {
    rideStats.movingmsec = 0;
    rideStats.statsTimerReset();
    rideStats.showAverageMovingSpeedStatistic = AppStorage.getSetting(
      "averageMovingSpeedStatistic"
    );
    rideStats.showTopSpeedStatistic =
      AppStorage.getSetting("topSpeedStatistic");

    rideStats.showWatchBatteryConsumptionStatistic = AppStorage.getSetting(
      "watchBatteryConsumptionStatistic"
    );
    // unelegant
    if (rideStats.showAverageMovingSpeedStatistic) {
      rideStats.statsNumberToDiplay++;
    }
    if (rideStats.showTopSpeedStatistic) {
      rideStats.statsNumberToDiplay++;
    }
    if (rideStats.showWatchBatteryConsumptionStatistic) {
      rideStats.statsNumberToDiplay++;
    }
    rideStats.statsArray = new [rideStats.statsNumberToDiplay];
    //System.println("array size:" + rideStats.statsArray.size());
  }
}

function getApp() as GarminEUCApp {
  return Application.getApp() as GarminEUCApp;
}
