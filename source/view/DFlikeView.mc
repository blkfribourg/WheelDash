import Toybox.Graphics;
import Toybox.WatchUi;
using Toybox.Timer;
using Toybox.ActivityMonitor;
import Toybox.Weather;
using Toybox.System;
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
  hidden var maxTemperature = null;
  hidden var fieldNames = null;
  hidden var fieldValues = null;

  // Set field names once to optimize ?
  /* TODO : COMM_GET_STATS							= 128
  request  case COMM_GET_STATS: {
        mTimeoutStats = 0;
        STAT_VALUES values;
        uint32_t mask = vb.vbPopFrontUint32();
        if (mask & ((uint32_t)1 << 0)) { values.speed_avg = vb.vbPopFrontDouble32Auto(); }
        if (mask & ((uint32_t)1 << 1)) { values.speed_max = vb.vbPopFrontDouble32Auto(); }
        if (mask & ((uint32_t)1 << 2)) { values.power_avg = vb.vbPopFrontDouble32Auto(); }
        if (mask & ((uint32_t)1 << 3)) { values.power_max = vb.vbPopFrontDouble32Auto(); }
        if (mask & ((uint32_t)1 << 4)) { values.current_avg = vb.vbPopFrontDouble32Auto(); }
        if (mask & ((uint32_t)1 << 5)) { values.current_max = vb.vbPopFrontDouble32Auto(); }
        if (mask & ((uint32_t)1 << 6)) { values.temp_mos_avg = vb.vbPopFrontDouble32Auto(); }
        if (mask & ((uint32_t)1 << 7)) { values.temp_mos_max = vb.vbPopFrontDouble32Auto(); }
        if (mask & ((uint32_t)1 << 8)) { values.temp_motor_avg = vb.vbPopFrontDouble32Auto(); }
        if (mask & ((uint32_t)1 << 9)) { values.temp_motor_max = vb.vbPopFrontDouble32Auto(); }
        if (mask & ((uint32_t)1 << 10)) { values.count_time = vb.vbPopFrontDouble32Auto(); }
        emit statsRx(values, mask);
    } break;
*/
  function initialize() {
    View.initialize();
    hasHr = ActivityMonitor has :getHeartRateHistory;
    hasWX = Weather has :getCurrentConditions;
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
      fieldIDs.slice(0, fieldNB - 1).indexOf(21) != -1 ||
      fieldIDs.slice(0, fieldNB - 1).indexOf(22) != -1 ||
      eucData.displayNorth == true ||
      eucData.displayWind == true
    ) {
      reqPos = true;
      enableGPS();
    }

    if (
      fieldIDs.slice(0, fieldNB - 1).indexOf(26) != -1 ||
      fieldIDs.slice(0, fieldNB - 1).indexOf(27) != -1 ||
      fieldIDs.slice(0, fieldNB - 1).indexOf(28) != -1 ||
      fieldIDs.slice(0, fieldNB - 1).indexOf(29) != -1 ||
      fieldIDs.slice(0, fieldNB - 1).indexOf(30) != -1 ||
      fieldIDs.slice(0, fieldNB - 1).indexOf(31) != -1
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
      current_weather = Weather.getCurrentConditions();
    }

    for (var field_id = 0; field_id < fieldNB; field_id++) {
      if (fieldIDs[field_id] == 0) {
        fieldNames[field_id] = "SPEED";
        fieldValues[field_id] = valueRound(eucData.correctedSpeed, "%.1f");
      }
      if (fieldIDs[field_id] == 1) {
        fieldNames[field_id] = "VOLTAGE";
        fieldValues[field_id] = valueRound(eucData.voltage, "%.1f");
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
        fieldValues[field_id] = valueRound(eucData.minVoltage, "%.1f");
      }
      if (fieldIDs[field_id] == 13) {
        fieldNames[field_id] = "MAX VOLT";
        fieldValues[field_id] = valueRound(eucData.maxVoltage, "%.1f");
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
          fieldValues[field_id] = valueRound(current_position.speed, "%.1f");
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
          "%.1f"
        );
      }
      if (fieldIDs[field_id] == 25) {
        fieldNames[field_id] = "WTCH USG";
        fieldValues[field_id] = valueRound(eucData.watchBatteryUsage, "%.1f");
      }
      //WATCH WEATHER
      if (fieldIDs[field_id] == 26) {
        fieldNames[field_id] = "WX TEMP";
        if (current_weather != null) {
          fieldValues[field_id] = valueRound(
            current_weather.temperature,
            "%.1f"
          );
        } else {
          fieldValues[field_id] = "--";
        }
      }
      if (fieldIDs[field_id] == 27) {
        fieldNames[field_id] = "RF TEMP";
        if (current_weather != null) {
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
        if (current_weather != null) {
          fieldValues[field_id] = current_weather.condition;
        } else {
          fieldValues[field_id] = "--";
        }
      }
      if (fieldIDs[field_id] == 29) {
        fieldNames[field_id] = "RAIN";
        if (current_weather != null) {
          fieldValues[field_id] = valueRound(
            current_weather.precipitationChance,
            "%.1f"
          );
        } else {
          fieldValues[field_id] = "--";
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
          fieldValues[field_id] = "--";
        }
      }
      if (fieldIDs[field_id] == 31) {
        fieldNames[field_id] = "WIND SPD";
        if (current_weather != null) {
          fieldValues[field_id] = valueRound(current_weather.windSpeed, "%.1f");
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
    var scr_height = dc.getHeight();
    var scr_width = dc.getWidth();
    var fieldNameFont;
    var fieldValueFont;
    var fieldNameFontHeight;
    var fieldValueFontHeight;
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
    dc.clear();
    if (fieldNB == 6) {
      var paddingCorrection = 0.7;
      fieldNameFont = Graphics.FONT_XTINY;
      if (eucData.alternativeFont == true) {
        fieldValueFont = WatchUi.loadResource(Rez.Fonts.Rajdhani);
      } else {
        fieldValueFont = Graphics.FONT_SYSTEM_NUMBER_MILD;
      }

      fieldNameFontHeight =
        Graphics.getFontHeight(fieldNameFont) * paddingCorrection;
      fieldValueFontHeight =
        Graphics.getFontHeight(fieldValueFont) * (paddingCorrection + 0.2);
      if (scr_width < 260) {
        gap = dc.getWidth() / 50;
        fieldNameFontHeight = fieldNameFontHeight - 4;
      } else {
        gap = dc.getWidth() / 40;
      }
      if (eucData.drawLines) {
        dc.setPenWidth(2);
        dc.setColor(eucData.linesColor, Graphics.COLOR_BLACK);
        dc.drawLine(gap, scr_height / 2, scr_width - gap, scr_height / 2);
        dc.drawLine(
          scr_width / 2,
          2 * gap + (fieldNameFontHeight + fieldValueFontHeight),
          scr_width / 2,
          scr_height / 2 - 2 * gap
        );
        dc.drawLine(
          scr_width / 2,
          scr_height / 2 + 2 * gap,
          scr_width / 2,
          scr_height - 2 * gap - (fieldNameFontHeight + fieldValueFontHeight)
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
      dc.drawText(
        scr_width / 2,
        gap + fieldNameFontHeight,
        fieldValueFont,
        fieldValues[0],
        Graphics.TEXT_JUSTIFY_CENTER
      );

      dc.drawText(
        scr_width / 4,
        scr_height / 4,
        fieldNameFont,
        fieldNames[1],
        Graphics.TEXT_JUSTIFY_CENTER
      );
      dc.drawText(
        scr_width / 4,
        scr_height / 4 + fieldNameFontHeight,
        fieldValueFont,
        fieldValues[1],
        Graphics.TEXT_JUSTIFY_CENTER
      );

      dc.drawText(
        scr_width - scr_width / 4,
        scr_height / 4,
        fieldNameFont,
        fieldNames[2],
        Graphics.TEXT_JUSTIFY_CENTER
      );
      dc.drawText(
        scr_width - scr_width / 4,
        scr_height / 4 + fieldNameFontHeight,
        fieldValueFont,
        fieldValues[2],
        Graphics.TEXT_JUSTIFY_CENTER
      );

      dc.drawText(
        scr_width / 4,
        scr_height / 2 + gap,
        fieldNameFont,
        fieldNames[3],
        Graphics.TEXT_JUSTIFY_CENTER
      );
      dc.drawText(
        scr_width / 4,
        scr_height / 2 + gap + fieldNameFontHeight,
        fieldValueFont,
        fieldValues[3],
        Graphics.TEXT_JUSTIFY_CENTER
      );

      dc.drawText(
        scr_width - scr_width / 4,
        scr_height / 2 + gap,
        fieldNameFont,
        fieldNames[4],
        Graphics.TEXT_JUSTIFY_CENTER
      );
      dc.drawText(
        scr_width - scr_width / 4,
        scr_height / 2 + gap + fieldNameFontHeight,
        fieldValueFont,
        fieldValues[4],
        Graphics.TEXT_JUSTIFY_CENTER
      );

      dc.drawText(
        scr_width / 2,
        scr_height / 2 + 3 * gap + fieldValueFontHeight,
        fieldNameFont,
        fieldNames[5],
        Graphics.TEXT_JUSTIFY_CENTER
      );

      dc.drawText(
        scr_width / 2,
        scr_height / 2 + 3 * gap + (fieldNameFontHeight + fieldValueFontHeight),
        fieldValueFont,
        fieldValues[5],
        Graphics.TEXT_JUSTIFY_CENTER
      );
      /*
    if (displayingAlert == true && displayAlertTimer > 0) {
      dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
      dc.fillRectangle(
        0,
        dc.getWidth() / 2 - Graphics.getFontHeight(Graphics.FONT_SMALL) / 2,
        dc.getWidth(),
        Graphics.getFontHeight(Graphics.FONT_SMALL)
      );
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
      dc.drawLine(
        0,
        dc.getHeight() / 2 -
          Graphics.getFontHeight(Graphics.FONT_SMALL) / 2 -
          1,
        dc.getWidth(),
        dc.getHeight() / 2 - Graphics.getFontHeight(Graphics.FONT_SMALL) / 2 - 1
      );
      dc.drawLine(
        0,
        dc.getHeight() / 2 +
          Graphics.getFontHeight(Graphics.FONT_SMALL) / 2 +
          1,
        dc.getWidth(),
        dc.getHeight() / 2 + Graphics.getFontHeight(Graphics.FONT_SMALL) / 2 + 1
      );
      dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
      dc.drawText(
        dc.getWidth() / 2,
        dc.getHeight() / 2 - Graphics.getFontHeight(Graphics.FONT_SMALL) / 2,
        Graphics.FONT_SMALL,
        textAlert,
        Graphics.TEXT_JUSTIFY_CENTER
      );
    }*/
    } else {
      fieldNameFont = Graphics.FONT_TINY;
      if (eucData.alternativeFont == true) {
        fieldValueFont = WatchUi.loadResource(Rez.Fonts.Rajdhani);
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
          scr_height / 2 + 2 * gap
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
      dc.drawText(
        scr_width / 2,
        gap + fieldNameFontHeight,
        fieldValueFont,
        fieldValues[0],
        Graphics.TEXT_JUSTIFY_CENTER
      );

      dc.drawText(
        scr_width / 4,
        scr_height / 3,
        fieldNameFont,
        fieldNames[1],
        Graphics.TEXT_JUSTIFY_CENTER
      );
      dc.drawText(
        scr_width / 4,
        scr_height / 3 + fieldNameFontHeight,
        fieldValueFont,
        fieldValues[1],
        Graphics.TEXT_JUSTIFY_CENTER
      );

      dc.drawText(
        scr_width - scr_width / 4,
        scr_height / 3,
        fieldNameFont,
        fieldNames[2],
        Graphics.TEXT_JUSTIFY_CENTER
      );
      dc.drawText(
        scr_width - scr_width / 4,
        scr_height / 3 + fieldNameFontHeight,
        fieldValueFont,
        fieldValues[2],
        Graphics.TEXT_JUSTIFY_CENTER
      );

      dc.drawText(
        scr_width / 2,
        scr_height / 2 + 4 * gap,
        fieldNameFont,
        fieldNames[3],
        Graphics.TEXT_JUSTIFY_CENTER
      );
      dc.drawText(
        scr_width / 2,
        scr_height / 2 + (4 * gap + fieldNameFontHeight),
        fieldValueFont,
        fieldValues[3],
        Graphics.TEXT_JUSTIFY_CENTER
      );
    }

    if (!EUCAlarms.alarmType.equals("none")) {
      var textAlert = "!! Alarm: " + EUCAlarms.alarmType + " !!";
      dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
      dc.fillRectangle(
        0,
        dc.getWidth() / 2 - Graphics.getFontHeight(Graphics.FONT_SMALL) / 2,
        dc.getWidth(),
        Graphics.getFontHeight(Graphics.FONT_SMALL)
      );
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
      dc.drawLine(
        0,
        dc.getHeight() / 2 -
          Graphics.getFontHeight(Graphics.FONT_SMALL) / 2 -
          1,
        dc.getWidth(),
        dc.getHeight() / 2 - Graphics.getFontHeight(Graphics.FONT_SMALL) / 2 - 1
      );
      dc.drawLine(
        0,
        dc.getHeight() / 2 +
          Graphics.getFontHeight(Graphics.FONT_SMALL) / 2 +
          1,
        dc.getWidth(),
        dc.getHeight() / 2 + Graphics.getFontHeight(Graphics.FONT_SMALL) / 2 + 1
      );
      dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
      dc.drawText(
        dc.getWidth() / 2,
        dc.getHeight() / 2 - Graphics.getFontHeight(Graphics.FONT_SMALL) / 2,
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
      renderWindnUI(scr_width, dc);
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

  function renderWindnUI(screenDiam, dc) {
    var rawNorth = Toybox.Position.getInfo().heading;
    if (current_weather != null) {
      var windBearing = current_weather.windBearing;
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
  }
  function enableGPS() {
    Position.enableLocationEvents(
      Position.LOCATION_CONTINUOUS,
      method(:onPosition)
    );
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
}
