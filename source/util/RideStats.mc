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
  var computeMaxTemperature = false;
  var computeTopSpeed = false;
  var computeAvgMovingSpeed = false;
  var computeMinVoltage = false;
  var computeMaxVoltage = false;
  var computeMaxCurrent = false;
  var computeAvgCurrent = false;
  var computeMinBatteryPerc = false;
  var computeMaxBatteryPerc = false;
  var computeAvgPower = false;
  var computeMaxPower = false;
  var computeMaxPWM = false;
  var computeBatteryUsagePerc = false;
  var computeBatteryUsage = false;
  var computeWatchBatteryUsage = false;
  var currentSum;
  var currentCount;
  var powerSum;
  var powerCount;
  var EUCBatteryPercStart;

  function avgSpeed() {
    if (eucData.useMiles == true) {
      minimalMovingSpeed = 2; // 2 mph
    } else {
      minimalMovingSpeed = 3; // 3 km/h
    }
    if (eucData.correctedSpeed > minimalMovingSpeed) {
      if (startupDistance == null) {
        startupDistance = eucData.correctedTripDistance;
      } else {
        movingmsec = movingmsec + eucData.updateDelay;
        eucData.avgMovingSpeed =
          (eucData.correctedTripDistance - startupDistance) /
          (movingmsec / 3600000.0);
      }
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

  function calcMaxTemp() {
    if (eucData.maxTemperature == null) {
      eucData.maxTemperature = eucData.DisplayedTemperature;
    } else {
      if (eucData.maxTemperature < eucData.DisplayedTemperature) {
        eucData.maxTemperature = eucData.DisplayedTemperature;
      }
    }
  }
  function calcMinVoltage() {
    if (eucData.minVoltage == null) {
      eucData.minVoltage = eucData.getVoltage();
    } else {
      if (eucData.minVoltage > eucData.getVoltage()) {
        eucData.minVoltage = eucData.getVoltage();
      }
    }
  }
  function calcMaxVoltage() {
    if (eucData.maxVoltage == null) {
      eucData.maxVoltage = eucData.getVoltage();
    } else {
      if (eucData.maxVoltage < eucData.getVoltage()) {
        eucData.maxVoltage = eucData.getVoltage();
      }
    }
  }

  function calcMaxCurrent() {
    if (eucData.maxCurrent == null) {
      eucData.maxCurrent = eucData.getCurrent();
    } else {
      if (eucData.maxCurrent < eucData.getCurrent()) {
        eucData.maxCurrent = eucData.getCurrent();
      }
    }
  }

  function calcMinBatteryPerc() {
    if (eucData.minBatteryPerc == null) {
      eucData.minBatteryPerc = eucData.getBatteryPercentage();
    } else {
      if (eucData.minBatteryPerc > eucData.getBatteryPercentage()) {
        eucData.minBatteryPerc = eucData.getBatteryPercentage();
      }
    }
  }

  function calcMaxBatteryPerc() {
    if (eucData.maxBatteryPerc == null) {
      eucData.maxBatteryPerc = eucData.getBatteryPercentage();
    } else {
      if (eucData.maxBatteryPerc < eucData.getBatteryPercentage()) {
        eucData.maxBatteryPerc = eucData.getBatteryPercentage();
      }
    }
  }

  function calcAvgCurrent() {
    if (eucData.avgCurrent == null) {
      if (eucData.useMiles == true) {
        minimalMovingSpeed = 2; // 2 mph
      } else {
        minimalMovingSpeed = 3; // 3 km/h
      }
      currentSum = eucData.getCurrent();
      currentCount = 1.0;
      eucData.avgCurrent = currentSum;
    } else {
      if (eucData.correctedSpeed > minimalMovingSpeed) {
        currentSum = currentSum + eucData.getCurrent();
        currentCount = currentCount + 1;
        eucData.avgCurrent = currentSum / currentCount;
      }
    }
  }

  function calcAvgPower() {
    var current = eucData.getCurrent().abs();
    var voltage = eucData.getVoltage();
    if (eucData.avgPower == null) {
      if (eucData.useMiles == true) {
        minimalMovingSpeed = 2; // 2 mph
      } else {
        minimalMovingSpeed = 3; // 3 km/h
      }

      if (current != null && voltage != null) {
        powerSum = current * voltage;
        powerCount = 1.0;
        eucData.avgPower = powerSum;
      }
    } else {
      if (eucData.correctedSpeed > minimalMovingSpeed) {
        powerSum = powerSum + current * voltage;
        powerCount = powerCount + 1;
        eucData.avgPower = powerSum / powerCount;
      }
    }
  }

  function calcMaxPower() {
    var current = eucData.getCurrent().abs();
    var voltage = eucData.getVoltage();
    if (eucData.maxPower == null) {
      if (current != null && voltage != null) {
        eucData.maxPower = current * voltage;
      }
    } else {
      if (eucData.maxPower < current * voltage) {
        eucData.maxPower = current * voltage;
      }
    }
  }

  function calcMaxPWM() {
    var PWM = eucData.getPWM();
    if (eucData.maxPWM == null) {
      eucData.maxPWM = PWM;
    } else {
      if (eucData.maxPWM < PWM) {
        eucData.maxPWM = PWM;
      }
    }
  }

  function calcBatteryUsagePerc() {
    var eucBattery = eucData.getBatteryPercentage();

    if (
      eucData.batteryUsagePerc == null &&
      eucBattery > 0.0 &&
      eucData.paired == true
    ) {
      EUCBatteryPercStart = eucBattery;
      eucData.batteryUsagePerc = 0;
    } else {
      if (EUCBatteryPercStart != null && EUCBatteryPercStart > eucBattery) {
        eucData.batteryUsagePerc = EUCBatteryPercStart - eucBattery;
      } else {
        EUCBatteryPercStart = eucBattery;
      }
    }
  }

  function calcBatteryUsage() {
    calcBatteryUsagePerc();
    if (eucData.batteryUsagePerc != null && eucData.correctedTripDistance > 0) {
      eucData.batteryUsage =
        eucData.batteryUsagePerc / eucData.correctedTripDistance;
    }
  }

  function statsTimerReset() {
    statsTimer = 2000.0 / eucData.updateDelay;
  }

  function computeDFViewStats() {
    if (computeMaxTemperature == true) {
      calcMaxTemp();
    }
    if (computeTopSpeed == true && showTopSpeedStatistic == false) {
      topSpeed();
    }
    if (
      computeAvgMovingSpeed == true &&
      showAverageMovingSpeedStatistic == false
    ) {
      avgSpeed();
    }
    if (computeMinVoltage == true) {
      calcMinVoltage();
    }
    if (computeMaxVoltage == true) {
      calcMaxVoltage();
    }
    if (computeMaxCurrent == true) {
      calcMaxCurrent();
    }
    if (computeAvgCurrent == true) {
      calcAvgCurrent();
    }
    if (computeMinBatteryPerc == true) {
      calcMinBatteryPerc();
    }
    if (computeMaxBatteryPerc == true) {
      calcMaxBatteryPerc();
    }
    if (computeAvgPower == true) {
      calcAvgPower();
    }
    if (computeMaxPower == true) {
      calcMaxPower();
    }
    if (computeMaxPWM == true) {
      calcMaxPWM();
    }
    if (computeBatteryUsagePerc == true) {
      calcBatteryUsagePerc();
    }
    if (computeBatteryUsage == true) {
      calcBatteryUsage();
    }
    if (
      computeWatchBatteryUsage == true &&
      showWatchBatteryConsumptionStatistic == false
    ) {
      watchBatteryUsage();
    }
  }
}
