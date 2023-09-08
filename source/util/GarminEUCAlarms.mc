import Toybox.Attention;
import Toybox.Lang;
using Toybox.System;

module EUCAlarms {
  var alarmDelay = 0;
  var alarmType = "none";
  var PWMAlarm = false;
  var speedAlarm = false;
  var tempAlarm = false;
  function alarmHandler(intensity, duration) {
    Attention.vibrate([new Attention.VibeProfile(intensity, duration)]);
  }
  function setAlarmType() {
    if (PWMAlarm == true) {
      alarmType = "PWM";
    } else {
      if (tempAlarm == true) {
        alarmType = "Temp.";
      } else {
        if (speedAlarm == true) {
          alarmType = "Speed";
        }
      }
    }

    if (PWMAlarm == false && tempAlarm == false && speedAlarm == false) {
      alarmType = "none";
    }
  }
  function speedAlarmCheck() {
    //PWN alarm
    if (Attention has :vibrate && eucData.alarmThreshold_PWM != 0) {
      if (
        eucData.PWM > eucData.alarmThreshold_PWM &&
        eucData.PWM < eucData.alarmThreshold_PWM + 5 &&
        alarmDelay <= 0
      ) {
        EUCAlarms.alarmHandler(100, 300);
        alarmDelay = 1000 / eucData.updateDelay;
        PWMAlarm = true;
      }
      if (eucData.PWM > eucData.alarmThreshold_PWM + 5 && alarmDelay <= 0) {
        EUCAlarms.alarmHandler(100, 100);
        alarmDelay = 200 / eucData.updateDelay;

        PWMAlarm = true;
      }
      if (eucData.PWM < eucData.alarmThreshold_PWM) {
        alarmDelay = 0;

        PWMAlarm = false;
      } else {
        alarmDelay--;
      }
      setAlarmType();
    }

    //Temperature alarm
    if (Attention has :vibrate && eucData.alarmThreshold_temp != 0) {
      if (
        eucData.temperature > eucData.alarmThreshold_temp &&
        alarmDelay <= 0 &&
        PWMAlarm == false
      ) {
        // PWM alarm have priority over temperature alarm
        EUCAlarms.alarmHandler(100, 300);
        alarmDelay = 1000 / eucData.updateDelay;
        tempAlarm = true;
      }
      if (eucData.temperature < eucData.alarmThreshold_temp) {
        alarmDelay = 0;
        tempAlarm = false;
      } else {
        alarmDelay--;
      }
      setAlarmType();
    }

    //Speed alarm
    if (Attention has :vibrate && eucData.alarmThreshold_speed != 0) {
      if (
        eucData.correctedSpeed > eucData.alarmThreshold_speed &&
        alarmDelay <= 0 &&
        PWMAlarm == false &&
        tempAlarm == false
      ) {
        // PWM alarm and temperature alarm have priority over speed alarm
        EUCAlarms.alarmHandler(100, 300);
        alarmDelay = 1000 / eucData.updateDelay;
        speedAlarm = true;
      }
      if (eucData.correctedSpeed < eucData.alarmThreshold_speed) {
        alarmDelay = 0;
        speedAlarm = false;
      } else {
        alarmDelay--;
      }
      setAlarmType();
    }
  }
}
