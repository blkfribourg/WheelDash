import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
using Toybox.Timer;
using Toybox.StringUtil;
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
  private var debug;
  private var actionButtonTrigger;
  private var profileMenu;
  function initialize() {
    AppBase.initialize();
    alarmsTimer = new Timer.Timer();
    actionButtonTrigger = new ActionButton();
  }

  // onStart() is called on application start up
  function onStart(state as Dictionary?) as Void {
    // Sandbox zone
    //profileMenu= createMenu(["Profile1","Profile2","Profile3"],"Profile Selection");
    // end of sandbox
    setSettings();
    rideStatsInit();
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
          //System.println("Activity saved");
        }
      }
    }
  }

  // Return the initial view of your application here
  function getInitialView() as Array<Views or InputDelegates>? {
    queue = new BleQueue();
    var profileManager = new eucPM();

    if (Toybox has :BluetoothLowEnergy) {
      profileManager.setManager();
      eucBleDelegate = new eucBLEDelegate(
        profileManager,
        queue,
        frameDecoder.init()
      );
      BluetoothLowEnergy.setDelegate(eucBleDelegate);
      profileManager.registerProfiles();
    }
    if (debug == true) {
      view = new GarminEUCDebugView();
      view.setBleDelegate(eucBleDelegate);
    } else {
      view = new GarminEUCView();
    }

    EUCSettingsDict = getEUCSettingsDict(); // in helper function
    actionButtonTrigger.setEUCDict();
    menu = createMenu(EUCSettingsDict.getConfigLabels(), "Settings");
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
      queue,
      actionButtonTrigger
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
        eucData.paired == true &&
        !activityrecordview.isSessionRecording()
      ) {
        //enable sensor first ?
        activityrecordview.enableGPS();
        activityrecordview.startRecording();
        //System.println("autorecord started");
      }
    }
    // -------------------------

    eucData.correctedSpeed = eucData.getCorrectedSpeed();
    eucData.PWM = eucData.getPWM();
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
        "Top Spd: " + valueRound(eucData.topSpeed, "%.1f").toString();
      //System.println(rideStats.statsArray[statsIndex]);
      statsIndex++;
    }
    if (rideStats.showWatchBatteryConsumptionStatistic) {
      rideStats.watchBatteryUsage();
      rideStats.statsArray[statsIndex] =
        "Wtch btry/h: " +
        valueRound(eucData.watchBatteryUsage, "%.1f").toString();
      //System.println(rideStats.statsArray[statsIndex]);
      statsIndex++;
    }
    if (rideStats.showTripDistance) {
      rideStats.statsArray[statsIndex] =
        "Trip dist: " + valueRound(eucData.tripDistance, "%.1f").toString();
      //System.println(rideStats.statsArray[statsIndex]);
      statsIndex++;
    }
    if (rideStats.showVoltage) {
      rideStats.statsArray[statsIndex] =
        "voltage: " + valueRound(eucData.getVoltage(), "%.2f").toString();
      //System.println(rideStats.statsArray[statsIndex]);
      statsIndex++;
    }
    if (rideStats.showWatchBatteryStatistic) {
      rideStats.statsArray[statsIndex] =
        "Wtch btry: " +
        valueRound(System.getSystemStats().battery, "%.1f").toString() +
        " %";
      //System.println(rideStats.statsArray[statsIndex]);
      statsIndex++;
    }

    WatchUi.requestUpdate();
  }

  function rideStatsInit() {
    rideStats.movingmsec = 0;
    rideStats.statsTimerReset();

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
    if (rideStats.showTripDistance) {
      rideStats.statsNumberToDiplay++;
    }
    if (rideStats.showVoltage) {
      rideStats.statsNumberToDiplay++;
    }
    if (rideStats.showWatchBatteryStatistic) {
      rideStats.statsNumberToDiplay++;
    }
    rideStats.statsArray = new [rideStats.statsNumberToDiplay];
    //System.println("array size:" + rideStats.statsArray.size());
  }
  function setSettings() {
    eucData.maxDisplayedSpeed = AppStorage.getSetting("maxSpeed");
    eucData.mainNumber = AppStorage.getSetting("mainNumber");
    eucData.topBar = AppStorage.getSetting("topBar");
    eucData.gothPWN = AppStorage.getSetting("begodeCF");
    eucData.currentCorrection = AppStorage.getSetting("currentCorrection");
    eucData.maxTemperature = AppStorage.getSetting("maxTemperature");
    eucData.updateDelay = AppStorage.getSetting("updateDelay");
    eucData.rotationSpeed = AppStorage.getSetting("rotationSpeed_PWM");
    eucData.rotationVoltage = AppStorage.getSetting("rotationVoltage_PWM");
    eucData.powerFactor = AppStorage.getSetting("powerFactor_PWM");
    eucData.voltage_scaling = AppStorage.getSetting("voltageCorrectionFactor");
    eucData.speedCorrectionFactor = AppStorage.getSetting(
      "speedCorrectionFactor"
    );

    eucData.alarmThreshold_PWM = AppStorage.getSetting("alarmThreshold_PWM");
    eucData.alarmThreshold_speed = AppStorage.getSetting(
      "alarmThreshold_speed"
    );
    eucData.alarmThreshold_temp = AppStorage.getSetting("alarmThreshold_temp");
    eucData.wheelBrand = AppStorage.getSetting("wheelBrand");
    activityAutorecording = AppStorage.getSetting("activityRecordingOnStartup");
    activityAutosave = AppStorage.getSetting("activitySavingOnExit");
    debug = AppStorage.getSetting("debugMode");

    rideStats.showAverageMovingSpeedStatistic = AppStorage.getSetting(
      "averageMovingSpeedStatistic"
    );
    rideStats.showTopSpeedStatistic =
      AppStorage.getSetting("topSpeedStatistic");

    rideStats.showWatchBatteryConsumptionStatistic = AppStorage.getSetting(
      "watchBatteryConsumptionStatistic"
    );
    rideStats.showTripDistance = AppStorage.getSetting("tripDistanceStatistic");

    rideStats.showVoltage = AppStorage.getSetting("voltageStatistic");
    rideStats.showWatchBatteryStatistic = AppStorage.getSetting(
      "watchBatteryStatistic"
    );
    actionButtonTrigger.recordActivityButton = AppStorage.getSetting(
      "recordActivityButtonMap"
    );
    actionButtonTrigger.cycleLightButton = AppStorage.getSetting(
      "cycleLightButtonMap"
    );
    actionButtonTrigger.beepButton = AppStorage.getSetting("beepButtonMap");
    actionButtonTrigger.delay = AppStorage.getSetting("actionQueueDelay");
  }
}

function getApp() as GarminEUCApp {
  return Application.getApp() as GarminEUCApp;
}
