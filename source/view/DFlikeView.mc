import Toybox.Graphics;
import Toybox.WatchUi;
using Toybox.Timer;
using Toybox.ActivityMonitor;
import Toybox.Weather;
using Toybox.System;
using Toybox.Time.Gregorian;
import Toybox.Position;
class DFView extends WatchUi.View {
  hidden var hasHr = null;
  hidden var hasWX = null;
  hidden var reqPos = false;
  hidden var reqWX = false;
  hidden var fieldIDs = null;
  hidden var fieldNB = 6;
  hidden var current_position = null;
  hidden var current_weather = null;
  hidden var hourly_weather = null;
  hidden var daily_weather = null;
  hidden var maxTemperature = null;
  hidden var fieldNames = null;
  hidden var fieldValues = null;
  hidden var weatherFont = null;
  hidden var fieldValueFont = null;
  hidden var weatherChar = null;
  hidden var weatherReqTimer = null;
  hidden var paddingCorrection;
  var weatherReqTiming = 60000;

  function initialize() {
    View.initialize();
    if (Toybox has :ActivityMonitor) {
      hasHr = ActivityMonitor has :getHeartRateHistory;
    }

    if (Toybox has :Weather) {
      hasWX = Weather has :getCurrentConditions;
    }

    fieldIDs = [
      AppStorage.getSetting("field1"),
      AppStorage.getSetting("field2"),
      AppStorage.getSetting("field3"),
      AppStorage.getSetting("field4"),
      AppStorage.getSetting("field5"),
      AppStorage.getSetting("field6"),
    ];
    fieldNB = AppStorage.getSetting("fieldNB");

    fieldNames = new [fieldNB];
    fieldValues = new [fieldNB];
    if (
      fieldIDs.slice(0, fieldNB).indexOf(21) != -1 ||
      fieldIDs.slice(0, fieldNB).indexOf(22) != -1 ||
      eucData.displayNorth == true ||
      eucData.displayWind == true
    ) {
      reqPos = true;
      enableGPS();
    }
    if (fieldIDs.slice(0, fieldNB).indexOf(28) != -1) {
      weatherFont = WatchUi.loadResource(Rez.Fonts.Weather);
      initWeatherChar();
    }

    if (
      fieldIDs.slice(0, fieldNB).indexOf(26) != -1 ||
      fieldIDs.slice(0, fieldNB).indexOf(27) != -1 ||
      fieldIDs.slice(0, fieldNB).indexOf(28) != -1 ||
      fieldIDs.slice(0, fieldNB).indexOf(29) != -1 ||
      fieldIDs.slice(0, fieldNB).indexOf(30) != -1 ||
      fieldIDs.slice(0, fieldNB).indexOf(31) != -1 ||
      eucData.displayWind == true
    ) {
      reqWX = true;
    }
    setReqVars();
    getfieldValues();
  }

