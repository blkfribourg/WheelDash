using Toybox.System;

module eucData {
  var currentProfile;
  var wheelBrand;
  var wheelName;
  var paired = false;
  var limitedMemory = false;
  // Calculated PWM variables :
  // PLEASE UPDATE WITH YOU OWN VALUES BEFORE USE !
  var rotationSpeed; // cutoff speed when freespin test performed
  var powerFactor; // 0.9 for better safety
  var rotationVoltage; // voltage when freespin test performed
  var updateDelay = 200; // UI refresh every updateDelay
  var BLECmdDelay = 200;
  var topBar; // String : Speed or PWM
  var mainNumber; // String : Speed or PWM
  var maxDisplayedSpeed; // number, used if topBar equals Speed : read from settings
  var vibeIntensity = 90;
  var alarmThreshold_PWM;
  var alarmThreshold2_PWM;
  var alarmThreshold_speed;
  var alarmThreshold_temp;
  var activityAutorecording;
  var activityAutosave;
  var activityRecording = false;
  var debug;
  var BLEReadRate = 0;
  var timeWhenConnected;
  //UI
  var sagThreshold = 0.3;
  var orangeColoringThreshold;
  var redColoringThreshold;
  //speedLimiterIcon
  var speedLimitOn = false;
  var speedLimit = 25;
  var tiltBackSpeed = 0;
  var WDtiltBackSpd = 0;
  var speedCorrectionFactor = 1; // correct distance aswell ...
  var useMiles = false;
  var useFahrenheit = false;
  var convertToMiles = false;
  var convertToFahrenheit = false;
  var deviceName = null;
  var voltage_scaling = 1;
  var speed = 0.0;
  var correctedSpeed = 0.0;
  var voltage = null;
  var lowestBatteryPercentage = 101;
  var tripDistance = 0.0;
  var correctedTripDistance = 0.0;
  var Phcurrent = 0.0;
  var current = 0.0;
  var temperature = 0.0;

  var DisplayedTemperature = 0.0;
  var maxDisplayedTemperature = 65;
  var totalDistance = 0.0;
  var correctedTotalDistance = 0.0;
  var PWM = 0.0;
  var pedalMode = "0";
  var speedAlertMode = "0";
  var rollAngleMode = "0";
  var speedUnitMode = 0;
  var ledMode = "0";
  var avgMovingSpeed;
  var topSpeed = 0;
  var watchBatteryUsage = 0.0;
  var hPWM = 0.0;
  var currentCorrection;
  var gothPWM = false;
  var battery = 0.0;
  // Veteran specific
  var version = 0;

  // Kingsong specific
  var KSName = "";
  var KSSerial;
  var KS18L_scale_toggle = false;
  var mode = 0;
  var fanStatus;
  var chargingStatus;
  var temperature2 = 0;
  var cpuLoad = 0;
  var KSVoiceMode = false;
  // var output;

  var KSAlarm3Speed;
  var KSAlarm2Speed;
  var KSAlarm1Speed;

  // Kingsong & inmotion :
  var model = "none";

  //inmotion specific
  var imHornSound = 0x18;
  var batteryTemp1 = 0.0;
  var batteryTemp2 = 0.0;

  // Addition for datafield-like view :
  var slideToDFView = false;
  var dfViewOnly = false;
  var displayNorth = false;
  var displayWind = false;
  var dfViewBtn;
  var GPS_requested = false;
  var maxTemperature;
  var minVoltage;
  var maxVoltage;
  var maxCurrent;
  var avgCurrent;
  var minBatteryPerc;
  var maxBatteryPerc;
  var avgPower;
  var maxPower;
  var maxPWM;
  var batteryUsagePerc;
  var batteryUsage;
  var alternativeFont = false;
  var txtColor = 0xffffff;
  var txtColor_unpr = 0xff8000;
  var linesColor = 0xffffff;
  var drawLines = true;

  //ESP32 based BLE horn:
  var ESP32Horn = false;
  var ESP32HornPaired = false;

  // Motorbike headset
  var motorbikeHeadset = false;

