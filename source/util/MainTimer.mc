import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Communications;
using Toybox.Timer;
import Toybox.Position;
class MainTimer {
  private var JSONFetchMessage;
  private var PSTimeout = 10000; // PSTimeout for profile selector
  private var delegate;
  private var bleDelegate;
  private var activityRecordView;
  private var activityRecordingRequired;
  private var activityRecordingDelay = 3000;
  private var engoNextUpdate;
  private var variaNextUpdate;
  private var mainTimer;
  private var configMessage;

  // varia sim
  // var fakeVariaObj;

  function initialize(_delegate) {
    delegate = _delegate;
    mainTimer = new Timer.Timer();
  }
  function startTimer() {
    mainTimer.start(method(:onUpdateTimer), eucData.updateDelay, true);
  }
  function stopTimer() {
    mainTimer.stop();
  }
  function setPsMenuDelegate(_delegate) {
    delegate = delegate;
  }
  function onUpdateTimer() {
    // compatibility with EUC World. Requires multiple webRequests. As timer number are limited, I use this one. It's not the nicest approach but for for now it's the one I choosed :)

    if (eucData.wheelBrand == 6) {
      EUCWorldCompat();
    } //EUC World

    //dummyGen();

    //Only starts if no profile selected
    if (eucData.wheelName == null && delegate != null) {
      //should check settingsChanged status, and reset timeOut value if true
      if (!eucData.useProfileSelector) {
        PSTimeout = 0;
      }
      if (eucData.PSlock == false) {
        PSTimeout = PSTimeout - eucData.updateDelay;
        if (PSTimeout <= 0) {
          System.println("loadingdef");
          delegate.getDefaultSettings();
        }
      }
    }
    if (eucData.useRadar == true) {
      variaUpdate();
    }
    // ensure a profile was loaded
    if (eucData.wheelName != null && bleDelegate != null) {
      if (eucData.useEngo == true) {
        engoScreenUpdate();
      }
    }
    if (eucData.wheelName != null) {
      if (bleDelegate == null && delegate.getBleDelegate() != null) {
        bleDelegate = delegate.getBleDelegate();
      }
      // automatic recording ------------------
      // a bit hacky maybe ...

      if (eucData.activityAutorecording == true && eucData.paired == true) {
        if (delegate != null && activityRecordView == null) {
          // System.println("initialize autorecording");
          activityRecordView = delegate.getActivityView();
          activityRecordingRequired = true;
        }

        if (
          activityRecordView != null &&
          !activityRecordView.isSessionRecording() &&
          activityRecordingRequired == true
        ) {
          //System.println("starting recording");

          //enable sensor first ?
          activityRecordView.enableGPS();
          eucData.GPS_requested = true;
          activityRecordingDelay = activityRecordingDelay - eucData.updateDelay;
          //force initialization
          activityRecordView.initialize();
          if (activityRecordingDelay <= 0) {
            //System.println("record");
            activityRecordingRequired = false;
            activityRecordView.startRecording();
          }

          //System.println("autorecord started");
        }
      }
      if (eucData.mainNumber == 3) {
        //enable GPS
        if (eucData.GPS_requested == false) {
          Position.enableLocationEvents(
            Position.LOCATION_CONTINUOUS,
            method(:onPosition)
          );
          eucData.GPS_requested = true;
        }
        var gpsSpeed = Position.getInfo().speed;
        if (gpsSpeed != null && Position.getInfo().accuracy >= 2) {
          eucData.GPS_speed = gpsSpeed * 3.6;
          if (eucData.useMiles == true || eucData.convertToMiles == true) {
            eucData.GPS_speed = kmToMiles(gpsSpeed);
          }
        }
      }
      /* DISABLED IN DEV -- Speed limiter code ---

      if (eucData.WDtiltBackSpd == -1 && eucData.tiltBackSpeed != null) {
        setWDTiltBackVal(eucData.tiltBackSpeed);
      } else {
        if (
          eucData.correctedSpeed < 3 &&
          eucData.WDtiltBackSpd > 0 &&
          tiltBackInit != true
        ) {
          if (eucData.tiltBackSpeed != null) {
            if (eucData.tiltBackSpeed != eucData.speedLimit) {
              speedLimiter(
                bleDelegate.getQueue(),
                bleDelegate,
                eucData.WDtiltBackSpd
              );
              tiltBackInit = true;
            }
          }
        }
      }

      if (eucData.speedLimit != 0) {
        if (eucData.tiltBackSpeed == eucData.speedLimit) {
          eucData.speedLimitOn = true;
        } else {
          eucData.speedLimitOn = false;
        }
      }
      */
      // -------------------------
      //attributing here to avoid multiple calls
      eucData.correctedSpeed = eucData.getCorrectedSpeed();
      eucData.correctedTotalDistance = eucData.getCorrectedTotalDistance();
      eucData.correctedTripDistance = eucData.getCorrectedTripDistance();
      eucData.DisplayedTemperature = eucData.getTemperature();
      eucData.PWM = eucData.getPWM();
      EUCAlarms.alarmsCheck();

      if (delegate.getMenu2Delegate() != null) {
        if (delegate.getMenu2Delegate().requestSubLabelsUpdate == true) {
          delegate.getMenu2Delegate().updateSublabels();
        }
      }
      if (rideStats.statsArray != null) {
        var statsIndex = 0;
        if (rideStats.showAverageMovingSpeedStatistic) {
          rideStats.avgSpeed();
          rideStats.statsArray[statsIndex] =
            "Avg Spd: " + valueRound(eucData.avgMovingSpeed, "%.1f").toString();
          //System.println(rideStats.statsArray[statsIndex]);
          statsIndex++;
        }
        if (rideStats.showTopSpeedStatistic) {
          rideStats.topSpeed();
          rideStats.statsArray[statsIndex] =
            "Top Spd: " + valueRound(eucData.topSpeed, "%.1f").toString();
          //System.println(rideStats.statsArray[statsIndex]);
          statsIndex++;
        }
        if (rideStats.showWatchBatteryConsumptionStatistic) {
          rideStats.watchBatteryUsage();
          rideStats.statsArray[statsIndex] =
            "Wtch btry/h: " +
            valueRound(eucData.watchBatteryUsage, "%.1f").toString();
          //System.println(rideStats.statsArray[statsIndex]);
          statsIndex++;
        }
        if (rideStats.showTotalDistance) {
          rideStats.statsArray[statsIndex] =
            "Tot dist: " +
            valueRound(eucData.correctedTotalDistance, "%.1f").toString();
          //System.println(rideStats.statsArray[statsIndex]);
          statsIndex++;
        }
        if (rideStats.showTripDistance) {
          rideStats.statsArray[statsIndex] =
            "Trip dist: " +
            valueRound(eucData.correctedTripDistance, "%.1f").toString();
          //System.println(rideStats.statsArray[statsIndex]);
          statsIndex++;
        }
        if (rideStats.showVoltage) {
          rideStats.statsArray[statsIndex] =
            "voltage: " + valueRound(eucData.getVoltage(), "%.2f").toString();
          //System.println(rideStats.statsArray[statsIndex]);
          statsIndex++;
        }
        if (rideStats.showWatchBatteryStatistic) {
          rideStats.statsArray[statsIndex] =
            "Wtch btry: " +
            valueRound(System.getSystemStats().battery, "%d").toString() +
            "%";
          //System.println(rideStats.statsArray[statsIndex]);
          statsIndex++;
        }
        if (rideStats.showProfileName) {
          rideStats.statsArray[statsIndex] = "EUC: " + eucData.wheelName;
          //System.println(rideStats.statsArray[statsIndex]);
          statsIndex++;
        }
      }
      if (
        !eucData.limitedMemory &&
        (eucData.dfViewBtn != 0 ||
          eucData.slideToDFView == true ||
          eucData.dfViewOnly == true)
      ) {
        rideStats.computeDFViewStats();
      }
    }
    WatchUi.requestUpdate();
  }
  function variaUpdate() {
    var now = new Time.Moment(Time.now().value());
    /*
    if (fakeVariaObj == null) {
      if (variaNextUpdate != null && variaNextUpdate.compare(now) <= 0) {
        fakeVariaObj = fakeVaria(3);
      }
    } else {
      fakeVariaObj = variaMove(fakeVariaObj);

      Varia.processTarget(fakeVariaObj);
    }*/
    Varia.checkVehicule();

    if (variaNextUpdate == null || variaNextUpdate.compare(now) <= 0) {
      variaNextUpdate = now.add(new Time.Duration(5));
      // VARIA SIM

      Varia.checkStatus();
    }
  }
  function engoVariaAlert() {
    var vehData = getHexText(engoVariaData(), 3, 1);
    if (vehData != null) {
      bleDelegate.sendCommands(
        concatCmd([
          [0xff, 0x69, 0x00, vehData.size() + 6, 0x28]b,
          vehData,
          [0xaa]b,
        ])
      );
    }
  }
  function engoVariaData() {
    if (eucData.engoVaria == 0) {
      return eucData.variaTargetNb.toString();
    }
    if (eucData.engoVaria == 1) {
      var variaVehSpd = eucData.variaTargetSpeed;
      if (eucData.useMiles == true) {
        variaVehSpd = kmToMiles(eucData.variaTargetSpeed);
      }
      return valueRound(variaVehSpd, "%1d").toString();
    }
    if (eucData.engoVaria == 2) {
      return valueRound(eucData.variaTargetDist, "%1d").toString();
    }
    return null;
  }
  function clearVariaAlert() {
    bleDelegate.sendCommands(getClearRectCmd(12, 85, 61, 157, 0));
  }
  function clearVariaAlertHR() {
    bleDelegate.sendCommands(getClearRectCmd(12, 154, 61, 226, 0)); // tester y0:154 -> y1:226
  }