  function setReqVars() {
    if (fieldIDs.slice(0, fieldNB).indexOf(8) != -1) {
      rideStats.computeBatteryUsagePerc = true;
    }
    if (fieldIDs.slice(0, fieldNB).indexOf(9) != -1) {
      rideStats.computeMaxTemperature = true;
    }
    if (fieldIDs.slice(0, fieldNB).indexOf(10) != -1) {
      rideStats.computeTopSpeed = true;
    }
    if (fieldIDs.slice(0, fieldNB).indexOf(11) != -1) {
      rideStats.computeAvgMovingSpeed = true;
    }
    if (fieldIDs.slice(0, fieldNB).indexOf(12) != -1) {
      rideStats.computeMinVoltage = true;
    }
    if (fieldIDs.slice(0, fieldNB).indexOf(13) != -1) {
      rideStats.computeMaxVoltage = true;
    }
    if (fieldIDs.slice(0, fieldNB).indexOf(14) != -1) {
      rideStats.computeMaxCurrent = true;
    }
    if (fieldIDs.slice(0, fieldNB).indexOf(15) != -1) {
      rideStats.computeAvgCurrent = true;
    }
    if (fieldIDs.slice(0, fieldNB).indexOf(16) != -1) {
      rideStats.computeMinBatteryPerc = true;
    }
    if (fieldIDs.slice(0, fieldNB).indexOf(17) != -1) {
      rideStats.computeMaxBatteryPerc = true;
    }
    if (fieldIDs.slice(0, fieldNB).indexOf(18) != -1) {
      rideStats.computeAvgPower = true;
    }
    if (fieldIDs.slice(0, fieldNB).indexOf(19) != -1) {
      rideStats.computeMaxPower = true;
    }
    if (fieldIDs.slice(0, fieldNB).indexOf(10) != -1) {
      rideStats.computeMaxPWM = true;
    }
    if (fieldIDs.slice(0, fieldNB).indexOf(25) != -1) {
      rideStats.computeWatchBatteryUsage = true;
    }
    if (fieldIDs.slice(0, fieldNB - 1).indexOf(32) != -1) {
      rideStats.computeBatteryUsage = true;
    }
  }
  function getfieldValues() {
    if (reqPos == true && eucData.GPS_requested == false) {
      enableGPS();
    }
    if (reqPos == true) {
      current_position = Position.getInfo();
    }
    if (reqWX == true && hasWX == true) {
      if (weatherReqTimer == null || weatherReqTimer < 0) {
        //System.println("weather refresh");
        weatherReqTimer = weatherReqTiming;
        current_weather = Weather.getCurrentConditions();

        if (current_weather == null) {
          hourly_weather = getWXFromHourly(Weather.getHourlyForecast());
        }
      } else {
        weatherReqTimer = weatherReqTimer - eucData.updateDelay;
      }
    }

    for (var field_id = 0; field_id < fieldNB; field_id++) {
      if (fieldIDs[field_id] == 0) {
        fieldNames[field_id] = "SPEED";
        fieldValues[field_id] = valueRound(eucData.correctedSpeed, "%.1f");
      }
      if (fieldIDs[field_id] == 1) {
        fieldNames[field_id] = "VOLTAGE";
        fieldValues[field_id] = valueRound(eucData.getVoltage(), "%.2f");
      }
      if (fieldIDs[field_id] == 2) {
        fieldNames[field_id] = "TRP DIST";
        fieldValues[field_id] = valueRound(
          eucData.correctedTripDistance,
          "%.1f"
        );
      }
      if (fieldIDs[field_id] == 3) {
        fieldNames[field_id] = "CURR";
        fieldValues[field_id] = valueRound(eucData.getCurrent(), "%.1f");
      }
      if (fieldIDs[field_id] == 4) {
        fieldNames[field_id] = "TEMP";
        fieldValues[field_id] = valueRound(
          eucData.DisplayedTemperature,
          "%.1f"
        );
      }
      if (fieldIDs[field_id] == 5) {
        fieldNames[field_id] = "TT DIST";
        fieldValues[field_id] = valueRound(
          eucData.correctedTotalDistance,
          "%.1f"
        );
      }
      if (fieldIDs[field_id] == 6) {
        fieldNames[field_id] = "PWM";
        fieldValues[field_id] = valueRound(eucData.PWM, "%.1f");
      }
      if (fieldIDs[field_id] == 7) {
        fieldNames[field_id] = "BATT %";
        fieldValues[field_id] = valueRound(
          eucData.getBatteryPercentage(),
          "%.1f"
        );
      }
      if (fieldIDs[field_id] == 8) {
        fieldNames[field_id] = "BATT USG%"; //TODO
        fieldValues[field_id] = valueRound(eucData.batteryUsagePerc, "%.1f");
      }
      if (fieldIDs[field_id] == 9) {
        fieldNames[field_id] = "MAX TEMP";
        fieldValues[field_id] = valueRound(eucData.maxTemperature, "%.1f");
      }
      if (fieldIDs[field_id] == 10) {
        fieldNames[field_id] = "TOP SPD";
        fieldValues[field_id] = valueRound(eucData.topSpeed, "%.1f");
      }
      if (fieldIDs[field_id] == 11) {
        fieldNames[field_id] = "AVG SPD";
        fieldValues[field_id] = valueRound(eucData.avgMovingSpeed, "%.1f");
      }
      if (fieldIDs[field_id] == 12) {
        fieldNames[field_id] = "MIN VOLT";
        fieldValues[field_id] = valueRound(eucData.minVoltage, "%.2f");
      }
      if (fieldIDs[field_id] == 13) {
        fieldNames[field_id] = "MAX VOLT";
        fieldValues[field_id] = valueRound(eucData.maxVoltage, "%.2f");
      }
      if (fieldIDs[field_id] == 14) {
        fieldNames[field_id] = "MAX CURR";
        fieldValues[field_id] = valueRound(eucData.maxCurrent, "%.1f");
      }
      if (fieldIDs[field_id] == 15) {
        fieldNames[field_id] = "AVG CURR";
        fieldValues[field_id] = valueRound(eucData.avgCurrent, "%.1f");
      }
      if (fieldIDs[field_id] == 16) {
        fieldNames[field_id] = "MIN BATT %";
        fieldValues[field_id] = valueRound(
          eucData.lowestBatteryPercentage,
          "%.1f"
        );
      }
      if (fieldIDs[field_id] == 17) {
        fieldNames[field_id] = "MAX BATT %";
        fieldValues[field_id] = valueRound(eucData.maxBatteryPerc, "%.1f");
      }
      if (fieldIDs[field_id] == 18) {
        fieldNames[field_id] = "AVG PWR";
        fieldValues[field_id] = valueRound(eucData.avgPower, "%.1f");
      }
      if (fieldIDs[field_id] == 19) {
        fieldNames[field_id] = "MAX PWR";
        fieldValues[field_id] = valueRound(eucData.maxPower, "%.1f");
      }
      if (fieldIDs[field_id] == 20) {
        fieldNames[field_id] = "MAX PWM";
        fieldValues[field_id] = valueRound(eucData.maxPWM, "%.1f");
      }
      // GPS
      if (fieldIDs[field_id] == 21) {
        fieldNames[field_id] = "GPS ALT";
        if (current_position != null && current_position.accuracy >= 2) {
          fieldValues[field_id] = valueRound(current_position.altitude, "%.1f");
        } else {
          fieldValues[field_id] = "--";
        }
      }
      if (fieldIDs[field_id] == 22) {
        fieldNames[field_id] = "GPS SPD";
        if (current_position != null && current_position.accuracy >= 2) {
          var GPSSpeed = current_position.speed * 3.6;
          if (eucData.useMiles == true) {
            GPSSpeed = kmToMiles(GPSSpeed);
          }
          fieldValues[field_id] = valueRound(GPSSpeed, "%.1f");
        } else {
          fieldValues[field_id] = "--";
        }
      }
      //WATCH SENSOR
      if (fieldIDs[field_id] == 23) {
        fieldNames[field_id] = "HRATE";
        fieldValues[field_id] = getHR();
      }
      if (fieldIDs[field_id] == 24) {
        fieldNames[field_id] = "WTCH BAT";
        fieldValues[field_id] = valueRound(
          System.getSystemStats().battery,
          "%d"
        );
      }
      if (fieldIDs[field_id] == 25) {
        fieldNames[field_id] = "WTCH USG";
        fieldValues[field_id] = valueRound(eucData.watchBatteryUsage, "%.1f");
      }
      //WATCH WEATHER
      if (fieldIDs[field_id] == 26) {
        fieldNames[field_id] = "WX TEMP";
        if (current_weather != null && current_weather.temperature != null) {
          fieldValues[field_id] = valueRound(
            current_weather.temperature,
            "%.1f"
          );
        } else {
          if (hourly_weather != null && hourly_weather.temperature != null) {
            fieldValues[field_id] = valueRound(
              hourly_weather.temperature,
              "%.1f"
            );
          } else {
            fieldValues[field_id] = "--";
          }
        }
      }

      if (fieldIDs[field_id] == 27) {
        fieldNames[field_id] = "RF TEMP";
        if (
          current_weather != null &&
          current_weather.feelsLikeTemperature != null
        ) {
          fieldValues[field_id] = valueRound(
            current_weather.feelsLikeTemperature,
            "%.1f"
          );
        } else {
          fieldValues[field_id] = "--";
        }
      }
      if (fieldIDs[field_id] == 28) {
        fieldNames[field_id] = "WX COND";
        if (current_weather != null && current_weather.condition != null) {
          fieldValues[field_id] = current_weather.condition;
        } else {
          if (hourly_weather != null && hourly_weather.condition != null) {
            fieldValues[field_id] = hourly_weather.condition;
          } else {
            fieldValues[field_id] = 53;
          }
        }
      }
      if (fieldIDs[field_id] == 29) {
        fieldNames[field_id] = "RAIN";
        if (
          current_weather != null &&
          current_weather.precipitationChance != null
        ) {
          fieldValues[field_id] = valueRound(
            current_weather.precipitationChance,
            "%d"
          );
        } else {
          if (
            hourly_weather != null &&
            hourly_weather.precipitationChance != null
          ) {
            fieldValues[field_id] = valueRound(
              hourly_weather.precipitationChance,
              "%.1f"
            );
          } else {
            fieldValues[field_id] = "--";
          }
        }
      }
      if (fieldIDs[field_id] == 30) {
        fieldNames[field_id] = "HUM";
        if (current_weather != null) {
          fieldValues[field_id] = valueRound(
            current_weather.relativeHumidity,
            "%.1f"
          );
        } else {
          if (hourly_weather != null && hourly_weather.relativeHumidity) {
            fieldValues[field_id] = valueRound(
              hourly_weather.relativeHumidity,
              "%.1f"
            );
          } else {
            fieldValues[field_id] = "--";
          }
        }
      }
      if (fieldIDs[field_id] == 31) {
        fieldNames[field_id] = "WIND SPD";
        var windSpeed = null;
        if (current_weather != null && current_weather.windSpeed != null) {
          windSpeed = current_weather.windSpeed;
        } else {
          if (hourly_weather != null && hourly_weather.windSpeed != null) {
            windSpeed = hourly_weather.windSpeed;
          }
        }
        if (windSpeed != null) {
          windSpeed = windSpeed * 3.6;
          if (eucData.useMiles == true) {
            windSpeed = kmToMiles(windSpeed);
          }
          fieldValues[field_id] = valueRound(windSpeed, "%.1f");
        } else {
          fieldValues[field_id] = "--";
        }
      }
      if (fieldIDs[field_id] == 32) {
        fieldNames[field_id] = "BATT USG";
        if (current_weather != null) {
          fieldValues[field_id] = valueRound(eucData.batteryUsage, "%.1f");
        } else {
          fieldValues[field_id] = "--";
        }
      }
      if (fieldIDs[field_id] == 33) {
        fieldNames[field_id] = "TIME";
        var CurrentTime = System.getClockTime();

        fieldValues[field_id] =
          CurrentTime.hour.format("%d") + ":" + CurrentTime.min.format("%02d");
      }
    }
  }

