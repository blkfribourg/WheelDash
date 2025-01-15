import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
using Toybox.System;
using Toybox.Lang;
using Toybox.BluetoothLowEnergy as Ble;
using Toybox.Timer;
using Toybox.Application.Storage;

class PSMenuDelegate extends WatchUi.Menu2InputDelegate {
  private var queue;
  private var eucBleDelegate;
  private var mainView;
  private var EUCSettingsDict;
  private var actionButtonTrigger;
  private var menu;
  private var menu2Delegate;
  private var mainViewdelegate;
  private var profileNb;
  private var connView;
  private var activityRecordView;

  function initialize() {
    System.println("InitialiseProfileSelectorDelegate");
    actionButtonTrigger = new ActionButton();
    Menu2InputDelegate.initialize();
    queue = new BleQueue();
    setGlobalSettings();
  }

  function onSelect(item) {
    setSettings(item.getId());

    connInit();
    Varia.initVaria();
    DFViewInit();
    rideStatsInit();
  }
  function onDone() {
    WatchUi.popView(WatchUi.SLIDE_DOWN);
  }
  function connInit() {
    // Initialize Alarms
    EUCAlarms.alarmsInit();

    if (Toybox has :BluetoothLowEnergy) {
      if (eucData.wheelBrand < 6) {
        eucPM.setManager();
        eucBleDelegate = new eucBLEDelegate(
          profileNb,
          queue,
          frameDecoder.init()
        );

        BluetoothLowEnergy.setDelegate(eucBleDelegate);
        eucPM.registerProfiles();
        if (eucData.ESP32Horn == true) {
          hornPM.registerProfiles();
        }
        if (eucData.useEngo == true) {
          engoPM.init();
          engoPM.registerProfiles();
          if (eucData.useMiles == true) {
            eucData.engoDistUnit = "mi";
            eucData.engoSpdUnit = "mph";
            eucData.engoTempUnit = "F";
          }
        }
      } else {
        if (eucData.ESP32Horn == true || eucData.useEngo == true) {
          eucBleDelegate = new eucBLEDelegate(
            profileNb,
            queue,
            frameDecoder.init()
          );

          BluetoothLowEnergy.setDelegate(eucBleDelegate);
          eucPM.registerProfiles();
          if (eucData.ESP32Horn == true) {
            hornPM.registerProfiles();
          }
          if (eucData.useEngo == true) {
            engoPM.init();
            engoPM.registerProfiles();
          }
        }
      }
    }
    viewInit();
  }
  function viewInit() {
    if (eucData.debug == true && eucBleDelegate != null) {
      mainView = new GarminEUCDebugView();
      mainView.setBleDelegate(eucBleDelegate);
    } else {
      if (eucData.dfViewOnly == true) {
        mainView = new DFView();
      } else {
        mainView = new GarminEUCView();
      }
    }
    eucData.dfViewBtn = actionButtonTrigger.DFViewButton;
    EUCSettingsDict = getEUCSettingsDict(); // in helper function
    actionButtonTrigger.setEUCDict();
    menu = createMenu(EUCSettingsDict.getConfigLabels(), "Settings");
    menu2Delegate = new GarminEUCMenu2Delegate_generic(
      menu,
      eucBleDelegate,
      queue,
      mainView,
      EUCSettingsDict
    );
    activityRecordView = new ActivityRecordView();
    //    activityRecordDelegate.setView(activityRecordView);
    mainViewdelegate = new GarminEUCDelegate(
      mainView,
      menu,
      menu2Delegate,
      eucBleDelegate,
      queue,
      activityRecordView,
      actionButtonTrigger
    );

    /*    if (
      eucData.speedLimit != 0 &&
      actionButtonTrigger.speedLimiterButton != 0
    ) {
      eucData.spdLimFeatEnabled = true;
    }
    */
    //   System.println(eucData.spdLimFeatEnabled);
    if (eucData.wheelBrand == 6) {
      WatchUi.pushView(mainView, mainViewdelegate, WatchUi.SLIDE_IMMEDIATE);
    } else {
      if (eucBleDelegate.eucFirst == false) {
        System.println("not first");
        /*
      if (
        eucData.spdLimFeatEnabled == true &&
        Storage.getValue("spdLimDisclDone") != true
      ) {
        connView = new messageView(eucBleDelegate, profileNb, self, "spdLimOn");
        connView.popViewDelay = 5000;
        WatchUi.pushView(connView, null, WatchUi.SLIDE_IMMEDIATE);
        Storage.setValue("spdLimDisclDone", true);
      } else {*/
        WatchUi.pushView(mainView, mainViewdelegate, WatchUi.SLIDE_IMMEDIATE);
        // }
      } else {
        System.println("first");
        connView = new messageView(eucBleDelegate, profileNb, self, "1stConn");
        WatchUi.switchToView(connView, null, WatchUi.SLIDE_IMMEDIATE);
      }
    }
  }

