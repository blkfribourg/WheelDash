import Toybox.Attention;
import Toybox.Lang;
import Toybox.Time;
using Toybox.System;

module EUCAlarms {
  var alarmDelay = 0;
  var alarmType = "none";
  var PWMAlarm = false;
  var speedAlarm = false;
  var tempAlarm = false;
  var nextTrigger as Moment?;
  var triggerAlarm = false;
  var PWMVibe, PWMDangerVibe, speedVibe, tempVibe, killVibe;
  var PWMTone, PWMDangerTone, speedTone, tempTone, killTone;
  var PWM1_thr, PWM2_thr;
  var vibeKilled,
    toneKilled = true;
  function alarmsInit() {
    initVibes(eucData.vibeIntensity);
    initTones();
    if (eucData.alarmThreshold_PWM != 0 && eucData.alarmThreshold2_PWM != 0) {
      if (eucData.alarmThreshold_PWM < eucData.alarmThreshold2_PWM) {
        PWM1_thr = eucData.alarmThreshold_PWM;
        PWM2_thr = eucData.alarmThreshold2_PWM;
      } else {
        PWM2_thr = eucData.alarmThreshold_PWM;
        PWM1_thr = eucData.alarmThreshold2_PWM;
      }
    }
    if (eucData.alarmThreshold_PWM != 0 && eucData.alarmThreshold2_PWM == 0) {
      PWM1_thr = eucData.alarmThreshold_PWM;
      PWM2_thr = 0;
    }
    if (eucData.alarmThreshold_PWM == 0 && eucData.alarmThreshold2_PWM != 0) {
      PWM1_thr = eucData.alarmThreshold2_PWM;
      PWM2_thr = 0;
    }
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
        new Attention.VibeProfile(intensity, 125),
        new Attention.VibeProfile(0, 125),
        new Attention.VibeProfile(intensity, 125),
        new Attention.VibeProfile(0, 125),
        new Attention.VibeProfile(intensity, 125),
        new Attention.VibeProfile(0, 125),
        new Attention.VibeProfile(intensity, 125),
        new Attention.VibeProfile(0, 125),
      ];
      speedVibe = [
        new Attention.VibeProfile(intensity, 350),
        new Attention.VibeProfile(0, 150),
        new Attention.VibeProfile(intensity, 100),
        new Attention.VibeProfile(0, 150),
        new Attention.VibeProfile(intensity, 100),
        new Attention.VibeProfile(0, 150),
      ];
      tempVibe = [
        new Attention.VibeProfile(intensity, 500),
        new Attention.VibeProfile(0, 200),
        new Attention.VibeProfile(intensity, 100),
        new Attention.VibeProfile(0, 200),
      ];
      killVibe = [new Attention.VibeProfile(0, 1)];
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
        new Attention.ToneProfile(535, 125),
        new Attention.ToneProfile(0, 125),
        new Attention.ToneProfile(535, 125),
        new Attention.ToneProfile(0, 125),
        new Attention.ToneProfile(535, 125),
        new Attention.ToneProfile(0, 125),
        new Attention.ToneProfile(535, 125),
        new Attention.ToneProfile(0, 125),
      ];
      speedTone = [
        new Attention.ToneProfile(420, 350),
        new Attention.ToneProfile(0, 150),
        new Attention.ToneProfile(516, 100),
        new Attention.ToneProfile(0, 150),
        new Attention.ToneProfile(420, 100),
        new Attention.ToneProfile(0, 150),
      ];
      tempTone = [
        new Attention.ToneProfile(435, 500),
        new Attention.ToneProfile(0, 200),
        new Attention.ToneProfile(488, 100),
        new Attention.ToneProfile(0, 200),
      ];
      killTone = [new Attention.ToneProfile(10000, 1)];
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
      //interrupt alarms before the end
      if (
        killVibe != null &&
        eucData.vibeIntensity != 0 &&
        vibeKilled == false
      ) {
        Attention.vibrate(killVibe);
        vibeKilled = true;
      }
      if (killTone != null && toneKilled == false) {
        Attention.playTone({ :toneProfile => killTone });
        toneKilled = true;
      }
    }
  }
  function alarmsCheck() {
    //PWM alarm
    triggerAlarm = true;
    var now = new Time.Moment(Time.now().value());

    if (nextTrigger != null && nextTrigger.compare(now) >= 0) {
      triggerAlarm = false;
    }

    if (PWM1_thr != 0 && PWM1_thr != null) {
      if (PWM2_thr != 0 && PWM2_thr != null) {
        if (
          eucData.PWM > PWM1_thr &&
          eucData.PWM < PWM2_thr &&
          triggerAlarm == true
        ) {
          nextTrigger = new Time.Moment(Time.now().value());
          nextTrigger.add(new Time.Duration(1));
          if (PWMVibe != null && eucData.vibeIntensity != 0) {
            Attention.vibrate(PWMVibe);
            vibeKilled = false;
          }
          if (PWMTone != null) {
            Attention.playTone({ :toneProfile => PWMTone });
            toneKilled = false;
          }
          PWMAlarm = true;
        }
        if (eucData.PWM > PWM2_thr && triggerAlarm == true && PWM2_thr != 0) {
          if (PWMDangerVibe != null && eucData.vibeIntensity != 0) {
            Attention.vibrate(PWMDangerVibe);
            vibeKilled = false;
          }
          if (PWMDangerTone != null) {
            Attention.playTone({ :toneProfile => PWMDangerTone });
            toneKilled = false;
          }
          nextTrigger = new Time.Moment(Time.now().value());
          nextTrigger.add(new Time.Duration(1));
          PWMAlarm = true;
        }
      } else {
        if (eucData.PWM > PWM1_thr && triggerAlarm == true) {
          nextTrigger = new Time.Moment(Time.now().value());
          nextTrigger.add(new Time.Duration(1));
          if (PWMVibe != null && eucData.vibeIntensity != 0) {
            Attention.vibrate(PWMVibe);
            vibeKilled = false;
          }
          if (PWMTone != null) {
            Attention.playTone({ :toneProfile => PWMTone });
            toneKilled = false;
          }
          PWMAlarm = true;
        }
      }
      if (eucData.PWM < PWM1_thr) {
        PWMAlarm = false;
      }
    }

    //Temperature alarm
    if (
      eucData.alarmThreshold_temp != 0 &&
      eucData.alarmThreshold_temp != null
    ) {
      if (
        eucData.DisplayedTemperature > eucData.alarmThreshold_temp &&
        triggerAlarm == true &&
        PWMAlarm == false
      ) {
        // PWM alarm have priority over temperature alarm
        nextTrigger = new Time.Moment(Time.now().value());
        nextTrigger.add(new Time.Duration(1));
        if (tempVibe != null && eucData.vibeIntensity != 0) {
          Attention.vibrate(tempVibe);
          vibeKilled = false;
        }
        if (tempTone != null) {
          Attention.playTone({ :toneProfile => tempTone });
          toneKilled = false;
        }
        tempAlarm = true;
      }
      if (eucData.DisplayedTemperature < eucData.alarmThreshold_temp) {
        tempAlarm = false;
      }
    }
    //Speed alarm
    if (
      eucData.alarmThreshold_speed != 0 &&
      eucData.alarmThreshold_speed != null
    ) {
      if (
        eucData.correctedSpeed > eucData.alarmThreshold_speed &&
        triggerAlarm == true &&
        PWMAlarm == false &&
        tempAlarm == false
      ) {
        nextTrigger = new Time.Moment(Time.now().value());
        nextTrigger.add(new Time.Duration(1));
        // PWM alarm and temperature alarm have priority over speed alarm
        if (speedVibe != null && eucData.vibeIntensity != 0) {
          Attention.vibrate(speedVibe);
          vibeKilled = false;
        }
        if (speedTone != null) {
          Attention.playTone({ :toneProfile => speedTone });
          toneKilled = false;
        }
        speedAlarm = true;
      }
      if (eucData.correctedSpeed < eucData.alarmThreshold_speed) {
        speedAlarm = false;
      }
    }
    setAlarmType();
  }
}
