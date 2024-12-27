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
    actionButtonTrigger = new ActionButton();
    Menu2InputDelegate.initialize();
    queue = new BleQueue();
    //activityRecordDelegate = new ActivityRecordDelegate();
  }

  function onSelect(item) {
    setSettings(item.getId());
    connInit();
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
      if (eucBleDelegate.isFirst == false) {
        //System.println("not first");
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
        //  System.println("first");
        connView = new messageView(eucBleDelegate, profileNb, self, "1stConn");
        WatchUi.pushView(connView, null, WatchUi.SLIDE_IMMEDIATE);
      }
    }
  }
  function unpair() {
    try {
      // eucBleDelegate.manualUnpair();
    } catch (e instanceof Lang.Exception) {
      System.println(e.getErrorMessage());
    }
  }
  function getView() {
    return mainView;
  }
  function getDelegate() {
    return mainViewdelegate;
  }
  function getMenu2Delegate() {
    return menu2Delegate;
  }
  function getActivityView() {
    return mainViewdelegate.getActivityView();
  }

  function getDFlikeView() {
    return mainViewdelegate.getDFlikeView();
  }

  function setDFlikeView(_DFLikeView) {
    mainViewdelegate.setDFlikeView(_DFLikeView);
  }
  function getBleDelegate() {
    return mainViewdelegate.getBleDelegate();
  }

  function getDefaultSettings(profileIdx) {
    //load last used if exist or default profile if doesn't
    var lastProfile = Storage.getValue("lastProfile");

    if (lastProfile != null && AppStorage.getSetting("defaultProfile") == 0) {
      if (setSettings(lastProfile) == false) {
        // to avoid infinite loop if user change lastprofile profile name charge profile 1.
        setSettings(getProfileList()[0]);
      }
      connInit();
    } else {
      setSettings(
        getProfileList()[AppStorage.getSetting("defaultProfile") - 1]
      );
      connInit();
    }
  }
  function getProfileList() {
    return [
      AppStorage.getSetting("wheelName_p1"),
      AppStorage.getSetting("wheelName_p2"),
      AppStorage.getSetting("wheelName_p3"),
    ];
  }

  function setSettings(profileName) {
    var profiles = getProfileList();
    System.println(profileName);
    System.println(profiles.indexOf(profileName) + 1);
    profileNb = profiles.indexOf(profileName) + 1;

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
  // should add some fallback to PSMenuDelegate if JSONSettings is not available!
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
    //activityRecordDelegate = new ActivityRecordDelegate();
  }

  function onSelect(item) {
    setSettings(item.getId());
    connInit();
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
      if (eucBleDelegate.isFirst == false) {
        //System.println("not first");
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
        //  System.println("first");
        connView = new messageView(eucBleDelegate, profileNb, self, "1stConn");
        WatchUi.pushView(connView, null, WatchUi.SLIDE_IMMEDIATE);
      }
    }
  }
  function unpair() {
    try {
      // eucBleDelegate.manualUnpair();
    } catch (e instanceof Lang.Exception) {
      System.println(e.getErrorMessage());
    }
  }
  function getView() {
    return mainView;
  }
  function getDelegate() {
    return mainViewdelegate;
  }
  function getMenu2Delegate() {
    return menu2Delegate;
  }
  function getActivityView() {
    return mainViewdelegate.getActivityView();
  }

  function getDFlikeView() {
    return mainViewdelegate.getDFlikeView();
  }

  function setDFlikeView(_DFLikeView) {
    mainViewdelegate.setDFlikeView(_DFLikeView);
  }
  function getBleDelegate() {
    return mainViewdelegate.getBleDelegate();
  }

  function getDefaultSettings(profileIdx) {
    System.println("loading: " + profileIdx);

    //load last used if exist or profile 1 if doesn't
    var lastProfile = Storage.getValue("lastProfile");

    if (lastProfile != null && JSONSettings.get("defaultProfile") == 0) {
      if (setSettings(lastProfile) == false) {
        // to avoid infinite loop if user change lastprofile profile name charge profile 1.
        setSettings(profileSelector.getJSONProfileList()[0]);
      }
      connInit();
    } else {
      setSettings(
        profileSelector.getJSONProfileList()[
          (
            (JSONSettings.get("defaultProfile") as Dictionary).get("v") as
              String
          ).toNumber() - 1
        ]
      );
      connInit();
    }
  }

  function setSettings(profileName) {
    var profiles = profileSelector.getJSONProfileList();
    profileNb = profiles.indexOf(profileName) + 1;
    //System.println("profileNb: " + profileNb);
    //System.println("maxSpeed_p" + profileNb);
    //  System.println(JSONSettings);
    eucData.maxDisplayedSpeed = (
      (JSONSettings.get("maxSpeed_p" + profileNb) as Dictionary).get("v") as
        String
    ).toNumber();
    eucData.mainNumber = (
      (JSONSettings.get("mainNumber_p" + profileNb) as Dictionary).get("v") as
        String
    ).toNumber();
    eucData.topBar = (
      (JSONSettings.get("topBar_p" + profileNb) as Dictionary).get("v") as
        String
    ).toNumber();
    eucData.gothPWM = (
      JSONSettings.get("begodeCF_p" + profileNb) as Dictionary
    ).get("v");

    eucData.orangeColoringThreshold = (
      (
        JSONSettings.get("orangeColoringThreshold_p" + profileNb) as Dictionary
      ).get("v") as String
    ).toNumber();

    eucData.redColoringThreshold = (
      (
        JSONSettings.get("redColoringThreshold_p" + profileNb) as Dictionary
      ).get("v") as String
    ).toNumber();

    eucData.currentCorrection = (
      (JSONSettings.get("currentCorrection_p" + profileNb) as Dictionary).get(
        "v"
      ) as String
    ).toNumber();
    eucData.maxDisplayedTemperature = (
      (JSONSettings.get("maxTemperature_p" + profileNb) as Dictionary).get(
        "v"
      ) as String
    ).toNumber();

    eucData.rotationSpeed = (
      (JSONSettings.get("rotationSpeed_PWM_p" + profileNb) as Dictionary).get(
        "v"
      ) as String
    ).toFloat();
    eucData.rotationVoltage = (
      (JSONSettings.get("rotationVoltage_PWM_p" + profileNb) as Dictionary).get(
        "v"
      ) as String
    ).toFloat();
    eucData.powerFactor = (
      (JSONSettings.get("powerFactor_PWM_p" + profileNb) as Dictionary).get(
        "v"
      ) as String
    ).toFloat();
    eucData.voltage_scaling = (
      (
        JSONSettings.get("voltageCorrectionFactor_p" + profileNb) as Dictionary
      ).get("v") as String
    ).toFloat();
    eucData.sagThreshold = (
      (
        JSONSettings.get("voltageSagIndicatorThresh_p" + profileNb) as
          Dictionary
      ).get("v") as String
    ).toFloat();
    eucData.speedCorrectionFactor = (
      (
        JSONSettings.get("speedCorrectionFactor_p" + profileNb) as Dictionary
      ).get("v") as String
    ).toFloat();

    eucData.alarmThreshold_PWM = (
      (JSONSettings.get("alarmThreshold_PWM_p" + profileNb) as Dictionary).get(
        "v"
      ) as String
    ).toNumber();
    eucData.alarmThreshold2_PWM = (
      (JSONSettings.get("alarmThreshold2_PWM_p" + profileNb) as Dictionary).get(
        "v"
      ) as String
    ).toNumber();
    eucData.alarmThreshold_speed = (
      (
        JSONSettings.get("alarmThreshold_speed_p" + profileNb) as Dictionary
      ).get("v") as String
    ).toNumber();
    eucData.alarmThreshold_temp = (
      (JSONSettings.get("alarmThreshold_temp_p" + profileNb) as Dictionary).get(
        "v"
      ) as String
    ).toNumber();
    eucData.wheelBrand = (
      (JSONSettings.get("wheelBrand_p" + profileNb) as Dictionary).get("v") as
        String
    ).toNumber();

    actionButtonTrigger.recordActivityButton = (
      (
        JSONSettings.get("recordActivityButtonMap_p" + profileNb) as Dictionary
      ).get("v") as String
    ).toNumber();
    actionButtonTrigger.cycleLightButton = (
      (JSONSettings.get("cycleLightButtonMap_p" + profileNb) as Dictionary).get(
        "v"
      ) as String
    ).toNumber();
    actionButtonTrigger.DFViewButton = (
      (JSONSettings.get("DFViewButtonMap_p" + profileNb) as Dictionary).get(
        "v"
      ) as String
    ).toNumber();
    actionButtonTrigger.beepButton = (
      (JSONSettings.get("beepButtonMap_p" + profileNb) as Dictionary).get(
        "v"
      ) as String
    ).toNumber();
    eucData.BLECmdDelay = (
      (JSONSettings.get("cmdQueueDelay_p" + profileNb) as Dictionary).get(
        "v"
      ) as String
    ).toNumber();

    eucData.wheelName = (
      JSONSettings.get("wheelName_p" + profileNb) as Dictionary
    ).get("v");
    eucData.convertToMiles = (
      JSONSettings.get("convertToMiles_p" + profileNb) as Dictionary
    ).get("v");
    Storage.setValue("lastProfile", profileName);
    return true;
  }
}
