import Toybox.WatchUi;
class RecordIndicatorRenderer extends WatchUi.Drawable {
  private var mMainColor;
  private var screenWidth = System.getDeviceSettings().screenWidth;
  private var pause = 1000;
  function initialize(params) {
    Drawable.initialize(params);
    mMainColor = params.get(:mainColor);
  }
  function draw(dc) {
    if (eucData.activityRecording == true) {
      //System.println(pause);
      var foregroundColor;
      if (pause < 0) {
        foregroundColor = 0x000000;
      } else {
        foregroundColor = mMainColor;
      }
      dc.setPenWidth(2);
      dc.setColor(foregroundColor, 0x000000);
      dc.fillCircle(screenWidth / 2, screenWidth * 0.715, screenWidth / 70);
      dc.drawCircle(screenWidth / 2, screenWidth * 0.715, screenWidth / 40);
      // dc.fillPolygon(hornIcon);
      pause = pause - eucData.updateDelay;
      if (pause < -1000) {
        pause = 1000;
      }
    }
  }
}

class HornIndicatorRenderer extends WatchUi.Drawable {
  private var mMainColor;
  private var screenWidth = System.getDeviceSettings().screenWidth;
  function initialize(params) {
    Drawable.initialize(params);
    mMainColor = params.get(:mainColor);
  }
  function draw(dc) {
    if (eucData.ESP32Horn == true) {
      //System.println(pause);
      var foregroundColor;
      if (eucData.ESP32HornPaired == true) {
        foregroundColor = mMainColor;
      } else {
        foregroundColor = 0x545454;
      }
      var oriX = screenWidth * 0.63;
      var oriY = screenWidth * 0.227;
      var w = 0.014;
      var h = 0.024;

      dc.setPenWidth(2);
      dc.setColor(foregroundColor, 0x000000);
      dc.fillRoundedRectangle(oriX, oriY, screenWidth * w, screenWidth * h, 2);
      var polyTriangle = [
        [screenWidth * 0.646, screenWidth * 0.229],
        [(2 * screenWidth) / 3, screenWidth * 0.214],
        [(2 * screenWidth) / 3, screenWidth * 0.26],
        [screenWidth * 0.646, screenWidth * 0.247],
      ];
      dc.fillPolygon(polyTriangle);
      dc.setPenWidth(3);
      dc.drawArc(
        screenWidth * 0.662,
        screenWidth * 0.239,
        screenWidth * 0.02,
        Graphics.ARC_COUNTER_CLOCKWISE,
        -screenWidth / 10,
        screenWidth / 10
      );
      dc.drawArc(
        screenWidth * 0.662,
        screenWidth * 0.239,
        screenWidth * 0.035,
        Graphics.ARC_COUNTER_CLOCKWISE,
        -screenWidth / 10,
        screenWidth / 10
      );
      // dc.drawCircle(screenWidth / 2, screenWidth * 0.715, screenWidth / 40);
      // dc.fillPolygon(hornIcon);
    }
  }
}

class SpeedLimiterRenderer extends WatchUi.Drawable {
  private var mMainColor;
  private var screenWidth = System.getDeviceSettings().screenWidth;
  function initialize(params) {
    Drawable.initialize(params);
    mMainColor = params.get(:mainColor);
  }
  function draw(dc) {
    if (eucData.speedLimit != 0) {
      //System.println(pause);
      var foregroundColor;
      if (eucData.speedLimitOn == true) {
        foregroundColor = mMainColor;
      } else {
        foregroundColor = 0x545454;
      }
      var oriX = screenWidth * 0.28;
      var oriY = screenWidth * 0.2;

      dc.setColor(foregroundColor, Graphics.COLOR_TRANSPARENT);

      dc.drawText(
        oriX,
        oriY,
        Graphics.FONT_XTINY,
        "LIM",
        Graphics.TEXT_JUSTIFY_LEFT
      );
    }

    // dc.drawCircle(screenWidth / 2, screenWidth * 0.715, screenWidth / 40);
    // dc.fillPolygon(hornIcon);
  }
}

class VariaIndicatorRenderer extends WatchUi.Drawable {
  private var maxDistance = 100;
  private var screenWidth = System.getDeviceSettings().screenWidth;
  private var barLength = screenWidth * 0.55;
  private var xStart = screenWidth / 2 - barLength / 2;
  private var yStart = screenWidth * 0.8;
  private var xEnd = screenWidth / 2 + barLength / 2;
  private var yEnd = screenWidth * 0.8;
  private var roadSpace = screenWidth * 0.05;
  private var mMainColor, mDangerColor;
  private var target;

  function initialize(params) {
    Drawable.initialize(params);
    mMainColor = params.get(:mainColor);
    mDangerColor = params.get(:dangerColor);
  }
  function draw(dc) {
    if (target != null) {
      for (var i = 0; i < target.size(); i++) {
        var distance = target[i].range;
        var threat = target[i].threat;
        if (threat != 0 && EUCAlarms.alarmType.equals("none")) {
          dc.setPenWidth(2);
          dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
          dc.drawRoundedRectangle(xStart, yStart, barLength, roadSpace, 10);

          if (distance < maxDistance && distance != 0) {
            var xPos =
              barLength * 0.04 +
              (distance.toFloat() / maxDistance.toFloat()) * (barLength * 0.92);
            //xPos = Math.round(xPos / roadSpace) * roadSpace;
            System.println("drawcars: " + xPos + ";" + yStart);
            System.println("TGNB: " + eucData.variaTargetNb);
            if (threat == 1) {
              dc.setColor(mMainColor, Graphics.COLOR_TRANSPARENT);
            }
            if (threat == 2) {
              dc.setColor(mDangerColor, Graphics.COLOR_TRANSPARENT);
            }
            dc.fillCircle(
              xEnd - xPos,
              yStart + roadSpace / 2.0 - 1,
              roadSpace / 2.0 - roadSpace / 6.0 - 1
            );
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            dc.drawCircle(
              xEnd - xPos,
              yStart + roadSpace / 2.0,
              roadSpace / 2.0 - roadSpace / 6.0
            );
          }
        }
      }
    }
  }

  // dc.drawLine(xEnd, yEnd, xEnd, yEnd - screenWidth * 0.01);
  /* dc.drawLine(
      xEnd,
      yEnd + screenWidth * roadSpace,
      xEnd,
      yEnd + screenWidth * roadSpace + screenWidth * 0.01
    );*/

  function setValues(_radarTarget) {
    target = _radarTarget;
  }
}
