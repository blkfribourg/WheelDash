import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
using Toybox.Timer;
using Toybox.StringUtil;
import Toybox.Position;
class GarminEUCApp extends Application.AppBase {
  private var view;
  private var delegate;
  private var bleDelegate = null;
  private var engoNextUpdate = null;
  private var tiltBackInit = null;
  var timeOut = 10000;
  var activityRecordingDelay = 3000;
  var usePS;
  // private var updateDelay = 100;
  private var alarmsTimer;

  private var activityRecordingRequired = true;
  private var activityRecordView;

  function initialize() {
    eucData.limitedMemory = System.getSystemStats().totalMemory < 128000;
    AppBase.initialize();
    usePS = AppStorage.getSetting("useProfileSelector");
    alarmsTimer = new Timer.Timer();
  }

  // onStart() is called on application start up
  function onStart(state as Dictionary?) as Void {
    // Sandbox zone
    // Varia.targetObject = fakeVaria(3);
    // end of sandbox
    setGlobalSettings();
    rideStatsInit();
    Varia.initVaria();
    alarmsTimer.start(method(:onUpdateTimer), eucData.updateDelay, true);

    // check if using GPS speed
  }
  function DFViewInit() {
    if (
      !eucData.limitedMemory &&
      (eucData.dfViewBtn != 0 ||
        eucData.slideToDFView == true ||
        eucData.dfViewOnly == true)
    ) {
      if (delegate.getDFlikeView() == null) {
        // init DFlikeView
        var DFlikeView = new DFView();
        delegate.setDFlikeView(DFlikeView);
      }
    }
  }
  // onStop() is called when your application is exiting
  function onStop(state as Dictionary?) as Void {
    if (eucData.activityAutorecording == true) {
      if (delegate != null && activityRecordView != null) {
        if (activityRecordView.isSessionRecording()) {
          activityRecordView.stopRecording();
        }
      }
    }
    if (eucData.activityAutosave == true && delegate != null) {
      activityRecordView = delegate.getActivityView();
      if (activityRecordView.isSessionRecording()) {
        activityRecordView.stopRecording();
      }
    }
    delegate.unpair();
  }

