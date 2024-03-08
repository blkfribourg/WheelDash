import Toybox.Lang;
import Toybox.System;
module rideStats {
  var showAverageMovingSpeedStatistic;
  var showTopSpeedStatistic;
  var showWatchBatteryConsumptionStatistic;
  var showTripDistance;
  var showTotalDistance;
  var showVoltage;
  var showWatchBatteryStatistic;
  var statsNumberToDiplay = 0;
  var statsIndexToDiplay = 0;
  var statsArray;
  var minimalMovingSpeed = 3.0; // 3 kmh erased in GarminEUCApp
  var distanceSinceStartup;
  var startupDistance as Float?;
  var movingmsec = 0.0;
  var runningmsec = 0.0;
  var statsTimer;
  var consummedWatchBattery = 0.0;
  var startupWatchBattery;
  var showProfileName;

  function avgSpeed() {
    if (eucData.useMiles == false) {
      minimalMovingSpeed = 2; // 2 mph
    } else {
      minimalMovingSpeed = 3; // 3 km/h
    }
    if (eucData.correctedSpeed > minimalMovingSpeed) {
      if (startupDistance == null) {
        startupDistance = eucData.correctedTripDistance;
      }
      movingmsec = movingmsec + eucData.updateDelay;
      eucData.avgMovingSpeed =
        (eucData.correctedTripDistance - startupDistance) /
        (movingmsec / 3600000.0);
    }
  }

  function topSpeed() {
    if (eucData.correctedSpeed > eucData.topSpeed) {
      eucData.topSpeed = eucData.correctedSpeed;
    }
  }

  function watchBatteryUsage() {
    runningmsec = runningmsec + eucData.updateDelay;
    if (startupWatchBattery == null) {
      startupWatchBattery = System.getSystemStats().battery;
    }
    consummedWatchBattery =
      startupWatchBattery - System.getSystemStats().battery;
    eucData.watchBatteryUsage =
      consummedWatchBattery / (runningmsec / 3600000.0);
  }

  function statsTimerReset() {
    statsTimer = 2000.0 / eucData.updateDelay;
  }
}
