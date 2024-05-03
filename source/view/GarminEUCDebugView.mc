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

  function onShow() {}

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
        "temp: " + valueRound(eucData.DisplayedTemperature, "%.1f"),
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
      dc.drawText(
        dc.getWidth() - 2.7 * alignAxe,
        3 * space + yGap,
        Graphics.FONT_TINY,
        "data/s: " + valueRound(eucData.BLEReadRate, "%.1f"),
        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
      );
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
        "temp: " + valueRound(eucData.DisplayedTemperature, "%.1f"),
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
      dc.drawText(
        dc.getWidth() - 2.7 * alignAxe,
        3 * space + yGap,
        Graphics.FONT_TINY,
        "data/s: " + valueRound(eucData.BLEReadRate, "%.1f"),
        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
      );
    }
    if (eucData.wheelBrand == 4 || eucData.wheelBrand == 5) {
      if (BleDelegate != null) {
        var alignAxe = dc.getWidth() / 5;
        var space = dc.getHeight() / 10;
        var yGap = dc.getHeight() / 8;
        var xGap = dc.getWidth() / 12;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
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
          "bat%: " + valueRound(eucData.getBatteryPercentage(), "%.1f"),
          Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
        dc.drawText(
          alignAxe - 2 * xGap,
          4 * space + yGap,
          Graphics.FONT_TINY,
          "model: " + eucData.model,
          Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
        dc.drawText(
          alignAxe - 2 * xGap,
          5 * space + yGap,
          Graphics.FONT_TINY,
          "PWM: " + valueRound(eucData.hPWM, "%.1f"),
          Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
        dc.drawText(
          alignAxe - xGap,
          6 * space + yGap,
          Graphics.FONT_TINY,
          "data/s: " + valueRound(eucData.BLEReadRate, "%.1f"),
          Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
        dc.drawText(
          alignAxe,
          7 * space + yGap,
          Graphics.FONT_TINY,
          "q_size: " + BleDelegate.queue.queue.size(),
          Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
        dc.drawText(
          dc.getWidth() - 2.6 * alignAxe,
          3 * space + yGap,
          Graphics.FONT_TINY,
          "q_trg: " + BleDelegate.queue.run_id,
          Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
        dc.drawText(
          dc.getWidth() - 2.5 * alignAxe,
          4 * space + yGap,
          Graphics.FONT_TINY,
          "batT1: " + valueRound(eucData.batteryTemp1, "%.1f"),
          Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
        dc.drawText(
          dc.getWidth() - 2.5 * alignAxe,
          5 * space + yGap,
          Graphics.FONT_TINY,
          "batT2: " + valueRound(eucData.batteryTemp2, "%.1f"),
          Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
        dc.drawText(
          dc.getWidth() - 2.9 * alignAxe,
          2 * space + yGap,
          Graphics.FONT_TINY,
          "batTRq: " + BleDelegate.queue.batStatsCounter,
          Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
      }
    }
  }
}