  // Return the initial view of your application here
  function getInitialView() {
    view = profileSelector.createPSMenu();
    delegate = profileSelector.createPSDelegate();
    if (!usePS) {
      var profile = AppStorage.getSetting("defaultProfile");
      //System.println(profile);
      delegate.setSettings(profile);
      view = delegate.getView();
      delegate = delegate.getDelegate();
    }

    return [view, delegate];
  }
  // Timer callback for various alarms & update UI
  function onUpdateTimer() {
    // dummyGen();
    if (eucData.wheelName != null) {
      DFViewInit();
    }
    //Only starts if no profile selected
    if (eucData.wheelName == null && delegate != null && usePS) {
      timeOut = timeOut - eucData.updateDelay;
      if (timeOut <= 0) {
        var profile = AppStorage.getSetting("defaultProfile");
        delegate.setSettings(profile);
      }
    }
    if (eucData.useRadar == true) {
      Varia.checkVehicule();
    }
    if (eucData.paired == true && eucData.wheelName != null) {
      if (bleDelegate == null) {
        bleDelegate = delegate.getBleDelegate();
      }
      // automatic recording ------------------
      // a bit hacky maybe ...
      if (eucData.activityAutorecording == true) {
        if (delegate != null && activityRecordView == null) {
          // System.println("initialize autorecording");
          activityRecordView = delegate.getActivityView();
        }
        if (
          activityRecordView != null &&
          !activityRecordView.isSessionRecording() &&
          activityRecordingRequired == true
        ) {
          //enable sensor first ?
          activityRecordView.enableGPS();
          eucData.GPS_requested = true;
          activityRecordingDelay = activityRecordingDelay - eucData.updateDelay;
          //force initialization
          activityRecordView.initialize();
          if (activityRecordingDelay <= 0) {
            //System.println("record");
            activityRecordView.startRecording();
            activityRecordingRequired = false;
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
        if (gpsSpeed != null) {
          eucData.GPS_speed = gpsSpeed * 3.6;
          if (eucData.useMiles == true || eucData.convertToMiles == true) {
            eucData.GPS_speed = kmToMiles(gpsSpeed);
          }
        } else {
          eucData.GPS_speed = "...";
        }
      }
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
      // -------------------------
      //attributing here to avoid multiple calls
      eucData.correctedSpeed = eucData.getCorrectedSpeed();
      eucData.correctedTotalDistance = eucData.getCorrectedTotalDistance();
      eucData.correctedTripDistance = eucData.getCorrectedTripDistance();
      eucData.DisplayedTemperature = eucData.getTemperature();
      eucData.PWM = eucData.getPWM();
      EUCAlarms.alarmsCheck();
      if (eucData.useEngo == true) {
        engoScreenUpdate();
      }
      if (delegate.getMenu2Delegate().requestSubLabelsUpdate == true) {
        delegate.getMenu2Delegate().updateSublabels();
      }
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
  function engoScreenUpdate() {
    var now = new Time.Moment(Time.now().value());
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
          textArray[0] = getHexText(eucData.engoBattery + " %");
        } else {
          textArray[0] = getHexText(" ");
        }

        textArray[1] = getHexText(
          currentTime.hour.format("%02d") + ":" + currentTime.min.format("%02d")
        );
        if (eucData.engoPage == 1) {
          textArray[2] = getHexText(valueRound(eucData.PWM, "%.1f") + " %");
          textArray[3] = getHexText(
            valueRound(eucData.correctedSpeed, "%.1f") + " km/h"
          );
          textArray[4] = getHexText(
            valueRound(eucData.temperature, "%.1f") + " km/h"
          );
          textArray[5] = getHexText(
            valueRound(eucData.getBatteryPercentage(), "%.1f") + " %"
          );
        }
        if (eucData.engoPage == 2) {
          //Chrono page 1

          var chrono;
          var activityTimerTime = null;
          var sessionDistance = null;
          var averageSpeed = null;
          var maxSpeed = null;
          if (activityRecordView != null) {
            activityTimerTime = activityRecordView.getElapsedTime();
            sessionDistance = activityRecordView.getSessionDist();
            averageSpeed = activityRecordView.getAvgSpeed();
            maxSpeed = activityRecordView.getMaxSpeed();
          }
          if (activityTimerTime != null) {
            var sec = activityTimerTime / 1000;
            var mn = sec / 60;
            chrono = [mn / 60, mn % 60, sec % 60, activityTimerTime % 1000];
          } else {
            chrono = [0, 0, 0];
          }
          textArray[2] = getHexText(
            chrono[0].format("%02d") +
              ":" +
              chrono[1].format("%02d") +
              ":" +
              chrono[2].format("%02d")
          );
          textArray[3] = getHexText(
            valueRound(sessionDistance, "%.1f") + " km"
          );
          textArray[4] = getHexText(valueRound(averageSpeed, "%.1f") + " km/h");
          textArray[5] = getHexText(valueRound(maxSpeed, "%.1f") + " km/h");
        }
        var data = pagePayload(textArray);

        // System.println("sendCmd");
        bleDelegate.sendCommands(getPageCmd(data, eucData.engoPage));
        //    bleDelegate.sendCommands(cmdTime);
      }
    }
  }
  function rideStatsInit() {
    rideStats.movingmsec = 0;
    rideStats.statsTimerReset();

    // unelegant
    if (rideStats.showAverageMovingSpeedStatistic) {
      rideStats.statsNumberToDiplay++;
    }
    if (rideStats.showTopSpeedStatistic) {
      rideStats.statsNumberToDiplay++;
    }
    if (rideStats.showWatchBatteryConsumptionStatistic) {
      rideStats.statsNumberToDiplay++;
    }
    if (rideStats.showTotalDistance) {
      rideStats.statsNumberToDiplay++;
    }
    if (rideStats.showTripDistance) {
      rideStats.statsNumberToDiplay++;
    }
    if (rideStats.showVoltage) {
      rideStats.statsNumberToDiplay++;
    }
    if (rideStats.showWatchBatteryStatistic) {
      rideStats.statsNumberToDiplay++;
    }
    if (rideStats.showProfileName) {
      rideStats.statsNumberToDiplay++;
    }
    rideStats.statsArray = new [rideStats.statsNumberToDiplay];
    //System.println("array size:" + rideStats.statsArray.size());
  }
  function setGlobalSettings() {
    eucData.useEngo = AppStorage.getSetting("useEngo");
    eucData.engoTouch = AppStorage.getSetting("engoTouch");
    eucData.useRadar = AppStorage.getSetting("useRadar");
    eucData.variaCloseAlarmDistThr = AppStorage.getSetting(
      "variaCloseAlarmDistThr"
    );
    eucData.variaFarAlarmDistThr = AppStorage.getSetting(
      "variaFarAlarmDistThr"
    );
    eucData.ESP32Horn = AppStorage.getSetting("ESP32Horn");
    eucData.motorbikeHeadset = AppStorage.getSetting("motorbikeHeadset");
    eucData.vibeIntensity = AppStorage.getSetting("vibeIntensity");
    eucData.alternativeFont = AppStorage.getSetting("alternativeFont");
    eucData.slideToDFView = AppStorage.getSetting("slideToDFView");
    eucData.dfViewOnly = AppStorage.getSetting("dfViewOnly");
    eucData.displayWind = AppStorage.getSetting("displayWind");
    eucData.displayNorth = AppStorage.getSetting("displayNorth");
    eucData.useMiles = AppStorage.getSetting("useMiles");
    eucData.useFahrenheit = AppStorage.getSetting("useFahrenheit");
    eucData.convertToMiles = AppStorage.getSetting("convertToMiles");
    eucData.convertToFahrenheit = AppStorage.getSetting("convertToFahrenheit");
    //Im Horn experimental
    eucData.imHornSound = AppStorage.getSetting("imHornSound");
    eucData.KSVoiceMode = AppStorage.getSetting("KSVoiceMode");
    eucData.updateDelay = AppStorage.getSetting("updateDelay");
    eucData.debug = AppStorage.getSetting("debugMode");
    eucData.activityAutorecording = AppStorage.getSetting(
      "activityRecordingOnStartup"
    );
    eucData.activityAutosave = AppStorage.getSetting("activitySavingOnExit");

    rideStats.showAverageMovingSpeedStatistic = AppStorage.getSetting(
      "averageMovingSpeedStatistic"
    );
    rideStats.showTopSpeedStatistic =
      AppStorage.getSetting("topSpeedStatistic");

    rideStats.showWatchBatteryConsumptionStatistic = AppStorage.getSetting(
      "watchBatteryConsumptionStatistic"
    );
    rideStats.showTripDistance = AppStorage.getSetting("tripDistanceStatistic");
    rideStats.showTotalDistance = AppStorage.getSetting(
      "totalDistanceStatistic"
    );

    rideStats.showVoltage = AppStorage.getSetting("voltageStatistic");
    rideStats.showWatchBatteryStatistic = AppStorage.getSetting(
      "watchBatteryStatistic"
    );
    rideStats.showProfileName = AppStorage.getSetting("profileName");
  }

  function onPosition(info as Info) as Void {}
}

function getApp() as GarminEUCApp {
  return Application.getApp() as GarminEUCApp;
}
