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
    cDrawables[:SpeedArc] = View.findDrawableById("SpeedDial"); // used for PMW
    cDrawables[:BatteryArc] = View.findDrawableById("BatteryArc");
    cDrawables[:TemperatureArc] = View.findDrawableById("TemperatureArc");
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
    cDrawables[:TemperatureNumber].setText(
      valueRound(eucData.temperature, "%.1f").toString() + "°C"
    );
    cDrawables[:BottomSubtitle].setText(diplayStats());
    /* To implement later
            switch (AppStorage.getSetting("BottomSubtitleData")) {
                case 0: cDrawables[:BottomSubtitle].setText(WheelData.wheelModel); break;
                case 1: cDrawables[:BottomSubtitle].setText(Lang.format("$1$% / $2$%", [WheelData.pwm, WheelData.maxPwm])); break;
                case 2: cDrawables[:BottomSubtitle].setText(Lang.format("$1$ / $2$", [WheelData.averageSpeed, WheelData.topSpeed])); break;
                case 3: cDrawables[:BottomSubtitle].setText(WheelData.rideTime); break;
                case 4: cDrawables[:BottomSubtitle].setText(WheelData.rideDistance.toString()); break;
            }
        */
    cDrawables[:SpeedNumber].setText(
      valueRound(eucData.getCorrectedSpeed(), "%.1f").toString()
    );

    //cDrawables[:SpeedArc].setValues(WheelData.currentSpeed.toFloat(), WheelData.speedLimit);
    cDrawables[:SpeedArc].setValues(eucData.calculatedPWM.toFloat(), 100);
    cDrawables[:BatteryArc].setValues(batteryPercentage, 100);
    cDrawables[:TemperatureArc].setValues(
      eucData.temperature,
      eucData.maxTemperature
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
    var rideStatsText = "";

    if (rideStats.statsArray != null && rideStats.statsNumberToDiplay != 0) {
      rideStatsText = rideStats.statsArray[rideStats.statsIndexToDiplay];
      rideStats.statsTimer--;
      if (rideStats.statsTimer < 0) {
        rideStats.statsIndexToDiplay++;
        rideStats.statsTimerReset();
        if (rideStats.statsIndexToDiplay > rideStats.statsNumberToDiplay - 1) {
          rideStats.statsIndexToDiplay = 0;
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