  function DFViewInit() {
    System.println("initializing DFView");
    if (
      !eucData.limitedMemory &&
      (eucData.dfViewBtn != 0 ||
        eucData.slideToDFView == true ||
        eucData.dfViewOnly == true)
    ) {
      if (getDFlikeView() == null) {
        // init DFlikeView
        var DFlikeView = new DFView();
        setDFlikeView(DFlikeView);
      }
    }
  }

  function rideStatsInit() {
    rideStats.movingmsec = 0;
    rideStats.statsTimerReset();

    if (rideStats.showAverageMovingSpeedStatistic) {
      rideStats.statsNumberToDiplay++;
    }
    if (rideStats.showTopSpeedStatistic) {
      rideStats.statsNumberToDiplay++;
    }
    if (rideStats.showWatchBatteryConsumptionStatistic) {
      rideStats.statsNumberToDiplay++;
    }
    if (rideStats.showTotalDistance) {
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
    if (rideStats.showProfileName) {
      rideStats.statsNumberToDiplay++;
    }
    rideStats.statsArray = new [rideStats.statsNumberToDiplay];
  }

  function unpair() {
    try {
      // eucBleDelegate.manualUnpair();
    } catch (e instanceof Lang.Exception) {
      System.println(e.getErrorMessage());
    }
  }
  function getView() {
    return mainView as View;
  }
  function getDelegate() {
    return mainViewdelegate;
  }
  function getMenu2Delegate() {
    return menu2Delegate;
  }
  function getActivityView() {
    if (mainViewdelegate != null) {
      return mainViewdelegate.getActivityView();
    } else {
      return null;
    }
  }

  function getDFlikeView() {
    if (mainViewdelegate != null) {
      return mainViewdelegate.getDFlikeView();
    } else {
      return null;
    }
  }

  function setDFlikeView(_DFLikeView) {
    mainViewdelegate.setDFlikeView(_DFLikeView);
  }
  function getBleDelegate() {
    if (mainViewdelegate != null) {
      return mainViewdelegate.getBleDelegate();
    } else {
      // System.println("bleNull");
      return null;
    }
  }

  function getDefaultSettings() {
    //load last used if exist or default profile if doesn't
    var lastProfile = Storage.getValue("lastProfile");

    if (lastProfile != null && AppStorage.getSetting("defaultProfile") == 0) {
      if (setSettings(lastProfile) == false) {
        // to avoid infinite loop if user change lastprofile profile name charge profile 1.
        setSettings(getProfileList()[0]);
      }

      connInit();
      DFViewInit();
      rideStatsInit();
    } else {
      setSettings(
        getProfileList()[AppStorage.getSetting("defaultProfile") - 1]
      );

      connInit();
      DFViewInit();
      rideStatsInit();
    }
  }
  function getProfileList() {
    return [
      AppStorage.getSetting("wheelName_p1"),
      AppStorage.getSetting("wheelName_p2"),
      AppStorage.getSetting("wheelName_p3"),
    ];
  }

  function setGlobalSettings() {
    // Global settings (not associated with a specific profileName) :

    eucData.useEngo = AppStorage.getSetting("useEngo");
    eucData.engoTouch = AppStorage.getSetting("engoTouch");
    eucData.useRadar = AppStorage.getSetting("useRadar");
    eucData.variaCloseAlarmDistThr = AppStorage.getSetting(
      "variaCloseAlarmDistThr"
    );
    eucData.variaFarAlarmDistThr = AppStorage.getSetting(
      "variaFarAlarmDistThr"
    );
    eucData.ESP32Horn = AppStorage.getSetting("ESP32Horn");
    eucData.motorbikeHeadset = AppStorage.getSetting("motorbikeHeadset");
    eucData.vibeIntensity = AppStorage.getSetting("vibeIntensity");
    eucData.alternativeFont = AppStorage.getSetting("alternativeFont");
    eucData.slideToDFView = AppStorage.getSetting("slideToDFView");
    eucData.dfViewOnly = AppStorage.getSetting("dfViewOnly");
    eucData.displayWind = AppStorage.getSetting("displayWind");
    eucData.displayNorth = AppStorage.getSetting("displayNorth");
    eucData.useMiles = AppStorage.getSetting("useMiles");
    eucData.useFahrenheit = AppStorage.getSetting("useFahrenheit");
    eucData.useEUCWorldAPI = AppStorage.getSetting("useEUCWorldAPI");
    eucData.convertToFahrenheit = AppStorage.getSetting("convertToFahrenheit");
    //Im Horn experimental
    eucData.imHornSound = AppStorage.getSetting("imHornSound");
    eucData.KSVoiceMode = AppStorage.getSetting("KSVoiceMode");
    eucData.updateDelay = AppStorage.getSetting("updateDelay");
    eucData.debug = AppStorage.getSetting("debugView");
    eucData.activityAutorecording = AppStorage.getSetting(
      "activityRecordingOnStartup"
    );
    eucData.activityAutosave = AppStorage.getSetting("activitySavingOnExit");

    rideStats.showAverageMovingSpeedStatistic = AppStorage.getSetting(
      "averageMovingSpeedStatistic"
    );
    rideStats.showTopSpeedStatistic =
      AppStorage.getSetting("topSpeedStatistic");

    rideStats.showWatchBatteryConsumptionStatistic = AppStorage.getSetting(
      "watchBatteryConsumptionStatistic"
    );
    rideStats.showTripDistance = AppStorage.getSetting("tripDistanceStatistic");
    rideStats.showTotalDistance = AppStorage.getSetting(
      "totalDistanceStatistic"
    );

    rideStats.showVoltage = AppStorage.getSetting("voltageStatistic");
    rideStats.showWatchBatteryStatistic = AppStorage.getSetting(
      "watchBatteryStatistic"
    );
    rideStats.showProfileName = AppStorage.getSetting("profileName");

    eucData.fieldIDs = [
      AppStorage.getSetting("field1"),
      AppStorage.getSetting("field2"),
      AppStorage.getSetting("field3"),
      AppStorage.getSetting("field4"),
      AppStorage.getSetting("field5"),
      AppStorage.getSetting("field6"),
      AppStorage.getSetting("field7"),
      AppStorage.getSetting("field8"),
    ];
    eucData.fieldNB = AppStorage.getSetting("fieldNB");

    // End of Global Settings
  }

  function setSettings(profileName) {
    // add return false if profileName not found
    var profiles = getProfileList();

    profileNb = profiles.indexOf(profileName) + 1;
    if (profileNb == 0) {
      return false;
    }

    eucData.maxDisplayedSpeed = AppStorage.getSetting("maxSpeed_p" + profileNb);
    eucData.mainNumber = AppStorage.getSetting("mainNumber_p" + profileNb);
    eucData.topBar = AppStorage.getSetting("topBar_p" + profileNb);
    eucData.gothPWM = AppStorage.getSetting("begodeCF_p" + profileNb);

    eucData.orangeColoringThreshold = AppStorage.getSetting(
      "orangeColoringThreshold_p" + profileNb
    );
    eucData.redColoringThreshold = AppStorage.getSetting(
      "redColoringThreshold_p" + profileNb
    );

    eucData.currentCorrection = AppStorage.getSetting(
      "currentCorrection_p" + profileNb
    );
    eucData.maxDisplayedTemperature = AppStorage.getSetting(
      "maxTemperature_p" + profileNb
    );

    eucData.rotationSpeed = AppStorage.getSetting(
      "rotationSpeed_PWM_p" + profileNb
    );
    eucData.rotationVoltage = AppStorage.getSetting(
      "rotationVoltage_PWM_p" + profileNb
    );
    eucData.powerFactor = AppStorage.getSetting(
      "powerFactor_PWM_p" + profileNb
    );
    eucData.voltage_scaling = AppStorage.getSetting(
      "voltageCorrectionFactor_p" + profileNb
    );
    eucData.sagThreshold = AppStorage.getSetting(
      "voltageSagIndicatorThresh_p" + profileNb
    );
    eucData.speedCorrectionFactor = AppStorage.getSetting(
      "speedCorrectionFactor_p" + profileNb
    );

    eucData.alarmThreshold_PWM = AppStorage.getSetting(
      "alarmThreshold_PWM_p" + profileNb
    );
    eucData.alarmThreshold2_PWM = AppStorage.getSetting(
      "alarmThreshold2_PWM_p" + profileNb
    );
    eucData.alarmThreshold_speed = AppStorage.getSetting(
      "alarmThreshold_speed_p" + profileNb
    );
    eucData.alarmThreshold_temp = AppStorage.getSetting(
      "alarmThreshold_temp_p" + profileNb
    );
    eucData.wheelBrand = AppStorage.getSetting("wheelBrand_p" + profileNb);

    actionButtonTrigger.recordActivityButton = AppStorage.getSetting(
      "recordActivityButtonMap_p" + profileNb
    );
    actionButtonTrigger.cycleLightButton = AppStorage.getSetting(
      "cycleLightButtonMap_p" + profileNb
    );
    actionButtonTrigger.DFViewButton = AppStorage.getSetting(
      "DFViewButtonMap_p" + profileNb
    );
    actionButtonTrigger.beepButton = AppStorage.getSetting(
      "beepButtonMap_p" + profileNb
    );
    actionButtonTrigger.engoNextButton = AppStorage.getSetting(
      "engoNextButtonMap_p" + profileNb
    );
    actionButtonTrigger.engoLumaButton = AppStorage.getSetting(
      "engoLumaButtonMap_p" + profileNb
    );
    eucData.BLECmdDelay = AppStorage.getSetting("cmdQueueDelay_p" + profileNb);

    eucData.wheelName = AppStorage.getSetting("wheelName_p" + profileNb);
    eucData.convertToMiles = AppStorage.getSetting(
      "convertToMiles_p" + profileNb
    );
    Storage.setValue("lastProfile", profileName);
    return true;
  }
}

class JSONPSMenuDelegate extends PSMenuDelegate {
  // Todo : remove/clean unecessary functions
  private var queue;
  private var eucBleDelegate;
  private var mainView;
  private var EUCSettingsDict;
  private var actionButtonTrigger;
  private var menu;
  private var menu2Delegate;
  private var mainViewdelegate;
  private var profileNb;
  private var connView;
  private var JSONSettingsDict;
  private var JSONSettings;
  private var activityRecordView;

