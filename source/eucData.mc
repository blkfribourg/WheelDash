using Toybox.System;

module eucData {
  var wheelBrand;
  // Calculated PWM variables :
  // PLEASE UPDATE WITH YOU OWN VALUES BEFORE USE !
  var rotationSpeed; // cutoff speed when freespin test performed
  var powerFactor; // 0.9 for better safety
  var rotationVoltage; // voltage when freespin test performed
  var updateDelay; // UI refresh every updateDelay
  var alarmThreshold_PWN;
  var alarmThreshold_speed;
  var actionButton;
  var speedCorrectionFactor; // correct distance aswell ...
  var calculatedPWM = 0.0;
  var deviceName = null;
  var voltage_scaling;
  var speed = 0.0;
  var correctedSpeed = 0.0;
  var voltage = 0;
  var lowestBatteryPercentage = 101;
  var tripDistance = 0.0;
  var Phcurrent = 0;
  var temperature = 0;
  var maxTemperature = 65;
  var totalDistance = 0;
  var PWM = 0;
  var pedalMode = "0";
  var speedAlertMode = "0";
  var rollAngleMode = "0";
  var speedUnitMode = 0;
  var ledMode = "0";
  var avgMovingSpeed = 0.0;
  var topSpeed = 0.0;
  var watchBatteryUsage = 0.0;
  var hPWM;

  // Veteran specific
  var version;

  function getBatteryPercentage() {
    // using better battery formula from wheellog
    var battery = 0;
    // GOTWAY ---------------------------------------------------
    if (wheelBrand.equals("Gotway")) {
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
    // LEAPERKIM ------------------------------------------------
    if (wheelBrand.equals("Leaperkim")) {
      if (version < 4) {
        // not Patton
        if (voltage > 10020) {
          battery = 100;
        } else if (voltage > 8160) {
          battery = (voltage - 8070) / 19.5;
        } else if (voltage > 7935) {
          battery = (voltage - 7935) / 48.75;
        } else {
          battery = 0;
        }
      } else {
        if (voltage > 12525) {
          battery = 100;
        } else if (voltage > 10200) {
          battery = (voltage - 9975) / 25.5;
        } else if (voltage > 9600) {
          battery = (voltage - 9600) / 67.5;
        } else {
          battery = 0;
        }
      }
    }
    // ----------------------------------------------------------
    return battery;
  }
  function setSettings(
    _updateDelay,
    _rotationSpeed,
    _rotationVoltage,
    _powerFactor,
    _voltageFactor,
    _speedCorrectionFactor,
    _actionButton,
    _alarmThreshold_PWN,
    _alarmThreshold_speed
  ) {
    updateDelay = _updateDelay;
    rotationSpeed = _rotationSpeed;
    rotationVoltage = _rotationVoltage;
    powerFactor = _powerFactor;
    voltage_scaling = _voltageFactor;
    speedCorrectionFactor = _speedCorrectionFactor;
    actionButton = _actionButton;
    alarmThreshold_PWN = _alarmThreshold_PWN;
    alarmThreshold_speed = _alarmThreshold_speed;
  }
  function getCalculatedtPWM() {
    if (eucData.voltage != 0) {
      var CalculatedPWM =
        eucData.speed.toFloat() /
        ((rotationSpeed / rotationVoltage) *
          eucData.voltage.toFloat() *
          eucData.voltage_scaling *
          powerFactor);
      return CalculatedPWM * 100;
    } else {
      return 0;
    }
  }
  function getCorrectedSpeed() {
    return speed * speedCorrectionFactor.toFloat();
  }
}
