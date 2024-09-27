import Toybox.Graphics;
import Toybox.WatchUi;
using Toybox.Timer;

using Toybox.System;

class GarminEUCView extends WatchUi.View {
  private var cDrawables = {};
  function initialize() {
    View.initialize();
  }

  function onLayout(dc as Dc) as Void {
    setLayout(Rez.Layouts.HomeLayout(dc));

    // Label drawables
    cDrawables[:TimeDate] = View.findDrawableById("TimeDate");
    cDrawables[:SpeedNumber] = View.findDrawableById("SpeedNumber");
    cDrawables[:BatteryNumber] = View.findDrawableById("BatteryNumber");
    cDrawables[:TemperatureNumber] = View.findDrawableById("TemperatureNumber");
    cDrawables[:BottomSubtitle] = View.findDrawableById("BottomSubtitle");
    // And arc drawables
    cDrawables[:topArc] = View.findDrawableById("TopArc"); // used for PMW
    cDrawables[:BatteryArc] = View.findDrawableById("BatteryArc");
    cDrawables[:TemperatureArc] = View.findDrawableById("TemperatureArc");
    cDrawables[:RecordingIndicator] =
      View.findDrawableById("RecordingIndicator");
  }

  // Called when this View is brought to the foreground. Restore
  // the state of this View and prepare it to be shown. This includes
  // loading resources into memory.
  function onShow() {
    var CurrentTime = System.getClockTime();
    cDrawables[:TimeDate].setText(
      CurrentTime.hour.format("%d") + ":" + CurrentTime.min.format("%02d")
    );

    cDrawables[:TimeDate].setColor(Graphics.COLOR_WHITE);
  }

  // Update the view
  function onUpdate(dc) {
    // Update label drawables
    cDrawables[:TimeDate].setText(
      // Update time
      System.getClockTime().hour.format("%d") +
        ":" +
        System.getClockTime().min.format("%02d")
    );
    var batteryPercentage = eucData.getBatteryPercentage();

    cDrawables[:BatteryNumber].setText(
      valueRound(batteryPercentage, "%.1f") + "%"
    );
    var tempUnit;
    if (eucData.useFahrenheit == true) {
      tempUnit = "°F";
    } else {
      tempUnit = "°C";
    }
    cDrawables[:TemperatureNumber].setText(
      valueRound(eucData.DisplayedTemperature, "%.1f").toString() + tempUnit
    );
    cDrawables[:BottomSubtitle].setText(diplayStats());

    var speedNumberStr = "";

    if (eucData.mainNumber == 0) {
      var numericVal = "";
      numericVal = eucData.correctedSpeed;
      if (numericVal > 100) {
        speedNumberStr = valueRound(eucData.correctedSpeed, "%d").toString();
      } else {
        speedNumberStr = valueRound(eucData.correctedSpeed, "%.1f").toString();
      }
    }
    if (eucData.mainNumber == 1) {
      var numericVal;
      numericVal = eucData.PWM.abs();
      if (numericVal > 100) {
        speedNumberStr = valueRound(numericVal, "%d").toString();
      } else {
        speedNumberStr = valueRound(numericVal, "%.1f").toString();
      }
    }
    if (eucData.mainNumber == 2) {
      var numericVal;
      numericVal = eucData.getBatteryPercentage();
      if (numericVal > 100) {
        speedNumberStr = valueRound(numericVal, "%d").toString();
      } else {
        speedNumberStr = valueRound(numericVal, "%.1f").toString();
      }
    }
    if (eucData.mainNumber == 3) {
      var numericVal = "";
      numericVal = eucData.GPS_speed;
      if (numericVal == null) {
        numericVal = 0.0;
      }
      if (numericVal > 100) {
        speedNumberStr = valueRound(eucData.GPS_speed, "%d").toString();
      } else {
        speedNumberStr = valueRound(eucData.GPS_speed, "%.1f").toString();
      }
    }
    cDrawables[:SpeedNumber].setText(speedNumberStr);
    //cDrawables[:topArc].setValues(WheelData.currentSpeed.toFloat(), WheelData.speedLimit);
    if (eucData.topBar == 0) {
      cDrawables[:topArc].setValues(eucData.PWM.toFloat(), 100);
    } else {
      cDrawables[:topArc].setValues(
        eucData.correctedSpeed.toFloat(),
        eucData.maxDisplayedSpeed
      );
    }

    cDrawables[:BatteryArc].setValues(batteryPercentage, 100);
    cDrawables[:TemperatureArc].setValues(
      eucData.DisplayedTemperature,
      eucData.maxDisplayedTemperature
    );
    cDrawables[:TimeDate].setColor(Graphics.COLOR_WHITE);
    cDrawables[:SpeedNumber].setColor(Graphics.COLOR_WHITE);
    cDrawables[:BatteryNumber].setColor(Graphics.COLOR_WHITE);
    cDrawables[:TemperatureNumber].setColor(Graphics.COLOR_WHITE);
    cDrawables[:BottomSubtitle].setColor(Graphics.COLOR_WHITE);

    // Call the parent onUpdate function to redraw the layout
    View.onUpdate(dc);
  }

  function diplayStats() {
    //System.println(EUCAlarms.alarmType);
    var rideStatsText = "";
    if (eucData.engoCfgUpdate != null) {
      rideStatsText = "Engo cfg update\n" + eucData.engoCfgUpdate;
    } else {
      if (!eucData.paired) {
        rideStatsText = "EUC Not\nConnected";
      } else {
        if (!EUCAlarms.alarmType.equals("none")) {
          rideStatsText = "!! Alarm: " + EUCAlarms.alarmType + " !!";
        } else {
          if (eucData.variaTargetNb != 0) {
            rideStatsText = "";
          } else {
            if (
              rideStats.statsArray != null &&
              rideStats.statsNumberToDiplay != 0
            ) {
              rideStatsText =
                rideStats.statsArray[rideStats.statsIndexToDiplay];

              rideStats.statsTimer--;
              if (rideStats.statsTimer < 0) {
                rideStats.statsIndexToDiplay++;
                rideStats.statsTimerReset();
                if (
                  rideStats.statsIndexToDiplay >
                  rideStats.statsNumberToDiplay - 1
                ) {
                  rideStats.statsIndexToDiplay = 0;
                }
              }
            }
          }
        }
      }
    }
    //Sanity check, may return null during app initialization
    if (rideStatsText != null) {
      return rideStatsText;
    } else {
      return "";
    }
  }

  // Called when this View is removed from the screen. Save the
  // state of this View here. This includes freeing resources from
  // memory.
  function onHide() as Void {}
}