  function initialize() {
    actionButtonTrigger = new ActionButton();
    Menu2InputDelegate.initialize();
    queue = new BleQueue();
    JSONSettingsDict = Storage.getValue("JSONSettings");
    if (JSONSettingsDict != null) {
      JSONSettings = JSONSettingsDict.get("settings");
    }

    setGlobalSettings();
    //activityRecordDelegate = new ActivityRecordDelegate();
  }
  function onSelect(item) {
    setSettings(item.getId());

    connInit();
    Varia.initVaria();
    DFViewInit();
    rideStatsInit();
  }
  function onDone() {
    WatchUi.popView(WatchUi.SLIDE_DOWN);
  }
  function connInit() {
    // Initialize Alarms
    EUCAlarms.alarmsInit();

    if (Toybox has :BluetoothLowEnergy) {
      if (eucData.wheelBrand < 6) {
        eucPM.setManager();
        eucBleDelegate = new eucBLEDelegate(
          profileNb,
          queue,
          frameDecoder.init()
        );
        System.println("BLEInit");
        BluetoothLowEnergy.setDelegate(eucBleDelegate);
        eucPM.registerProfiles();
        if (eucData.ESP32Horn == true) {
          hornPM.registerProfiles();
        }
        if (eucData.useEngo == true) {
          engoPM.init();
          engoPM.registerProfiles();
          if (eucData.useMiles == true) {
            eucData.engoDistUnit = "mi";
            eucData.engoSpdUnit = "mph";
            eucData.engoTempUnit = "F";
          }
        }
      } else {
        if (eucData.ESP32Horn == true || eucData.useEngo == true) {
          eucBleDelegate = new eucBLEDelegate(
            profileNb,
            queue,
            frameDecoder.init()
          );

          BluetoothLowEnergy.setDelegate(eucBleDelegate);
          eucPM.registerProfiles();
          if (eucData.ESP32Horn == true) {
            hornPM.registerProfiles();
          }
          if (eucData.useEngo == true) {
            engoPM.init();
            engoPM.registerProfiles();
          }
        }
      }
    }
    viewInit();
  }
  function viewInit() {
    if (eucData.debug == true && eucBleDelegate != null) {
      mainView = new GarminEUCDebugView();
      mainView.setBleDelegate(eucBleDelegate);
    } else {
      if (eucData.dfViewOnly == true) {
        mainView = new DFView();
      } else {
        mainView = new GarminEUCView();
      }
    }
    eucData.dfViewBtn = actionButtonTrigger.DFViewButton;
    EUCSettingsDict = getEUCSettingsDict(); // in helper function
    actionButtonTrigger.setEUCDict();
    menu = createMenu(EUCSettingsDict.getConfigLabels(), "Settings");
    menu2Delegate = new GarminEUCMenu2Delegate_generic(
      menu,
      eucBleDelegate,
      queue,
      mainView,
      EUCSettingsDict
    );
    activityRecordView = new ActivityRecordView();
    //    activityRecordDelegate.setView(activityRecordView);
    mainViewdelegate = new GarminEUCDelegate(
      mainView,
      menu,
      menu2Delegate,
      eucBleDelegate,
      queue,
      activityRecordView,
      actionButtonTrigger
    );

    /*    if (
      eucData.speedLimit != 0 &&
      actionButtonTrigger.speedLimiterButton != 0
    ) {
      eucData.spdLimFeatEnabled = true;
    }
    */
    //   System.println(eucData.spdLimFeatEnabled);
    if (eucData.wheelBrand == 6) {
      WatchUi.pushView(mainView, mainViewdelegate, WatchUi.SLIDE_IMMEDIATE);
    } else {
      if (eucBleDelegate.eucFirst == false) {
        System.println("not first");
        /*
      if (
        eucData.spdLimFeatEnabled == true &&
        Storage.getValue("spdLimDisclDone") != true
      ) {
        connView = new messageView(eucBleDelegate, profileNb, self, "spdLimOn");
        connView.popViewDelay = 5000;
        WatchUi.pushView(connView, null, WatchUi.SLIDE_IMMEDIATE);
        Storage.setValue("spdLimDisclDone", true);
      } else {*/
        WatchUi.pushView(mainView, mainViewdelegate, WatchUi.SLIDE_IMMEDIATE);
        // }
      } else {
        System.println("first");
        connView = new messageView(eucBleDelegate, profileNb, self, "1stConn");
        WatchUi.switchToView(connView, null, WatchUi.SLIDE_IMMEDIATE);
      }
    }
  }

