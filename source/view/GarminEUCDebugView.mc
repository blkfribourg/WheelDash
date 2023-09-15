import Toybox.Graphics;
import Toybox.WatchUi;
using Toybox.Timer;

using Toybox.System;
class GarminEUCDebugView extends WatchUi.View {
  var BleDelegate;
  function initialize() {
    View.initialize();
  }
  function setBleDelegate(_BleDelegate) {
    BleDelegate = _BleDelegate;
  }

  // Called when this View is brought to the foreground. Restore
  // the state of this View and prepare it to be shown. This includes
  // loading resources into memory.
  function onShow() {}

  // Update the view
  function onUpdate(dc) {
    if (eucData.wheelBrand == 0 || eucData.wheelBrand == 1) {
      var alignAxe = dc.getWidth() / 5;
      var space = dc.getHeight() / 10;
      var yGap = dc.getHeight() / 8;
      var xGap = dc.getWidth() / 12;
      dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
      dc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
      dc.drawRectangle(0, 0, dc.getWidth(), dc.getHeight());
      dc.drawText(
        alignAxe,
        yGap,
        Graphics.FONT_TINY,
        "Spd: " + valueRound(eucData.speed, "%.1f"),
        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
      );
      dc.drawText(
        alignAxe - xGap,
        space + yGap,
        Graphics.FONT_TINY,
        "Vlt: " + valueRound(eucData.voltage, "%.1f"),
        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
      );
      dc.drawText(
        alignAxe - 2 * xGap,
        2 * space + yGap,
        Graphics.FONT_TINY,
        "phC: " + valueRound(eucData.Phcurrent, "%.1f"),
        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
      );
      dc.drawText(
        alignAxe - 2 * xGap,
        3 * space + yGap,
        Graphics.FONT_TINY,
        "temp: " + valueRound(eucData.temperature, "%.1f"),
        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
      );
      dc.drawText(
        alignAxe - 2 * xGap,
        4 * space + yGap,
        Graphics.FONT_TINY,
        "pdlMode: " + eucData.pedalMode,
        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
      );
      dc.drawText(
        alignAxe - 2 * xGap,
        5 * space + yGap,
        Graphics.FONT_TINY,
        "hPWM: " + valueRound(eucData.hPWM, "%.1f"),
        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
      );
      dc.drawText(
        alignAxe - xGap,
        6 * space + yGap,
        Graphics.FONT_TINY,
        "v: " + valueRound(eucData.version, "%.1f"),
        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
      );
      dc.drawText(
        alignAxe,
        7 * space + yGap,
        Graphics.FONT_TINY,
        "dst: " + valueRound(eucData.tripDistance, "%.2f"),
        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
      );
      dc.drawText(
        alignAxe + xGap,
        8 * space + yGap,
        Graphics.FONT_TINY,
        "t.dst: " + valueRound(eucData.totalDistance, "%.1f"),
        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
      );

      dc.drawText(
        dc.getWidth() - 2.6 * alignAxe,
        4 * space + yGap,
        Graphics.FONT_TINY,
        "bat%: " + valueRound(eucData.getBatteryPercentage(), "%.1f"),
        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
      );
      //  valueRound(batteryPercentage, "%.1f");
    }
    if (eucData.wheelBrand == 2 || eucData.wheelBrand == 3) {
      var alignAxe = dc.getWidth() / 5;
      var space = dc.getHeight() / 10;
      var yGap = dc.getHeight() / 8;
      var xGap = dc.getWidth() / 12;
      dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
      dc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
      dc.drawRectangle(0, 0, dc.getWidth(), dc.getHeight());
      dc.drawText(
        alignAxe,
        yGap,
        Graphics.FONT_TINY,
        "Spd: " + valueRound(eucData.speed, "%.1f"),
        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
      );
      dc.drawText(
        alignAxe - xGap,
        space + yGap,
        Graphics.FONT_TINY,
        "Vlt: " + valueRound(eucData.voltage, "%.1f"),
        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
      );
      dc.drawText(
        alignAxe - 2 * xGap,
        2 * space + yGap,
        Graphics.FONT_TINY,
        "Cur: " + valueRound(eucData.current, "%.1f"),
        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
      );
      dc.drawText(
        alignAxe - 2 * xGap,
        3 * space + yGap,
        Graphics.FONT_TINY,
        "temp: " + valueRound(eucData.temperature, "%.1f"),
        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
      );
      dc.drawText(
        alignAxe - 2 * xGap,
        4 * space + yGap,
        Graphics.FONT_TINY,
        "temp2: " + eucData.temperature2,
        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
      );
      dc.drawText(
        alignAxe - 2 * xGap,
        5 * space + yGap,
        Graphics.FONT_TINY,
        "PWM?: " + valueRound(eucData.speedLimit, "%.1f"),
        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
      );
      dc.drawText(
        alignAxe - xGap,
        6 * space + yGap,
        Graphics.FONT_TINY,
        "mode: " + eucData.mode,
        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
      );
      dc.drawText(
        alignAxe,
        7 * space + yGap,
        Graphics.FONT_TINY,
        "dst: " + valueRound(eucData.tripDistance, "%.1f"),
        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
      );
      dc.drawText(
        alignAxe + xGap,
        8 * space + yGap,
        Graphics.FONT_TINY,
        "t.dst: " + valueRound(eucData.totalDistance, "%.1f"),
        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
      );

      dc.drawText(
        dc.getWidth() - 2.6 * alignAxe,
        6 * space + yGap,
        Graphics.FONT_TINY,
        "n:" + eucData.model,
        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
      );
    }
    /*
    if (eucData.wheelBrand == 3) {
      if (BleDelegate != null) {
        var alignAxe = dc.getWidth() / 5;
        var space = dc.getHeight() / 10;
        var yGap = dc.getHeight() / 8;
        var xGap = dc.getWidth() / 12;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawRectangle(0, 0, dc.getWidth(), dc.getHeight());
        dc.drawText(
          alignAxe,
          yGap,
          Graphics.FONT_XTINY,
          BleDelegate.message1,
          Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
        dc.drawText(
          alignAxe - xGap,
          space + yGap,
          Graphics.FONT_XTINY,
          BleDelegate.message2,
          Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
        dc.drawText(
          alignAxe - 2 * xGap,
          2 * space + yGap,
          Graphics.FONT_XTINY,
          BleDelegate.message3,
          Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
        dc.drawText(
          alignAxe - 2 * xGap,
          3 * space + yGap,
          Graphics.FONT_XTINY,
          BleDelegate.message4,
          Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
        dc.drawText(
          alignAxe - 2 * xGap,
          4 * space + yGap,
          Graphics.FONT_XTINY,
          BleDelegate.message5,
          Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
        dc.drawText(
          alignAxe - 2 * xGap,
          5 * space + yGap,
          Graphics.FONT_XTINY,
          BleDelegate.message6,
          Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
        dc.drawText(
          alignAxe - xGap,
          6 * space + yGap,
          Graphics.FONT_XTINY,
          BleDelegate.message7,
          Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
        dc.drawText(
          alignAxe,
          7 * space + yGap,
          Graphics.FONT_XTINY,
          BleDelegate.message8,
          Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
        dc.drawText(
          alignAxe + xGap,
          8 * space + yGap,
          Graphics.FONT_XTINY,
          BleDelegate.message9,
          Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
      }
    }*/
  }
}
