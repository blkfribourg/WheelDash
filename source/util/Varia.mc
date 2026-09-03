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
  var targetObject;
  var listener;
  var highFreq = 3135;
  var lowFreq = 1046;
  var successTone = null;

  function initVaria() {
    if (eucData.useRadar == true) {
      // listener = new variaListener();
      //   System.println("init varia");
      eucData.radar = new AntPlus.BikeRadar(null);
      //  System.println("eucData.radar :" + eucData.radar);
    }
    
    // Initialize successTone only if ToneProfile is available
    if (Attention has :ToneProfile) {
      successTone = [
        new Attention.ToneProfile(1760, 200),
        new Attention.ToneProfile(0, 50),
        new Attention.ToneProfile(1760, 150),
        new Attention.ToneProfile(1568, 150),
        new Attention.ToneProfile(2349, 400),
      ];
    }
  }
  function checkVehicule() {
    //  System.println("checkingVehicule");
    if (eucData.useRadar == true && eucData.radar != null) {
      try {
        targetObject = eucData.radar.getRadarInfo();
        Varia.processTarget(targetObject); // surrounding by try because varia may disconnect (unexpected crashes were observed)
      } catch (e instanceof Lang.Exception) {
        //    System.println("varia error:" + e.getErrorMessage());
      }
    }
  }

  function checkStatus() {
    if (eucData.useRadar == true && eucData.radar != null) {
      if (eucData.radar.getDeviceState().state > 2) {
        eucData.radarPaired = true;
      } else {
        eucData.radarPaired = false;
      }
    }
  }

  function processTarget(_target) {
    //to remove :

    targetObject = _target;

    //System.println(_target);

    if (_target != null) {
      // System.println("processing target");
      if (_target.size != 0) {
        //System.println("threat: " + _target[0].threat);
        if (_target[0].threat != 0) {
          if (_target[0].threat == 1) {
            triggerDelay = 1000;
          }
          if (_target[0].threat == 2) {
            triggerDelay = 500;
          }
          eucData.variaTargetDist = _target[0].range;
          eucData.variaTargetSpeed = _target[0].speed * 3.6; // conversion in km/h

          // System.println(eucData.variaTargetDist);
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
    var variaNow = System.getTimer();

    if (nextVariaTrigger != null && nextVariaTrigger - variaNow >= 0) {
      triggerVariaAlarm = false;
    }
    //System.println("tva: " + triggerVariaAlarm);
    if (
      eucData.variaFarAlarmDistThr != 0 &&
      distance < eucData.variaFarAlarmDistThr &&
      distance > eucData.variaCloseAlarmDistThr
    ) {
      // far car
      if (Attention has :playTone && triggerVariaAlarm == true) {
        //System.println("triggerFar");
        // EUCAlarms.playSound({ :toneProfile => toneProfile });
        if (eucData.motorbikeHeadset == true) {
          EUCAlarms.playSound(Attention.TONE_DISTANCE_ALERT);
        } else if (Attention has :ToneProfile) {
          EUCAlarms.playSound([
            new Attention.ToneProfile(
              roundFreq(
                highFreq -
                  ((highFreq - lowFreq) / eucData.variaFarAlarmDistThr) *
                    distance
              ),
              250
            ),
          ]);
        }
      }

      nextVariaTrigger = System.getTimer() + triggerDelay;

      return;
    }

    if (
      eucData.variaCloseAlarmDistThr != 0 &&
      distance <= eucData.variaCloseAlarmDistThr
    ) {
      // close car
      if (Attention has :playTone && triggerVariaAlarm == true) {
        // System.println("triggerclose");
        // EUCAlarms.playSound({ :toneProfile => toneProfile });
        if (eucData.motorbikeHeadset == true) {
          EUCAlarms.playSound(Attention.TONE_ALARM);
        } else if (Attention has :ToneProfile) {
          EUCAlarms.playSound([
            new Attention.ToneProfile(
              roundFreq(
                highFreq -
                  ((highFreq - lowFreq) / eucData.variaFarAlarmDistThr) *
                    distance
              ),
              250
            ),
          ]);
        }
      }
      nextVariaTrigger = System.getTimer() + triggerDelay;

      return;
    }
  }

  function soundClear() {
    if (Attention has :playTone) {
      if (
        eucData.variaFarAlarmDistThr != 0 ||
        eucData.variaCloseAlarmDistThr != 0
      ) {
        if (eucData.motorbikeHeadset == true) {
          EUCAlarms.playSound(Attention.TONE_SUCCESS);
        } else if (Attention has :ToneProfile && successTone != null) {
          EUCAlarms.playSound(successTone);
        }
      }
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
class variaListener extends AntPlus.BikeRadarListener {
  function initialize() {}

  function onBikeRadarUpdate(data as Lang.Array<AntPlus.RadarTarget>) as Void {
    Varia.processTarget(data);
  }
}
