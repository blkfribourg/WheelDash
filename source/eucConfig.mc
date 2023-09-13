class gotwayConfig {
  function getWheelSettingsStatus() {
    return [
      eucData.ledMode.toString(),
      eucData.speedAlertMode.toString(),
      eucData.pedalMode.toString(),
      eucData.useMiles.toString(),
    ];
  }
  function getConfigWithStatusDict() {
    return [dictLedMode, dictAlarmStatus, dictPedalStatus, dictDstUnitStatus];
  }
  function getConfigWithStatusLabels() {
    return ["Leds Mode", "Speed Alarm", "Pedal Mode", "Distance unit"];
  }
  function getConfig() {
    return [
      dictLightsMode,
      dictLedMode,
      dictAlarmMode,
      dictPedalMode,
      dictCutoffAngleMode,
      dictVolume,
      dictDstUnit,
    ];
  }
  function getConfigLabels() {
    return [
      "Lights",
      "Leds Mode",
      "Speed Alarm",
      "Pedal Mode",
      "Cutoff Angle",
      "Beep Volume",
      "Distance unit",
    ];
  }
  function getConfigToLock() {
    return ["Speed Alarm", "Pedal Mode", "Cutoff Angle", "Distance unit"];
  }

  //dict for communication
  var dictLightsMode = {
    "On" => "Q",
    "Off" => "E",
    "Flashing" => "T",
  };
  var dictPedalMode = {
    "Hard" => "h",
    "Medium" => "f",
    "Soft" => "s",
  };
  var dictAlarmMode = {
    "PWM only" => "i",
    "35Kmh + PWM" => "u",
    "30Kmh + PWM" => "o",
  };
  var dictCutoffAngleMode = {
    "High" => "<",
    "Medium" => "=",
    "Low" => ">",
  };
  var dictLedMode = {
    "0" => "0",
    "1" => "1",
    "2" => "2",
    "3" => "3",
    "4" => "4",
  };
  var dictVolume = {
    "1" => "1",
    "2" => "2",
    "3" => "3",
    "4" => "4",
    "5" => "5",
    "6" => "6",
    "7" => "7",
    "8" => "8",
    "9" => "9",
  };

  var dictDstUnit = {
    "km" => "g",
    "miles" => "m",
  };
  var dictDstUnitStatus = {
    "km" => "0",
    "miles" => "1",
  };
  // dict for status report
  // no lights & volume "feedback" on tesla v2
  /*
        var dictLightStatus ={
            "On" => "0",
            "Off" => "1",
            "Flashing" => "2"
        };
        */

  /* No angle status feedback
        var dictCutoffAngleStatus={
            "High" => "2",
            "Medium" => "1",
            "Low" => "0"
        };
*/
  var dictPedalStatus = {
    "Hard" => "2",
    "Medium" => "1",
    "Soft" => "0",
  };
  var dictAlarmStatus = {
    "PWM only" => "2",
    "35Kmh + PWM" => "1",
    "30Kmh + PWM" => "0",
  };
}

class veteranConfig {
  function getWheelSettingsStatus() {
    return [eucData.pedalMode.toString()];
  }
  function getConfigWithStatusDict() {
    return [dictPedalStatus];
  }
  function getConfigWithStatusLabels() {
    return ["Pedal Mode"];
  }
  function getConfig() {
    return [dictLightsMode, dictPedalMode, dictResetTrip];
  }
  function getConfigLabels() {
    return ["Lights", "Pedal Mode", "Reset trip"];
  }

  function getConfigToLock() {
    return ["Pedal Mode"];
  }

  //dict for communication
  var dictLightsMode = {
    "On" => "SetLightON",
    "Off" => "SetLightOFF",
  };
  var dictPedalMode = {
    "Hard" => "SETh",
    "Medium" => "SETm",
    "Soft" => "SETs",
  };
  var dictResetTrip = {
    "Yes" => "CLEARMETER",
    "No" => "",
  };
  var dictPedalStatus = {
    "Hard" => "0",
    "Medium" => "1",
    "Soft" => "2",
  };
}

class kingsongConfig {
  function getWheelSettingsStatus() {
    return [];
  }
  function getConfigWithStatusDict() {
    return [];
  }
  function getConfigWithStatusLabels() {
    return [];
  }
  function getConfig() {
    return [dictLightsMode, dictStrobeMode, dictLedMode, dictPedalMode];
  }
  function getConfigLabels() {
    return ["Lights", "Strobe Mode", "Leds Mode", "Pedal Mode"];
  }

  function getConfigToLock() {
    return ["Pedal Mode"];
  }
  //dict for communication
  var dictStrobeMode = {
    "On" => 1,
    "Off" => 0,
  };
  var dictLightsMode = {
    "On" => 0,
    "Off" => 1,
    "Auto" => 2,
  };
  var dictPedalMode = {
    "Hard" => 0,
    "Medium" => 1,
    "Soft" => 2,
  };
  var dictLedMode = {
    "On" => 0,
    "Off" => 1,
  };
}

class dummyConfig {
  function getWheelSettingsStatus() {
    return [];
  }
  function getConfigWithStatusDict() {
    return [];
  }
  function getConfigWithStatusLabels() {
    return [];
  }
  function getConfig() {
    return [];
  }
  function getConfigLabels() {
    return [];
  }

  function getConfigToLock() {
    return [];
  }
}
