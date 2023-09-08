class gotwayConfig {
  function getWheelSettingsStatus() {
    return [
      eucData.ledMode.toString(),
      eucData.speedAlertMode.toString(),
      eucData.pedalMode.toString(),
    ];
  }
  function getConfigWithStatusDict() {
    return [dictLedMode, dictAlarmStatus, dictPedalStatus];
  }
  function getConfigWithStatusLabels() {
    return ["Leds Mode", "Speed Alarm", "Pedal Mode"];
  }
  function getConfig() {
    return [
      dictLightsMode,
      dictLedMode,
      dictAlarmMode,
      dictPedalMode,
      dictCutoffAngleMode,
      dictVolume,
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
    ];
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