  // Called when this View is brought to the foreground. Restore
  // the state of this View and prepare it to be shown. This includes
  // loading resources into memory.
  function onShow() {}

  // Update the view
  function onUpdate(dc) {
    getfieldValues();

    var gap;
    var scr_width = dc.getWidth();
    var scr_height = dc.getHeight();
    var orig = scr_width / 2 - 1;
    var fieldNameFont;
    var fieldNameFontHeight;
    var fieldValueFontHeight;
    var gap_lineMod = 1;

    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
    dc.clear();
    if (fieldNB == 6) {
      paddingCorrection = 0.85;
      fieldNameFont = Graphics.FONT_XTINY;
      if (eucData.alternativeFont == true && eucData.limitedMemory == false) {
        fieldValueFont = WatchUi.loadResource(Rez.Fonts.Rajdhani);
      } else {
        fieldValueFont = Graphics.FONT_SYSTEM_NUMBER_MILD;
        if (scr_width <= 260) {
          fieldValueFont = Graphics.FONT_LARGE;
        }
      }

      if (scr_width < 260) {
        gap = scr_width / 80;
        gap_lineMod = 4;
        paddingCorrection = 1;
      } else {
        gap = scr_width / 40;
      }
      fieldNameFontHeight =
        Graphics.getFontHeight(fieldNameFont) * paddingCorrection;
      fieldValueFontHeight =
        Graphics.getFontHeight(fieldValueFont) * (paddingCorrection + 0.2);
      if (eucData.drawLines) {
        dc.setPenWidth(2);
        dc.setColor(eucData.linesColor, Graphics.COLOR_BLACK);
        dc.drawLine(
          gap_lineMod * gap,
          orig,
          scr_width - gap_lineMod * gap,
          orig
        );
        dc.drawLine(
          orig,
          fieldNameFontHeight + fieldValueFontHeight,
          orig,
          orig - gap_lineMod * gap
        );
        dc.drawLine(
          orig,
          orig + gap_lineMod * gap,
          orig,
          orig + orig - (fieldNameFontHeight + fieldValueFontHeight)
        );
      }
      if (eucData.paired == true) {
        dc.setColor(eucData.txtColor, Graphics.COLOR_TRANSPARENT);
      } else {
        dc.setColor(eucData.txtColor_unpr, Graphics.COLOR_TRANSPARENT);
      }

      dc.drawText(
        orig,
        gap,
        fieldNameFont,
        fieldNames[0],
        Graphics.TEXT_JUSTIFY_CENTER
      );
      drawDFTextValue(dc, orig, gap + fieldNameFontHeight, 0);

      dc.drawText(
        scr_width / 4,
        scr_width / 4,
        fieldNameFont,
        fieldNames[1],
        Graphics.TEXT_JUSTIFY_CENTER
      );
      drawDFTextValue(
        dc,
        scr_width / 4,
        scr_width / 4 + fieldNameFontHeight,
        1
      );

      dc.drawText(
        scr_width - scr_width / 4,
        scr_width / 4,
        fieldNameFont,
        fieldNames[2],
        Graphics.TEXT_JUSTIFY_CENTER
      );
      drawDFTextValue(
        dc,
        scr_width - scr_width / 4,
        scr_width / 4 + fieldNameFontHeight,
        2
      );
      dc.drawText(
        scr_width / 4,
        scr_width / 2 + gap,
        fieldNameFont,
        fieldNames[3],
        Graphics.TEXT_JUSTIFY_CENTER
      );
      drawDFTextValue(
        dc,
        scr_width / 4,
        scr_width / 2 + gap + fieldNameFontHeight,
        3
      );

      dc.drawText(
        scr_width - scr_width / 4,
        scr_width / 2 + gap,
        fieldNameFont,
        fieldNames[4],
        Graphics.TEXT_JUSTIFY_CENTER
      );
      drawDFTextValue(
        dc,
        scr_width - scr_width / 4,
        scr_width / 2 + gap + fieldNameFontHeight,
        4
      );

      dc.drawText(
        scr_width / 2,
        scr_width - (fieldValueFontHeight + fieldNameFontHeight),
        fieldNameFont,
        fieldNames[5],
        Graphics.TEXT_JUSTIFY_CENTER
      );
      drawDFTextValue(dc, scr_width / 2, scr_width - fieldValueFontHeight, 5);
    } else {
      fieldNameFont = Graphics.FONT_TINY;
      if (eucData.alternativeFont == true && eucData.limitedMemory == false) {
        fieldValueFont = WatchUi.loadResource(Rez.Fonts.Rajdhani);
        System.println("altfont");
      } else {
        fieldValueFont = Graphics.FONT_NUMBER_MILD;
      }
      fieldNameFontHeight = Graphics.getFontHeight(fieldNameFont);
      fieldValueFontHeight = Graphics.getFontHeight(fieldValueFont);
      gap = dc.getWidth() / 20;
      if (eucData.drawLines) {
        dc.setPenWidth(2);
        dc.setColor(eucData.linesColor, Graphics.COLOR_BLACK);

        dc.drawLine(
          scr_width / 2,
          3 * gap + (fieldNameFontHeight + fieldValueFontHeight),
          scr_width / 2,
          scr_width / 2 + 2 * gap
        );
      }
      if (eucData.paired == true) {
        dc.setColor(eucData.txtColor, Graphics.COLOR_TRANSPARENT);
      } else {
        dc.setColor(eucData.txtColor_unpr, Graphics.COLOR_TRANSPARENT);
      }

      dc.drawText(
        scr_width / 2,
        gap,
        fieldNameFont,
        fieldNames[0],
        Graphics.TEXT_JUSTIFY_CENTER
      );
      drawDFTextValue(dc, scr_width / 2, gap + fieldNameFontHeight, 0);

      dc.drawText(
        scr_width / 4,
        scr_width / 3,
        fieldNameFont,
        fieldNames[1],
        Graphics.TEXT_JUSTIFY_CENTER
      );
      drawDFTextValue(
        dc,
        scr_width / 4,
        scr_width / 3 + fieldNameFontHeight,
        1
      );

      dc.drawText(
        scr_width - scr_width / 4,
        scr_width / 3,
        fieldNameFont,
        fieldNames[2],
        Graphics.TEXT_JUSTIFY_CENTER
      );
      drawDFTextValue(
        dc,
        scr_width - scr_width / 4,
        scr_width / 3 + fieldNameFontHeight,
        2
      );

      dc.drawText(
        scr_width / 2,
        scr_width / 2 + 4 * gap,
        fieldNameFont,
        fieldNames[3],
        Graphics.TEXT_JUSTIFY_CENTER
      );
      drawDFTextValue(
        dc,
        scr_width / 2,
        scr_width / 2 + (4 * gap + fieldNameFontHeight),
        3
      );
    }

    if (!EUCAlarms.alarmType.equals("none")) {
      var textAlert = "!! Alarm: " + EUCAlarms.alarmType + " !!";
      dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
      dc.fillRectangle(
        0,
        scr_width / 2 - Graphics.getFontHeight(Graphics.FONT_SMALL) / 2,
        scr_width,
        Graphics.getFontHeight(Graphics.FONT_SMALL)
      );
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
      dc.drawLine(
        0,
        scr_width / 2 - Graphics.getFontHeight(Graphics.FONT_SMALL) / 2 - 1,
        scr_width,
        scr_width / 2 - Graphics.getFontHeight(Graphics.FONT_SMALL) / 2 - 1
      );
      dc.drawLine(
        0,
        scr_width / 2 + Graphics.getFontHeight(Graphics.FONT_SMALL) / 2 + 1,
        scr_width,
        scr_width / 2 + Graphics.getFontHeight(Graphics.FONT_SMALL) / 2 + 1
      );
      dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
      dc.drawText(
        scr_width / 2,
        scr_width / 2 - Graphics.getFontHeight(Graphics.FONT_SMALL) / 2,
        Graphics.FONT_SMALL,
        textAlert,
        Graphics.TEXT_JUSTIFY_CENTER
      );
    }

    if (
      eucData.displayNorth == true &&
      Toybox.Position.getInfo().accuracy >= 2
    ) {
      renderNorthOnUI(scr_width, dc);
    }
    if (
      eucData.displayWind == true &&
      Toybox.Position.getInfo().accuracy >= 2
    ) {
      renderWindOnUI(scr_width, dc);
    }
  }
  function drawDFTextValue(dc, xpos, ypos, valueID) {
    var font;
    if (fieldNames[valueID].equals("WX COND") == true && weatherChar != null) {
      font = weatherFont;
      // ypos = ypos * 1.2;
      fieldValues[valueID] = weatherChar[fieldValues[valueID]]
        .toChar()
        .toString();
      dc.drawText(
        xpos,
        ypos + Graphics.getFontHeight(weatherFont) / 4,
        font,
        fieldValues[valueID],
        Graphics.TEXT_JUSTIFY_CENTER
      );
    } else {
      font = fieldValueFont;
      dc.drawText(
        xpos,
        ypos,
        font,
        fieldValues[valueID],
        Graphics.TEXT_JUSTIFY_CENTER
      );
    }
  }
  function renderNorthOnUI(screenDiam, dc) {
    var rawNorth = Toybox.Position.getInfo().heading;
    if (rawNorth != null) {
      var north = rawNorth * -57.2958;
      var x1 = getXY(screenDiam, 0, screenDiam / 2 - 1, north, 1);
      var x2 = getXY(
        screenDiam,
        0,
        screenDiam / 2 - screenDiam / 30,
        north - screenDiam / 150,
        1
      );
      var x3 = getXY(
        screenDiam,
        0,
        screenDiam / 2 - screenDiam / 30,
        north + screenDiam / 150,
        1
      );
      var pts = [x1, x2, x3];
      dc.setColor(0xd53420, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(pts);
    }
  }

  function renderWindOnUI(screenDiam, dc) {
    var rawNorth = Toybox.Position.getInfo().heading;
    var windBearing = null;
    if (current_weather != null && current_weather.windBearing != null) {
      windBearing = current_weather.windBearing;
    } else {
      if (hourly_weather != null && hourly_weather.windBearing != null) {
        windBearing = hourly_weather.windBearing;
      }
    }

    if (rawNorth != null && windBearing != null) {
      var north = rawNorth * -57.2958;
      var wind = windBearing + north;
      var x1 = getXY(screenDiam, 0, screenDiam / 2 - 1, wind, 1);
      var x2 = getXY(
        screenDiam,
        0,
        screenDiam / 2 - screenDiam / 30,
        wind - screenDiam / 150,
        1
      );
      var x3 = getXY(
        screenDiam,
        0,
        screenDiam / 2 - screenDiam / 30,
        wind + screenDiam / 150,
        1
      );
      var pts = [x1, x2, x3];
      dc.setColor(0x0077b6, Graphics.COLOR_TRANSPARENT);
      dc.fillPolygon(pts);
    }
  }

  function enableGPS() {
    Position.enableLocationEvents(
      Position.LOCATION_CONTINUOUS,
      method(:onPosition)
    );
    eucData.GPS_requested = true;
  }
  function onPosition(info as Info) as Void {}

  function getHR() {
    if (!hasHr) {
      return null;
    }
    var hr = "--";
    var newHr = Activity.getActivityInfo().currentHeartRate;
    if (newHr == null) {
      var hrh = ActivityMonitor.getHeartRateHistory(1, true);
      if (hrh != null) {
        var hrs = hrh.next();
        if (
          hrs != null &&
          hrs.heartRate != null &&
          hrs.heartRate != ActivityMonitor.INVALID_HR_SAMPLE
        ) {
          newHr = hrs.heartRate;
        }
      }
    }
    if (newHr != null) {
      hr = newHr.toNumber();
    }
    return hr;
  }

  function getWXFromHourly(hourly) {
    if (hourly == null) {
      return null;
    }
    var timeNow = Time.now();
    var now = Gregorian.info(timeNow, Time.FORMAT_SHORT);
    for (var i = 0; i < hourly.size(); i++) {
      var diffential = hourly[i].forecastTime.subtract(timeNow);

      if (diffential.value() <= 3600) {
        return hourly[i];
      }
    }

    return null;
  }
  // weather font char id (https://github.com/Weatherfonts/weather-font)
  function initWeatherChar() {
    weatherChar = [
      61453, //0
      61442,
      61459,
      61466,
      61467,
      61457,
      61469,
      61463,
      61460,
      61473,
      61461, //10
      61449,
      61454,
      61466,
      61466,
      61465,
      61467,
      61467,
      61463,
      61463,
      61459, //20
      61463,
      61442,
      61452,
      61467,
      61467,
      61467,
      61449,
      61454,
      61460,
      61539, //30
      61468,
      61526,
      61538,
      61558,
      61570,
      61457,
      61570,
      61640,
      61539,
      61453, //40
      61555,
      61470,
      61450,
      61446,
      61466,
      61467,
      61463,
      61467,
      61463,
      61463, //50
      61463,
      61442,
      61563,
    ];
  }
}
