using Toybox.System;
using Toybox.Application;
import Toybox.Lang;

module AppStorage {
  var runtimeDb = {};
  var defaultGlobals = {
    "settingsUrl" => "disabled",
    "updateDelay" => 200,
    "defaultProfile" => 1,
    "useProfileSelector" => true,
    "fieldNB" => 6,
    "field1" => 0,
    "field2" => 1,
    "field3" => 2,
    "field4" => 3,
    "field5" => 4,
    "field6" => 5,
    "field7" => 6,
    "field8" => 7,
    "vibeIntensity" => 90,
    "variaFarAlarmDistThr" => 60,
    "variaCloseAlarmDistThr" => 20,
    "engoTouch" => 0,
    "engoVaria" => 0,
    "imHornSound" => 0,
  };

  function setSetting(key as String, value) as Void {
    try {
      Application.getApp().setProperty(key, value);
    } catch (e instanceof Lang.Exception) {
      System.println("Unable to save setting: " + key);
    }
  }

  function getSetting(key as String) {
    try {
      var value = Application.getApp().getProperty(key);
      return value != null ? value : getDefaultSetting(key);
    } catch (e instanceof Lang.Exception) {
      System.println("Unable to read setting: " + key);
      return getDefaultSetting(key);
    }
  }

  // Garmin settings can temporarily be null after install/update. Keep these
  // defaults aligned with resources/settings/properties.xml.
  function getDefaultSetting(key as String) {
    if (defaultGlobals.hasKey(key)) {
      return defaultGlobals.get(key);
    }

    var profileMarker = key.find("_p");
    if (profileMarker != null) {
      var setting = key.substring(0, profileMarker);
      var profile = key.substring(profileMarker + 2, key.length());

      if (setting.equals("wheelName")) {
        return "Profile " + profile;
      }
      if (setting.equals("cmdQueueDelay")) {
        return 200;
      }
      if (setting.equals("orangeColoringThreshold")) {
        return 80;
      }
      if (setting.equals("redColoringThreshold")) {
        return 90;
      }
      if (setting.equals("rotationSpeed_PWM")) {
        return 65.2;
      }
      if (setting.equals("rotationVoltage_PWM")) {
        return 81.5;
      }
      if (setting.equals("powerFactor_PWM")) {
        return 0.9;
      }
      if (setting.equals("voltageCorrectionFactor")) {
        return 1.25;
      }
      if (setting.equals("voltageSagIndicatorThresh")) {
        return 0.3;
      }
      if (setting.equals("speedCorrectionFactor")) {
        return 1.0;
      }
      if (setting.equals("alarmThreshold_PWM")) {
        return 80;
      }
      if (setting.equals("maxTemperature")) {
        return 65.0;
      }
      if (setting.equals("tiltbackSpeed")) {
        return -1;
      }
      if (setting.equals("beepButtonMap") && profile.equals("2")) {
        return 4;
      }

      // Remaining profile numbers and button mappings default to zero.
      if (
        setting.equals("wheelBrand") ||
        setting.equals("recordActivityButtonMap") ||
        setting.equals("cycleLightButtonMap") ||
        setting.equals("beepButtonMap") ||
        setting.equals("DFViewButtonMap") ||
        setting.equals("engoNextButtonMap") ||
        setting.equals("engoLumaButtonMap") ||
        setting.equals("spdLimitButtonMap") ||
        setting.equals("lockButtonMap") ||
        setting.equals("mainNumber") ||
        setting.equals("topBar") ||
        setting.equals("maxSpeed") ||
        setting.equals("alarmThreshold2_PWM") ||
        setting.equals("alarmThreshold_speed") ||
        setting.equals("alarmThreshold_temp") ||
        setting.equals("currentCorrection") ||
        setting.equals("speedLimit")
      ) {
        return 0;
      }

      if (setting.equals("begodeCF") || setting.equals("convertToMiles")) {
        return false;
      }
    }

    // All remaining global properties declared by this app are booleans whose
    // XML default is false.
    return false;
  }
}