  //varia
  var radar = null;
  var totalVehCount = 0;
  var variaTargetNb = 0;
  var variaTargetDist = 0;
  var variaTargetSpeed = 0;
  var timerState = -1;
  var variaCloseAlarmDistThr = 15;
  var variaFarAlarmDistThr = 50;

  var useRadar = false;

  function getBatteryPercentage() {
    if (voltage != null) {
      // using better battery formula from wheellog

      // GOTWAY ---------------------------------------------------
      if (wheelBrand == 0) {
        if (voltage > 66.8) {
          battery = 100.0;
        } else if (voltage > 54.4) {
          battery = (voltage - 53.8) / 0.13;
        } else if (voltage > 52.9) {
          battery = (voltage - 52.9) / 0.325;
        } else {
          battery = 0.0;
        }
      }
      // ----------------------------------------------------------
      // VETERAN ------------------------------------------------
      if (wheelBrand == 1) {
        if (version < 4) {
          // models before Patton
          if (voltage > 100.2) {
            battery = 100.0;
          } else if (voltage > 81.6) {
            battery = (voltage - 80.7) / 0.195;
          } else if (voltage > 79.35) {
            battery = (voltage - 79.35) / 0.4875;
          } else {
            battery = 0.0;
          }
        }
        if (version > 4 && version < 5) {
          // Patton
          if (voltage > 125.25) {
            battery = 100.0;
          } else if (voltage > 102.0) {
            battery = (voltage - 99.75) / 0.255;
          } else if (voltage > 96.0) {
            battery = (voltage - 96.0) / 0.675;
          } else {
            battery = 0.0;
          }
        }
        if (version > 5 && version < 6) {
          // Lynx
          if (voltage > 150.3) {
            battery = 100.0;
          } else if (voltage > 122.4) {
            battery = (voltage - 119.7) / 0.306;
          } else if (voltage > 115.2) {
            battery = (voltage - 115.2) / 0.81;
          } else {
            battery = 0.0;
          }
        }
      }

      //-----------------------------------------------------------
      //Kingsong --------------------------------------------------

      if (wheelBrand == 2 || wheelBrand == 3) {
        var KSwheels84v = [
          "KS-18L",
          "KS-16X",
          "KS-16XF",
          "RW",
          "KS-18LH",
          "KS-18LY",
          "KS-S18",
          "KS-S16",
          "KS-S16P",
        ];
        var KSwheels100v = ["KS-S19"];
        var KSwheels126v = ["KS-S20", "KS-S22"];

        if (KSwheels84v.indexOf(model) != -1) {
          if (voltage > 83.5) {
            battery = 100.0;
          } else if (voltage > 68.0) {
            battery = (voltage - 66.5) / 0.17;
          } else if (voltage > 64.0) {
            battery = (voltage - 64.0) / 0.45;
          } else {
            battery = 0.0;
          }
        } else if (KSwheels100v.indexOf(model) != -1) {
          if (voltage > 100.2) {
            battery = 100.0;
          } else if (voltage > 81.6) {
            battery = (voltage - 79.8) / 0.204;
          } else if (voltage > 76.8) {
            battery = (voltage - 76.8) / 0.54;
          } else {
            battery = 0.0;
          }
        } else if (KSwheels126v.indexOf(model) != -1) {
          if (voltage > 125.25) {
            battery = 100.0;
          } else if (voltage > 102.0) {
            battery = (voltage - 99.75) / 0.255;
          } else if (voltage > 96.0) {
            battery = (voltage - 96.0) / 0.675;
          } else {
            battery = 0.0;
          }
        } else {
          if (voltage > 66.8) {
            battery = 100.0;
          } else if (voltage > 54.4) {
            battery = (voltage - 53.2) / 0.136;
          } else if (voltage > 51.2) {
            battery = (voltage - 51.2) / 0.36;
          } else {
            battery = 0.0;
          }
        }
      }

      // ----------------------------------------------------------
      // INMOTION V11 :
      if (wheelBrand == 4) {
        if (model.equals("V11")) {
          if (voltage > 83.5) {
            battery = 100.0;
          } else if (voltage > 68.0) {
            battery = (voltage - 66.5) / 0.17;
          } else if (voltage > 64.0) {
            battery = (voltage - 64.0) / 0.45;
          } else {
            battery = 0.0;
          }
        }
        if (model.equals("V12")) {
          if (voltage > 100.2) {
            battery = 100.0;
          } else if (voltage > 81.6) {
            battery = (voltage - 79.8) / 0.204;
          } else if (voltage > 76.8) {
            battery = (voltage - 76.8) / 0.54;
          } else {
            battery = 0.0;
          }
        }
      }
      if (wheelBrand == 5) {
        if (model.equals("V11")) {
          if (voltage > 83.5) {
            battery = 100.0;
          } else if (voltage > 68.0) {
            battery = (voltage - 66.5) / 0.17;
          } else if (voltage > 64.0) {
            battery = (voltage - 64.0) / 0.45;
          } else {
            battery = 0.0;
          }
        }
        if (model.equals("V13")) {
          if (voltage > 100.2) {
            battery = 100.0;
          } else if (voltage > 81.6) {
            battery = (voltage - 79.8) / 0.204;
          } else if (voltage > 76.8) {
            battery = (voltage - 76.8) / 0.54;
          } else {
            battery = 0.0;
          }
        }
        if (model.equals("V14")) {
          if (voltage > 133.6) {
            battery = 100.0;
          } else if (voltage > 108.8) {
            battery = (voltage - 106.4) / 0.272;
          } else if (voltage > 102.4) {
            battery = (voltage - 102.4) / 0.72;
          } else {
            battery = 0.0;
          }
        }
      }
      return battery;
    } else {
      return 0;
    }
  }

