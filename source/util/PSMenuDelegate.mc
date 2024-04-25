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
    var profileManager = new eucPM();

    if (Toybox has :BluetoothLowEnergy) {
      profileManager.setManager();
      eucBleDelegate = new eucBLEDelegate(
        profileManager,
        profileNb,
        queue,
        frameDecoder.init()
      );
      BluetoothLowEnergy.setDelegate(eucBleDelegate);
      profileManager.registerProfiles();
    }

    viewInit();
  }
  function viewInit() {
    if (eucData.debug == true) {
      mainView = new GarminEUCDebugView();
      mainView.setBleDelegate(eucBleDelegate);
    } else {
      mainView = new GarminEUCView();
    }
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

    if (eucBleDelegate.isFirst == false) {
      //System.println("not first");

      WatchUi.pushView(mainView, mainViewdelegate, WatchUi.SLIDE_IMMEDIATE);
    } else {
      //  System.println("first");
      connView = new connectionView(eucBleDelegate, profileNb, self);
      WatchUi.pushView(connView, null, WatchUi.SLIDE_IMMEDIATE);
    }
  }
  function unpair() {
    eucBleDelegate.manualUnpair();
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

  function setSettings(profileName) {
    var profileSelected = pickProfile(profileName);
    if (profileSelected != true) {
      //load last used if exist or profile 1 if doesn't
      var lastProfile = Storage.getValue("lastProfile");

      if (lastProfile != null && AppStorage.getSetting("defaultProfile") == 0) {
        if (pickProfile(lastProfile) == false) {
          // to avoid infinite loop if user change lastprofile profile name charge profile 1.
          pickProfile(getProfileList()[0]);
        }
        connInit();
      } else {
        pickProfile(
          getProfileList()[AppStorage.getSetting("defaultProfile") - 1]
        );
        connInit();
      }
    }
  }
  function getProfileList() {
    return [
      AppStorage.getSetting("wheelName_p1"),
      AppStorage.getSetting("wheelName_p2"),
      AppStorage.getSetting("wheelName_p3"),
    ];
  }
  function pickProfile(profileName) {
    var profiles = getProfileList();

    profileNb = profiles.indexOf(profileName) + 1;

    if (profileNb == 1) {
      eucData.maxDisplayedSpeed = AppStorage.getSetting("maxSpeed_p1");
      eucData.mainNumber = AppStorage.getSetting("mainNumber_p1");
      eucData.topBar = AppStorage.getSetting("topBar_p1");
      eucData.gothPWM = AppStorage.getSetting("begodeCF_p1");

      eucData.orangeColoringThreshold = AppStorage.getSetting(
        "orangeColoringThreshold_p1"
      );
      eucData.redColoringThreshold = AppStorage.getSetting(
        "redColoringThreshold_p1"
      );

      eucData.currentCorrection = AppStorage.getSetting("currentCorrection_p1");
      eucData.maxDisplayedTemperature =
        AppStorage.getSetting("maxTemperature_p1");

      eucData.rotationSpeed = AppStorage.getSetting("rotationSpeed_PWM_p1");
      eucData.rotationVoltage = AppStorage.getSetting("rotationVoltage_PWM_p1");
      eucData.powerFactor = AppStorage.getSetting("powerFactor_PWM_p1");
      eucData.voltage_scaling = AppStorage.getSetting(
        "voltageCorrectionFactor_p1"
      );
      eucData.sagThreshold = AppStorage.getSetting(
        "voltageSagIndicatorThresh_p1"
      );
      eucData.speedCorrectionFactor = AppStorage.getSetting(
        "speedCorrectionFactor_p1"
      );

      eucData.alarmThreshold_PWM = AppStorage.getSetting(
        "alarmThreshold_PWM_p1"
      );
      eucData.alarmThreshold_speed = AppStorage.getSetting(
        "alarmThreshold_speed_p1"
      );
      eucData.alarmThreshold_temp = AppStorage.getSetting(
        "alarmThreshold_temp_p1"
      );
      eucData.wheelBrand = AppStorage.getSetting("wheelBrand_p1");

      actionButtonTrigger.recordActivityButton = AppStorage.getSetting(
        "recordActivityButtonMap_p1"
      );
      actionButtonTrigger.cycleLightButton = AppStorage.getSetting(
        "cycleLightButtonMap_p1"
      );
      actionButtonTrigger.beepButton =
        AppStorage.getSetting("beepButtonMap_p1");
      eucData.BLECmdDelay = AppStorage.getSetting("cmdQueueDelay_p1");
      eucData.VESCCanId = AppStorage.getSetting("VESCCanId_p1");
      eucData.wheelName = AppStorage.getSetting("wheelName_p1");
      Storage.setValue("lastProfile", profileName);
      return true;
    } else if (profileNb == 2) {
      eucData.maxDisplayedSpeed = AppStorage.getSetting("maxSpeed_p2");
      eucData.mainNumber = AppStorage.getSetting("mainNumber_p2");
      eucData.topBar = AppStorage.getSetting("topBar_p2");
      eucData.gothPWM = AppStorage.getSetting("begodeCF_p2");

      eucData.orangeColoringThreshold = AppStorage.getSetting(
        "orangeColoringThreshold_p2"
      );
      eucData.redColoringThreshold = AppStorage.getSetting(
        "redColoringThreshold_p2"
      );

      eucData.currentCorrection = AppStorage.getSetting("currentCorrection_p2");
      eucData.maxDisplayedTemperature =
        AppStorage.getSetting("maxTemperature_p2");
      eucData.rotationSpeed = AppStorage.getSetting("rotationSpeed_PWM_p2");
      eucData.rotationVoltage = AppStorage.getSetting("rotationVoltage_PWM_p2");
      eucData.powerFactor = AppStorage.getSetting("powerFactor_PWM_p2");
      eucData.voltage_scaling = AppStorage.getSetting(
        "voltageCorrectionFactor_p2"
      );
      eucData.sagThreshold = AppStorage.getSetting(
        "voltageSagIndicatorThresh_p2"
      );
      eucData.speedCorrectionFactor = AppStorage.getSetting(
        "speedCorrectionFactor_p2"
      );

      eucData.alarmThreshold_PWM = AppStorage.getSetting(
        "alarmThreshold_PWM_p2"
      );
      eucData.alarmThreshold_speed = AppStorage.getSetting(
        "alarmThreshold_speed_p2"
      );
      eucData.alarmThreshold_temp = AppStorage.getSetting(
        "alarmThreshold_temp_p2"
      );
      eucData.wheelBrand = AppStorage.getSetting("wheelBrand_p2");

      actionButtonTrigger.recordActivityButton = AppStorage.getSetting(
        "recordActivityButtonMap_p2"
      );
      actionButtonTrigger.cycleLightButton = AppStorage.getSetting(
        "cycleLightButtonMap_p2"
      );
      actionButtonTrigger.beepButton =
        AppStorage.getSetting("beepButtonMap_p2");
      eucData.BLECmdDelay = AppStorage.getSetting("cmdQueueDelay_p2");
      eucData.VESCCanId = AppStorage.getSetting("VESCCanId_p2");
      eucData.wheelName = AppStorage.getSetting("wheelName_p2");
      Storage.setValue("lastProfile", profileName);
      return true;
    } else if (profileNb == 3) {
      eucData.maxDisplayedSpeed = AppStorage.getSetting("maxSpeed_p3");
      eucData.mainNumber = AppStorage.getSetting("mainNumber_p3");
      eucData.topBar = AppStorage.getSetting("topBar_p3");
      eucData.gothPWM = AppStorage.getSetting("begodeCF_p3");

      eucData.orangeColoringThreshold = AppStorage.getSetting(
        "orangeColoringThreshold_p3"
      );
      eucData.redColoringThreshold = AppStorage.getSetting(
        "redColoringThreshold_p3"
      );

      eucData.currentCorrection = AppStorage.getSetting("currentCorrection_p3");
      eucData.maxDisplayedTemperature =
        AppStorage.getSetting("maxTemperature_p3");

      eucData.rotationSpeed = AppStorage.getSetting("rotationSpeed_PWM_p3");
      eucData.rotationVoltage = AppStorage.getSetting("rotationVoltage_PWM_p3");
      eucData.powerFactor = AppStorage.getSetting("powerFactor_PWM_p3");
      eucData.voltage_scaling = AppStorage.getSetting(
        "voltageCorrectionFactor_p3"
      );
      eucData.sagThreshold = AppStorage.getSetting(
        "voltageSagIndicatorThresh_p3"
      );
      eucData.speedCorrectionFactor = AppStorage.getSetting(
        "speedCorrectionFactor_p3"
      );

      eucData.alarmThreshold_PWM = AppStorage.getSetting(
        "alarmThreshold_PWM_p3"
      );
      eucData.alarmThreshold_speed = AppStorage.getSetting(
        "alarmThreshold_speed_p3"
      );
      eucData.alarmThreshold_temp = AppStorage.getSetting(
        "alarmThreshold_temp_p3"
      );
      eucData.wheelBrand = AppStorage.getSetting("wheelBrand_p3");

      actionButtonTrigger.recordActivityButton = AppStorage.getSetting(
        "recordActivityButtonMap_p3"
      );
      actionButtonTrigger.cycleLightButton = AppStorage.getSetting(
        "cycleLightButtonMap_p3"
      );
      actionButtonTrigger.beepButton =
        AppStorage.getSetting("beepButtonMap_p3");
      eucData.BLECmdDelay = AppStorage.getSetting("cmdQueueDelay_p3");
      eucData.VESCCanId = AppStorage.getSetting("VESCCanId_p3");
      eucData.wheelName = AppStorage.getSetting("wheelName_p3");
      Storage.setValue("lastProfile", profileName);
      return true;
    } else {
      return false;
    }
  }
}
