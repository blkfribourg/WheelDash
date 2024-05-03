import Toybox.Attention;
import Toybox.Lang;
using Toybox.System;

module EUCAlarms {
  var alarmDelay = 0;
  var alarmType = "none";
  var PWMAlarm = false;
  var speedAlarm = false;
  var tempAlarm = false;
  var PWMVibe, PWMDangerVibe, speedVibe, tempVibe;
  var PWMTone, PWMDangerTone, speedTone, tempTone;
  /*
  function AlarmVibe(intensity, duration, steps, type) {
    var minIntensity = 20;
    var vibeData = [new Attention.VibeProfile(0, 0)];
    if (type.equals("speed")) {
      for (var i = 1; i <= steps; i++) {
        vibeData.add(
          new Attention.VibeProfile(
            minIntensity + ((intensity - minIntensity) * i) / steps,
            duration / steps
          )
        );
      }
    }
    if (type.equals("temp")) {
      for (var i = steps; i >= 1; i--) {
        vibeData.add(
          new Attention.VibeProfile(
            minIntensity + ((intensity - minIntensity) * i) / steps,
            duration / steps
          )
        );
      }
    }
    if (type.equals("PWM")) {
      for (var i = 1; i <= steps; i++) {
        vibeData.add(
          new Attention.VibeProfile(intensity, (duration / 2) * steps)
        );
        vibeData.add(new Attention.VibeProfile(0, (duration / 2) * steps));
      }
    }
    return vibeData;
  }
  */
  function alarmsInit() {
    initVibes(eucData.vibeIntensity);
    initTones();
  }
  function initVibes(intensity) {
    if (Attention has :vibrate) {
      PWMVibe = [
        new Attention.VibeProfile(intensity, 250),
        new Attention.VibeProfile(0, 250),
        new Attention.VibeProfile(intensity, 250),
        new Attention.VibeProfile(0, 250),
      ];
      PWMDangerVibe = [
        new Attention.VibeProfile(intensity, 100),
        new Attention.VibeProfile(0, 100),
        new Attention.VibeProfile(intensity, 100),
        new Attention.VibeProfile(0, 100),
      ];
      speedVibe = [
        new Attention.VibeProfile(intensity, 400),
        new Attention.VibeProfile(0, 200),
        new Attention.VibeProfile(intensity, 100),
        new Attention.VibeProfile(0, 100),
        new Attention.VibeProfile(intensity, 100),
        new Attention.VibeProfile(0, 100),
      ];
      tempVibe = [
        new Attention.VibeProfile(intensity, 500),
        new Attention.VibeProfile(0, 200),
        new Attention.VibeProfile(intensity, 100),
        new Attention.VibeProfile(0, 200),
      ];
    }
  }

  function initTones() {
    if (Attention has :ToneProfile) {
      PWMTone = [
        new Attention.ToneProfile(435, 250),
        new Attention.ToneProfile(0, 250),
        new Attention.ToneProfile(435, 250),
        new Attention.ToneProfile(0, 250),
      ];
      PWMDangerTone = [
        new Attention.ToneProfile(435, 100),
        new Attention.ToneProfile(0, 100),
        new Attention.ToneProfile(435, 100),
        new Attention.ToneProfile(0, 100),
      ];
      speedTone = [
        new Attention.ToneProfile(420, 400),
        new Attention.ToneProfile(0, 200),
        new Attention.ToneProfile(516, 100),
        new Attention.ToneProfile(0, 100),
        new Attention.ToneProfile(420, 100),
        new Attention.ToneProfile(0, 100),
      ];
      tempTone = [
        new Attention.ToneProfile(435, 500),
        new Attention.ToneProfile(0, 200),
        new Attention.ToneProfile(488, 100),
        new Attention.ToneProfile(0, 200),
      ];
    }
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
  function alarmsCheck() {
    //PWM alarm
    if (eucData.alarmThreshold_PWM != 0) {
      if (
        eucData.PWM > eucData.alarmThreshold_PWM &&
        eucData.PWM < eucData.alarmThreshold2_PWM &&
        alarmDelay <= 0
      ) {
        if (PWMVibe != null && eucData.vibeIntensity != 0) {
          Attention.vibrate(PWMVibe);
        }
        if (PWMTone != null) {
          Attention.playTone({ :toneProfile => PWMTone });
        }

        //EUCAlarms.alarmHandler(100, 300);
        alarmDelay = 1000 / eucData.updateDelay;
        PWMAlarm = true;
      }
      if (eucData.PWM > eucData.alarmThreshold2_PWM && alarmDelay <= 0) {
        if (PWMDangerVibe != null && eucData.vibeIntensity != 0) {
          Attention.vibrate(PWMDangerVibe);
        }
        if (PWMDangerTone != null) {
          Attention.playTone({ :toneProfile => PWMDangerTone });
        }
        alarmDelay = 400 / eucData.updateDelay;

        PWMAlarm = true;
      }
      if (eucData.PWM < eucData.alarmThreshold_PWM) {
        alarmDelay = 0;

        PWMAlarm = false;
      }
      alarmDelay--;

      setAlarmType();
    }

    //Temperature alarm
    if (eucData.alarmThreshold_temp != 0) {
      if (
        eucData.DisplayedTemperature > eucData.alarmThreshold_temp &&
        alarmDelay <= 0 &&
        PWMAlarm == false
      ) {
        // PWM alarm have priority over temperature alarm
        if (tempVibe != null && eucData.vibeIntensity != 0) {
          Attention.vibrate(tempVibe);
        }
        if (tempTone != null) {
          Attention.playTone({ :toneProfile => tempTone });
        }

        alarmDelay = 1000 / eucData.updateDelay;
        tempAlarm = true;
      }
      if (eucData.DisplayedTemperature < eucData.alarmThreshold_temp) {
        alarmDelay = 0;
        tempAlarm = false;
      } else {
        alarmDelay--;
      }
      setAlarmType();
    }

    //Speed alarm
    if (eucData.alarmThreshold_speed != 0) {
      if (
        eucData.correctedSpeed > eucData.alarmThreshold_speed &&
        alarmDelay <= 0 &&
        PWMAlarm == false &&
        tempAlarm == false
      ) {
        // PWM alarm and temperature alarm have priority over speed alarm
        if (speedVibe != null && eucData.vibeIntensity != 0) {
          Attention.vibrate(speedVibe);
        }
        if (speedTone != null) {
          System.println("speedTone!");
          Attention.playTone({ :toneProfile => speedTone });
        }
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