  function engoScreenUpdate() {
    var now = new Time.Moment(Time.now().value());

    if (eucData.engoPage == 3 || eucData.engoPage == 4) {
      var PWM_rd = Math.round(eucData.PWM.abs()).toNumber();
      var speed_rd = Math.round(eucData.correctedSpeed).toNumber();

      var HRRPArray = new [2]; // High Refresh Rate Page
      if (eucData.variaTargetNb != 0) {
        eucData.engoVariaAlert = true;
        eucData.engoPage = 4;
        HRRPArray = new [3];
        HRRPArray[2] = getHexText(engoVariaData(), 3, 1);
      } else {
        if (eucData.engoVariaAlert == true) {
          clearVariaAlertHR();
          eucData.engoVariaAlert = false;
        }
        eucData.engoPage = 3;
      }
      HRRPArray[0] = getHexText(PWM_rd.toString(), 2, 0);
      HRRPArray[1] = getHexText(speed_rd.toString(), 3, 1);

      var gaugeCmd = [0xff, 0x70, 0x00, 0x07, 0x01, PWM_rd, 0xaa]b;
      var pageCmd = getPageCmd(pagePayload(HRRPArray), eucData.engoPage);
      //gaugeCmd.addAll(pageCmd);
      // pageCmd.addAll(gaugeCmd);
      //bleDelegate.sendCommands(gaugeCmd);
      //System.println("cmd size: " + pageCmd.size());
      bleDelegate.sendCommands(pageCmd);
    } else {
      if (eucData.variaTargetNb != 0) {
        engoVariaAlert();
        eucData.engoVariaAlert = true;
      } else {
        if (eucData.engoVariaAlert == true) {
          clearVariaAlert();
          eucData.engoVariaAlert = false;
        }
      }
      if (engoNextUpdate == null || engoNextUpdate.compare(now) <= 0) {
        engoNextUpdate = now.add(new Time.Duration(1));
        //  eucData.speed = eucData.speed + 0.1;

        if (
          eucData.useEngo == true &&
          eucData.engoPaired == true &&
          bleDelegate.engoDisplayInit == true
        ) {
          eucData.engoBattReq = eucData.engoBattReq + 1;
          if (eucData.engoBattReq > 300) {
            eucData.engoBattReq = 0;
            bleDelegate.getEngoBattery();
          }

          var textArray = new [6];

          // var xpos = 225;
          var currentTime = System.getClockTime();
          if (eucData.engoBattery != null) {
            textArray[0] = getHexText(eucData.engoBattery + " %", 0, 1);
          } else {
            textArray[0] = getHexText(" ", 0, 1);
          }

          textArray[1] = getHexText(
            currentTime.hour.format("%02d") +
              ":" +
              currentTime.min.format("%02d"),
            0,
            1
          );
          if (eucData.engoPage == 1) {
            textArray[2] = getHexText(
              valueRound(eucData.PWM.abs(), "%.1f") + " %",
              0,
              3
            );
            textArray[3] = getHexText(
              valueRound(eucData.correctedSpeed, "%.1f") +
                " " +
                eucData.engoSpdUnit,
              0,
              3
            );
            textArray[4] = getHexText(
              valueRound(eucData.temperature, "%.1f") +
                " *" +
                eucData.engoTempUnit,
              0,
              3
            );
            textArray[5] = getHexText(
              valueRound(eucData.getBatteryPercentage(), "%.1f") + " %",
              0,
              3
            );
          }
          if (eucData.engoPage == 2) {
            //Chrono page 1

            var chrono;
            var activityTimerSec = null;
            var sessionDistance = null;
            var averageSpeed = null;
            var maxSpeed = null;
            if (
              activityRecordView != null &&
              activityRecordView.isSessionRecording() == true
            ) {
              activityTimerSec = activityRecordView.getElapsedTime();
              sessionDistance = activityRecordView.getSessionDist();
              averageSpeed = activityRecordView.getAvgSpeed();
              maxSpeed = activityRecordView.getMaxSpeed();
            }
            if (activityTimerSec != null) {
              var mn = activityTimerSec / 60;
              chrono = [mn / 60, mn % 60, activityTimerSec % 60];
            } else {
              chrono = [0, 0, 0];
            }
            textArray[2] = getHexText(
              chrono[0].format("%02d") +
                ":" +
                chrono[1].format("%02d") +
                ":" +
                chrono[2].format("%02d"),
              0,
              1
            );
            textArray[3] = getHexText(
              valueRound(sessionDistance, "%.1f") + " " + eucData.engoDistUnit,
              0,
              1
            );
            textArray[4] = getHexText(
              valueRound(averageSpeed, "%.1f") + " " + eucData.engoSpdUnit,
              0,
              1
            );
            textArray[5] = getHexText(
              valueRound(maxSpeed, "%.1f") + " " + eucData.engoSpdUnit,
              0,
              1
            );
          }
          var data = pagePayload(textArray);

          // System.println("sendCmd");
          // bleDelegate.flushCmdStackingIfSup(200);
          bleDelegate.sendCommands(getPageCmd(data, eucData.engoPage));

          //    bleDelegate.sendCommands(cmdTime);
        }
      }
    }
  }

  function onPosition(info as Info) as Void {}
}
