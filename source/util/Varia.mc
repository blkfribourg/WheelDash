using Toybox.Attention;
using Toybox.System;
using Toybox.Lang;
import Toybox.Time;
import Toybox.AntPlus;
module Varia {
  var prevCount = 0;
  var triggerVariaAlarm = false;
  var nextVariaTrigger;
  var triggerDelay;

  function initVaria() {
    if (eucData.useRadar == true) {
      eucData.radar = new AntPlus.BikeRadar(null);
    }
  }
  function checkVehicule() {
    if (eucData.useRadar == true && eucData.radar != null) {
      try {
        Varia.processTarget(eucData.radar.getRadarInfo()); // surrounding by try because varia may disconnect (unexpected crashes were observed)
      } catch (e instanceof Lang.Exception) {
        // System.println(e.getErrorMessage());
      }
    }
  }

  function processTarget(_target) {
    if (_target != null) {
      if (_target.size != 0) {
        if (_target[0].threat != 0) {
          if (_target[0].threat == 1) {
            triggerDelay = new Time.Duration(1);
          }
          if (_target[0].threat == 2) {
            triggerDelay = (new Time.Duration(1)).divide(2);
          }
          eucData.variaTargetDist = _target[0].range;
          eucData.variaTargetSpeed = _target[0].speed;
          soundAlert(_target[0].range);
        }

        var veh_count = 0;
        for (var i = 0; i < _target.size(); i++) {
          if (_target[i].threat != 0) {
            veh_count = veh_count + 1;
          }
        }

        eucData.variaTargetNb = veh_count;
        if (prevCount > veh_count && veh_count == 0) {
          //no more cars
          //System.println("no cars");
          soundClear();
          eucData.variaTargetDist = 0;
          eucData.variaTargetSpeed = 0;
        }
        if (prevCount > veh_count) {
          eucData.totalVehCount =
            eucData.totalVehCount + (prevCount - veh_count);
        }
        prevCount = veh_count;
      }
    }
  }

  function soundAlert(distance) {
    triggerVariaAlarm = true;
    var variaNow = new Time.Moment(Time.now().value());

    if (nextVariaTrigger != null && nextVariaTrigger.compare(variaNow) >= 0) {
      triggerVariaAlarm = false;
    }
    if (
      eucData.variaFarAlarmDistThr != 0 &&
      distance < eucData.variaFarAlarmDistThr &&
      distance > eucData.variaCloseAlarmDistThr
    ) {
      // far car
      if (Attention has :playTone && triggerVariaAlarm == true) {
        //   System.println("triggerFar");
        Attention.playTone(Attention.TONE_DISTANCE_ALERT);
        nextVariaTrigger = new Time.Moment(Time.now().value());
        nextVariaTrigger.add(triggerDelay);
      }
    }
    if (
      eucData.variaCloseAlarmDistThr != 0 &&
      distance <= eucData.variaCloseAlarmDistThr
    ) {
      // close car
      if (Attention has :playTone && triggerVariaAlarm == true) {
        //  System.println("triggerclose");
        Attention.playTone(Attention.TONE_ALARM);
        nextVariaTrigger = new Time.Moment(Time.now().value());
        nextVariaTrigger.add(triggerDelay);
      }
    }
  }

  function soundClear() {
    if (Attention has :playTone) {
      Attention.playTone(Attention.TONE_SUCCESS);
    }
  }
  function getVariaVoltage() {
    var batteryStats = null;
    var variaVoltage = null;
    if (eucData.useRadar == true && eucData.radar != null) {
      try {
        batteryStats = eucData.radar.getBatteryStatus(null);
        if (batteryStats != null) {
          variaVoltage = batteryStats.batteryVoltage;
        }
      } catch (e instanceof Lang.Exception) {
        // System.println(e.getErrorMessage());
      }
    }
    return variaVoltage;
  }
}
//far car : TONE_DISTANCE_ALERT
//close car : TONE_ALARM
//no more cars: TONE_SUCCESS
//speed : TONE_CANARY