  function DFViewInit() {
    System.println("initializing DFView");
    if (
      !eucData.limitedMemory &&
      (eucData.dfViewBtn != 0 ||
        eucData.slideToDFView == true ||
        eucData.dfViewOnly == true)
    ) {
      if (getDFlikeView() == null) {
        // init DFlikeView
        var DFlikeView = new DFView();
        setDFlikeView(DFlikeView);
      }
    }
  }

  function rideStatsInit() {
    rideStats.movingmsec = 0;
    rideStats.statsTimerReset();

    if (rideStats.showAverageMovingSpeedStatistic) {
      rideStats.statsNumberToDiplay++;
    }
    if (rideStats.showTopSpeedStatistic) {
      rideStats.statsNumberToDiplay++;
    }
    if (rideStats.showWatchBatteryConsumptionStatistic) {
      rideStats.statsNumberToDiplay++;
    }
    if (rideStats.showTotalDistance) {
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
    if (rideStats.showProfileName) {
      rideStats.statsNumberToDiplay++;
    }
    rideStats.statsArray = new [rideStats.statsNumberToDiplay];
  }

  function unpair() {
    try {
      // eucBleDelegate.manualUnpair();
    } catch (e instanceof Lang.Exception) {
      System.println(e.getErrorMessage());
    }
  }
  function getView() {
    return mainView as View;
  }
  function getDelegate() {
    return mainViewdelegate;
  }
  function getMenu2Delegate() {
    return menu2Delegate;
  }
  function getActivityView() {
    if (mainViewdelegate != null) {
      return mainViewdelegate.getActivityView();
    } else {
      return null;
    }
  }

  function getDFlikeView() {
    if (mainViewdelegate != null) {
      return mainViewdelegate.getDFlikeView();
    } else {
      return null;
    }
  }

  function setDFlikeView(_DFLikeView) {
    mainViewdelegate.setDFlikeView(_DFLikeView);
  }
  function getBleDelegate() {
    if (mainViewdelegate != null) {
      return mainViewdelegate.getBleDelegate();
    } else {
      //   System.println("bleNull");
      return null;
    }
  }
  function getDefaultSettings() {
    //load last used if exist or profile 1 if doesn't
    var lastProfile = Storage.getValue("lastProfile");

    if (lastProfile != null && JSONSettings.get("defaultProfile") == 0) {
      if (setSettings(lastProfile) == false) {
        // to avoid infinite loop if user change lastprofile profile name charge profile 1.
        setSettings(profileSelector.getJSONProfileList()[0]);
      }

      connInit();
      DFViewInit();
      rideStatsInit();
    } else {
      System.println(
        (JSONSettings.get("defaultProfile") as Dictionary).get("v") as String
      );
      setSettings(
        profileSelector.getJSONProfileList()[
          (
            (JSONSettings.get("defaultProfile") as Dictionary).get("v") as
              String
          ).toNumber() - 1
        ]
      );

      connInit();
      DFViewInit();
      rideStatsInit();
    }
  }
  function setGlobalSettings() {
    // Global Settings (not associated with a specific ProfileName) :
    if (JSONSettings.get("useEngo") != null) {
      eucData.useEngo = (JSONSettings.get("useEngo") as Dictionary).get("v");
    }

    if (JSONSettings.get("engoTouch") != null) {
      eucData.engoTouch = (
        (JSONSettings.get("engoTouch") as Dictionary).get("v") as String
      ).toNumber();
    }
    if (JSONSettings.get("useRadar") != null) {
      eucData.useRadar = (JSONSettings.get("useRadar") as Dictionary).get("v");
    }

    if (JSONSettings.get("variaCloseAlarmDistThr") != null) {
      eucData.variaCloseAlarmDistThr = (
        (JSONSettings.get("variaCloseAlarmDistThr") as Dictionary).get("v") as
          String
      ).toNumber();
    }

    if (JSONSettings.get("variaFarAlarmDistThr") != null) {
      eucData.variaFarAlarmDistThr = (
        (JSONSettings.get("variaFarAlarmDistThr") as Dictionary).get("v") as
          String
      ).toNumber();
    }

    if (JSONSettings.get("ESP32Horn") != null) {
      eucData.ESP32Horn = (JSONSettings.get("ESP32Horn") as Dictionary).get(
        "v"
      );
    }

    if (JSONSettings.get("motorbikeHeadset") != null) {
      eucData.motorbikeHeadset = (
        JSONSettings.get("motorbikeHeadset") as Dictionary
      ).get("v");
    }

    if (JSONSettings.get("vibeIntensity") != null) {
      eucData.vibeIntensity = (
        (JSONSettings.get("vibeIntensity") as Dictionary).get("v") as String
      ).toNumber();
    }

    if (JSONSettings.get("alternativeFont") != null) {
      eucData.alternativeFont = (
        JSONSettings.get("alternativeFont") as Dictionary
      ).get("v");
    }

    if (JSONSettings.get("slideToDFView") != null) {
      eucData.slideToDFView = (
        JSONSettings.get("slideToDFView") as Dictionary
      ).get("v");
    }

    if (JSONSettings.get("dfViewOnly") != null) {
      eucData.dfViewOnly = (JSONSettings.get("dfViewOnly") as Dictionary).get(
        "v"
      );
    }
    if (JSONSettings.get("displayWind") != null) {
      eucData.displayWind = (JSONSettings.get("displayWind") as Dictionary).get(
        "v"
      );
    }

    if (JSONSettings.get("displayNorth") != null) {
      eucData.displayNorth = (
        JSONSettings.get("displayNorth") as Dictionary
      ).get("v");
    }
    if (JSONSettings.get("useMiles") != null) {
      eucData.useMiles = (JSONSettings.get("useMiles") as Dictionary).get("v");
    }
    if (JSONSettings.get("useFahrenheit") != null) {
      eucData.useFahrenheit = (
        JSONSettings.get("useFahrenheit") as Dictionary
      ).get("v");
    }

    if (JSONSettings.get("useEUCWorldAPI") != null) {
      eucData.useEUCWorldAPI = (
        JSONSettings.get("useEUCWorldAPI") as Dictionary
      ).get("v");
    }
    if (JSONSettings.get("convertToFahrenheit") != null) {
      eucData.convertToFahrenheit = (
        JSONSettings.get("convertToFahrenheit") as Dictionary
      ).get("v");
    }

    //Im Horn experimental
    if (JSONSettings.get("imHornSound") != null) {
      eucData.imHornSound = (
        (JSONSettings.get("imHornSound") as Dictionary).get("v") as String
      ).toNumber();
    }

    if (JSONSettings.get("KSVoiceMode") != null) {
      eucData.KSVoiceMode = (JSONSettings.get("KSVoiceMode") as Dictionary).get(
        "v"
      );
    }
    if (JSONSettings.get("updateDelay") != null) {
      eucData.updateDelay = (
        (JSONSettings.get("updateDelay") as Dictionary).get("v") as String
      ).toNumber();
    }
    if (JSONSettings.get("debugView") != null) {
      eucData.debug = (JSONSettings.get("debugView") as Dictionary).get("v");
    }

    if (JSONSettings.get("activityRecordingOnStartup") != null) {
      eucData.activityAutorecording = (
        JSONSettings.get("activityRecordingOnStartup") as Dictionary
      ).get("v");
    }
    if (JSONSettings.get("activitySavingOnExit") != null) {
      eucData.activityAutosave = (
        JSONSettings.get("activitySavingOnExit") as Dictionary
      ).get("v");
    }

    if (JSONSettings.get("averageMovingSpeedStatistic") != null) {
      rideStats.showAverageMovingSpeedStatistic = (
        JSONSettings.get("averageMovingSpeedStatistic") as Dictionary
      ).get("v");
    }
    if (JSONSettings.get("topSpeedStatistic") != null) {
      rideStats.showTopSpeedStatistic = (
        JSONSettings.get("topSpeedStatistic") as Dictionary
      ).get("v");
    }
    if (JSONSettings.get("watchBatteryConsumptionStatistic") != null) {
      rideStats.showWatchBatteryConsumptionStatistic = (
        JSONSettings.get("watchBatteryConsumptionStatistic") as Dictionary
      ).get("v");
    }
    if (JSONSettings.get("tripDistanceStatistic") != null) {
      rideStats.showTripDistance = (
        JSONSettings.get("tripDistanceStatistic") as Dictionary
      ).get("v");
    }

    if (JSONSettings.get("totalDistanceStatistic") != null) {
      rideStats.showTotalDistance = (
        JSONSettings.get("totalDistanceStatistic") as Dictionary
      ).get("v");
    }

    if (JSONSettings.get("voltageStatistic") != null) {
      rideStats.showVoltage = (
        JSONSettings.get("voltageStatistic") as Dictionary
      ).get("v");
    }
    if (JSONSettings.get("watchBatteryStatistic") != null) {
      rideStats.showWatchBatteryStatistic = (
        JSONSettings.get("watchBatteryStatistic") as Dictionary
      ).get("v");
    }

    if (JSONSettings.get("profileName") != null) {
      rideStats.showProfileName = (
        JSONSettings.get("profileName") as Dictionary
      ).get("v");
    }

    if (JSONSettings.get("fieldNB") != null) {
      eucData.fieldNB = (
        (JSONSettings.get("fieldNB") as Dictionary).get("v") as String
      ).toNumber();
    }
    if (eucData.fieldNB != null) {
      eucData.fieldIDs = new [eucData.fieldNB];
      for (var i = 0; i < eucData.fieldNB; i++) {
        if (JSONSettings.get("field" + (i + 1)) != null) {
          eucData.fieldIDs[i] = (
            (JSONSettings.get("field" + (i + 1)) as Dictionary).get("v") as
              String
          ).toNumber();
        } else {
          System.println("fallback to default settings for DF-view");
          //fallback to default
          eucData.fieldIDs = [
            AppStorage.getSetting("field1"),
            AppStorage.getSetting("field2"),
            AppStorage.getSetting("field3"),
            AppStorage.getSetting("field4"),
            AppStorage.getSetting("field5"),
            AppStorage.getSetting("field6"),
            AppStorage.getSetting("field7"),
            AppStorage.getSetting("field8"),
          ];
          eucData.fieldNB = AppStorage.getSetting("fieldNB");
          break;
        }
      }
    }
    // end of global Setting
  }

  function setSettings(profileName) {
    var profiles = profileSelector.getJSONProfileList();
    profileNb = profiles.indexOf(profileName) + 1;

    if (profileNb == 0) {
      return false;
    }
    //System.println("profileNb: " + profileNb);
    //System.println("maxSpeed_p" + profileNb);
    //  System.println(JSONSettings);
    if (JSONSettings.get("maxSpeed_p" + profileNb) != null) {
      eucData.maxDisplayedSpeed = (
        (JSONSettings.get("maxSpeed_p" + profileNb) as Dictionary).get("v") as
          String
      ).toNumber();
    }
    if (JSONSettings.get("mainNumber_p" + profileNb) != null) {
      eucData.mainNumber = (
        (JSONSettings.get("mainNumber_p" + profileNb) as Dictionary).get("v") as
          String
      ).toNumber();
    }
    if (JSONSettings.get("topBar_p" + profileNb) != null) {
      eucData.topBar = (
        (JSONSettings.get("topBar_p" + profileNb) as Dictionary).get("v") as
          String
      ).toNumber();
    }
    if (JSONSettings.get("begodeCF_p" + profileNb) != null) {
      eucData.gothPWM = (
        JSONSettings.get("begodeCF_p" + profileNb) as Dictionary
      ).get("v");
    }
    if (JSONSettings.get("orangeColoringThreshold_p" + profileNb) != null) {
      eucData.orangeColoringThreshold = (
        (
          JSONSettings.get("orangeColoringThreshold_p" + profileNb) as
            Dictionary
        ).get("v") as String
      ).toNumber();
    }
    if (JSONSettings.get("redColoringThreshold_p" + profileNb) != null) {
      eucData.redColoringThreshold = (
        (
          JSONSettings.get("redColoringThreshold_p" + profileNb) as Dictionary
        ).get("v") as String
      ).toNumber();
    }
    if (JSONSettings.get("currentCorrection_p" + profileNb) != null) {
      eucData.currentCorrection = (
        (JSONSettings.get("currentCorrection_p" + profileNb) as Dictionary).get(
          "v"
        ) as String
      ).toNumber();
    }
    if (JSONSettings.get("maxTemperature_p" + profileNb) != null) {
      eucData.maxDisplayedTemperature = (
        (JSONSettings.get("maxTemperature_p" + profileNb) as Dictionary).get(
          "v"
        ) as String
      ).toNumber();
    }
    if (JSONSettings.get("rotationSpeed_PWM_p" + profileNb) != null) {
      eucData.rotationSpeed = (
        (JSONSettings.get("rotationSpeed_PWM_p" + profileNb) as Dictionary).get(
          "v"
        ) as String
      ).toFloat();
    }
    if (JSONSettings.get("rotationVoltage_PWM_p" + profileNb) != null) {
      eucData.rotationVoltage = (
        (
          JSONSettings.get("rotationVoltage_PWM_p" + profileNb) as Dictionary
        ).get("v") as String
      ).toFloat();
    }
    if (JSONSettings.get("powerFactor_PWM_p" + profileNb) != null) {
      eucData.powerFactor = (
        (JSONSettings.get("powerFactor_PWM_p" + profileNb) as Dictionary).get(
          "v"
        ) as String
      ).toFloat();
    }
    if (JSONSettings.get("voltageCorrectionFactor_p" + profileNb) != null) {
      eucData.voltage_scaling = (
        (
          JSONSettings.get("voltageCorrectionFactor_p" + profileNb) as
            Dictionary
        ).get("v") as String
      ).toFloat();
    }
    if (JSONSettings.get("voltageSagIndicatorThresh_p" + profileNb) != null) {
      eucData.sagThreshold = (
        (
          JSONSettings.get("voltageSagIndicatorThresh_p" + profileNb) as
            Dictionary
        ).get("v") as String
      ).toFloat();
    }
    if (JSONSettings.get("speedCorrectionFactor_p" + profileNb) != null) {
      eucData.speedCorrectionFactor = (
        (
          JSONSettings.get("speedCorrectionFactor_p" + profileNb) as Dictionary
        ).get("v") as String
      ).toFloat();
    }
    if (JSONSettings.get("alarmThreshold_PWM_p" + profileNb) != null) {
      eucData.alarmThreshold_PWM = (
        (
          JSONSettings.get("alarmThreshold_PWM_p" + profileNb) as Dictionary
        ).get("v") as String
      ).toNumber();
      System.println(eucData.alarmThreshold_PWM);
    }
    if (JSONSettings.get("alarmThreshold2_PWM_p" + profileNb) != null) {
      eucData.alarmThreshold2_PWM = (
        (
          JSONSettings.get("alarmThreshold2_PWM_p" + profileNb) as Dictionary
        ).get("v") as String
      ).toNumber();
    }
    if (JSONSettings.get("alarmThreshold_speed_p" + profileNb) != null) {
      eucData.alarmThreshold_speed = (
        (
          JSONSettings.get("alarmThreshold_speed_p" + profileNb) as Dictionary
        ).get("v") as String
      ).toNumber();
    }
    if (JSONSettings.get("alarmThreshold_temp_p" + profileNb) != null) {
      eucData.alarmThreshold_temp = (
        (
          JSONSettings.get("alarmThreshold_temp_p" + profileNb) as Dictionary
        ).get("v") as String
      ).toNumber();
    }
    if (JSONSettings.get("wheelBrand_p" + profileNb) != null) {
      eucData.wheelBrand = (
        (JSONSettings.get("wheelBrand_p" + profileNb) as Dictionary).get("v") as
          String
      ).toNumber();
    }
    if (JSONSettings.get("recordActivityButtonMap_p" + profileNb) != null) {
      actionButtonTrigger.recordActivityButton = (
        (
          JSONSettings.get("recordActivityButtonMap_p" + profileNb) as
            Dictionary
        ).get("v") as String
      ).toNumber();
    }
    if (JSONSettings.get("cycleLightButtonMap_p" + profileNb) != null) {
      actionButtonTrigger.cycleLightButton = (
        (
          JSONSettings.get("cycleLightButtonMap_p" + profileNb) as Dictionary
        ).get("v") as String
      ).toNumber();
    }
    if (JSONSettings.get("DFViewButtonMap_p" + profileNb) != null) {
      actionButtonTrigger.DFViewButton = (
        (JSONSettings.get("DFViewButtonMap_p" + profileNb) as Dictionary).get(
          "v"
        ) as String
      ).toNumber();
    }
    if (JSONSettings.get("beepButtonMap_p" + profileNb) != null) {
      actionButtonTrigger.beepButton = (
        (JSONSettings.get("beepButtonMap_p" + profileNb) as Dictionary).get(
          "v"
        ) as String
      ).toNumber();
    }
    if (JSONSettings.get("engoNextButtonMap_p" + profileNb) != null) {
      actionButtonTrigger.engoNextButton = (
        (JSONSettings.get("engoNextButtonMap_p" + profileNb) as Dictionary).get(
          "v"
        ) as String
      ).toNumber();
    }
    if (JSONSettings.get("engoLumaButtonMap_p" + profileNb) != null) {
      actionButtonTrigger.engoLumaButton = (
        (JSONSettings.get("engoLumaButtonMap_p" + profileNb) as Dictionary).get(
          "v"
        ) as String
      ).toNumber();
    }
    if (JSONSettings.get("cmdQueueDelay_p" + profileNb) != null) {
      eucData.BLECmdDelay = (
        (JSONSettings.get("cmdQueueDelay_p" + profileNb) as Dictionary).get(
          "v"
        ) as String
      ).toNumber();
    }
    if (JSONSettings.get("wheelName_p" + profileNb) != null) {
      eucData.wheelName = (
        JSONSettings.get("wheelName_p" + profileNb) as Dictionary
      ).get("v");
    }
    if (JSONSettings.get("convertToMiles_p" + profileNb) != null) {
      eucData.convertToMiles = (
        JSONSettings.get("convertToMiles_p" + profileNb) as Dictionary
      ).get("v");
    }
    Storage.setValue("lastProfile", profileName);

    return true;
  }
}