  function getPWM() {
    if (eucData.voltage != null && eucData.voltage > 0) {
      //Quick&dirty fix for now, need to rewrite this:
      if ((wheelBrand == 0 && gothPWM == false) || wheelBrand == 5) {
        //  System.println("calcPwm");
        var CalculatedPWM =
          eucData.speed.toFloat() /
          ((rotationSpeed / rotationVoltage) *
            eucData.voltage.toFloat() *
            eucData.voltage_scaling *
            powerFactor);
        return CalculatedPWM * 100;
      }

      // 0 is begode/gotway, all other brands returns hPWM (Leaperkim / KS / OLD KS / IM / VESC)
      else {
        //   System.println("hwPwm");
        return hPWM;
      }
    } else {
      return 0;
    }
  }
  function getCurrent() {
    var currentCurrent = 0;
    if (wheelBrand == 0 || wheelBrand == 1) {
      if (currentCorrection == 0) {
        currentCurrent = (getPWM() / 100) * eucData.Phcurrent;
      }
      if (currentCorrection == 1) {
        currentCurrent = (getPWM() / 100) * -eucData.Phcurrent;
      }
      if (currentCorrection == 2) {
        currentCurrent = (getPWM() / 100) * eucData.Phcurrent.abs();
      }
    } else {
      currentCurrent = current;
    }

    return currentCurrent;
  }
  function getCorrectedSpeed() {
    if (convertToMiles == true) {
      return speed * speedCorrectionFactor.toFloat() * 0.621371192;
    } else {
      return speed * speedCorrectionFactor.toFloat();
    }
  }
  function getCorrectedTripDistance() {
    if (convertToMiles == true) {
      return tripDistance * speedCorrectionFactor.toFloat() * 0.621371192;
    } else {
      return tripDistance * speedCorrectionFactor.toFloat();
    }
  }
  function getCorrectedTotalDistance() {
    if (convertToMiles == true) {
      return totalDistance * speedCorrectionFactor.toFloat() * 0.621371192;
    } else {
      return totalDistance * speedCorrectionFactor.toFloat();
    }
  }
  function getTemperature() {
    if (convertToFahrenheit == true) {
      return temperature * 1.8 + 32.0;
    } else {
      return temperature;
    }
  }

  function getVoltage() {
    if (wheelBrand == 0 && voltage != null) {
      // gotway
      return voltage * voltage_scaling;
    } else {
      return voltage;
    }
  }
}
