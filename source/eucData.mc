using Toybox.System;

module eucData {
  var wheelBrand;
  var paired = false;
  // Calculated PWM variables :
  // PLEASE UPDATE WITH YOU OWN VALUES BEFORE USE !
  var rotationSpeed; // cutoff speed when freespin test performed
  var powerFactor; // 0.9 for better safety
  var rotationVoltage; // voltage when freespin test performed
  var updateDelay; // UI refresh every updateDelay
  var topBar; // String : Speed or PWM
  var mainNumber; // String : Speed or PWM
  var maxDisplayedSpeed; // number, used if topBar equals Speed : read from settings
  var alarmThreshold_PWM;
  var alarmThreshold_speed;
  var alarmThreshold_temp;

  var speedCorrectionFactor; // correct distance aswell ...
  var useMiles = 0;
  var deviceName = null;
  var voltage_scaling;
  var speed = 0.0;
  var correctedSpeed = 0.0;
  var voltage = 0.0;
  var lowestBatteryPercentage = 101;
  var tripDistance = 0.0;
  var Phcurrent = 0.0;
  var current = 0.0;
  var temperature = 0;
  var maxTemperature = 65;
  var totalDistance = 0.0;
  var PWM = 0;
  var pedalMode = "0";
  var speedAlertMode = "0";
  var rollAngleMode = "0";
  var speedUnitMode = 0;
  var ledMode = "0";
  var avgMovingSpeed = 0.0;
  var topSpeed = 0.0;
  var watchBatteryUsage = 0.0;
  var hPWM = 0.0;
  var currentCorrection;
  var gothPWN = false;

  // Veteran specific
  var version = 0;

  // Kingsong specific
  var KSName = "";
  var KSSerial;
  var KS18L_scale_toggle = false;
  var mode = 0;
  var model = "none";
  var fanStatus;
  var chargingStatus;
  var temperature2 = 0;
  var cpuLoad = 0;
  // var output;
  var speedLimit = 0;
  var KSMaxSpeed;
  var KSAlarm3Speed;
  var KSAlarm2Speed;
  var KSAlarm1Speed;

  function getBatteryPercentage() {
    // using better battery formula from wheellog
    var battery = 0;
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
        // not Patton
        if (voltage > 100.2) {
          battery = 100.0;
        } else if (voltage > 81.6) {
          battery = (voltage - 80.7) / 0.195;
        } else if (voltage > 79.35) {
          battery = (voltage - 79.35) / 0.4875;
        } else {
          battery = 0.0;
        }
      } else {
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
    }
    //-----------------------------------------------------------
    //Kingsong --------------------------------------------------

    if (wheelBrand == 2) {
      var KSwheels84v = [
        "KS-18L",
        "KS-16X",
        "KS-16XF",
        "RW",
        "KS-18LH",
        "KS-18LY",
        "KS-S18",
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
        // unknown model
        battery = 0.0;
      }
    }

    // ----------------------------------------------------------
    return battery;
  }

  function getPWM() {
    if (eucData.voltage != 0) {
      //Quick&dirty fix for now, need to rewrite this:
      if (wheelBrand == 1 || wheelBrand == 2 || gothPWN == true) {
        return hPWM;
      } else {
        var CalculatedPWM =
          eucData.speed.toFloat() /
          ((rotationSpeed / rotationVoltage) *
            eucData.voltage.toFloat() *
            eucData.voltage_scaling *
            powerFactor);
        return CalculatedPWM * 100;
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
    return speed * speedCorrectionFactor.toFloat();
  }

  function getVoltage() {
    if (wheelBrand == 0) {
      // gotway
      return voltage * voltage_scaling;
    } else {
      return voltage;
    }
  }
}
