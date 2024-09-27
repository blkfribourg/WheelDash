import Toybox.WatchUi;
import Toybox.Application.Properties;
import Toybox.Application.Storage;
import Toybox.System;

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

class ArcRenderer extends WatchUi.Drawable {
  private var mMainColor,
    mBgColor,
    mRevColor,
    mSecondColor,
    mThirdColor,
    mStartDegree,
    mEndDegree,
    mXCenterPosition,
    mYCenterPosition,
    mArcRadius,
    mArcSize,
    mArcDirection,
    mArcType,
    mDataDrawingDirection;

  var currentValue = 0,
    maxValue = 0;
  private var screenCenterX = System.getDeviceSettings().screenWidth / 2;
  private var screenCenterY = System.getDeviceSettings().screenHeight / 2;

  private var screenHeight = System.getDeviceSettings().screenHeight;
  private var screenWidth = System.getDeviceSettings().screenWidth;

  function initialize(params) {
    Drawable.initialize(params);

    mArcType = params[:arcType];
    mMainColor = params.get(:mainColor);
    mBgColor = params.get(:bgColor);
    mRevColor = params.get(:revColor);
    mSecondColor = params.get(:secondColor);
    if (mArcType != :batteryArc) {
      mThirdColor = params[:thirdColor];
    }
    mStartDegree = params.get(:startDegree);
    mEndDegree = params.get(:endDegree);
    if (params.get(:xCenterPosition) == :center) {
      mXCenterPosition = screenCenterX;
    } else {
      mXCenterPosition = params.get(:xCenterPosition);
    }

    if (params.get(:yCenterPosition) == :center) {
      mYCenterPosition = screenCenterY;
    } else {
      mYCenterPosition = params.get(:yCenterPosition);
    }

    if (params.get(:arcRadius) == :max) {
      mArcRadius = screenWidth / 2;
    } else {
      mArcRadius = params.get(:arcRadius);
    }
    mArcSize = params.get(:arcSize);
    mArcDirection = params[:arcDirection];
    mDataDrawingDirection = params.get(:dataDrawingDirection);
  }

  function draw(dc) {
    dc.setPenWidth(mArcSize);

    var foregroundColor;

    // Calculating position of the foreground
    // About this part... Oh boy, don't even try to understand what is here,
    // because I just don't care about readability here, bc if it works - don't
    // touch it, and i have a spent a lot of nerves while trying to code this
    // crap (ggoraa comment)

    dc.setColor(mBgColor, 0x000000);
    dc.drawArc(
      mXCenterPosition,
      mYCenterPosition,
      mArcRadius,
      Graphics.ARC_CLOCKWISE,
      mStartDegree,
      mEndDegree
    );

    switch (mArcType) {
      case :topArc: {
        if (currentValue != 0.0) {
          if (
            //should move appstorage values elsewhere
            currentValue >= eucData.orangeColoringThreshold &&
            currentValue < eucData.redColoringThreshold
          ) {
            foregroundColor = mSecondColor;
          } else if (currentValue >= eucData.redColoringThreshold) {
            foregroundColor = mThirdColor;
          } else {
            if (currentValue >= 0) {
              foregroundColor = mMainColor;
            } else {
              foregroundColor = mRevColor;
            }
          }
        } else {
          foregroundColor = mMainColor;
        }
        if (eucData.paired == false) {
          foregroundColor = 0x545454;
        }
        dc.setColor(foregroundColor, 0x000000);
        if (currentValue >= maxValue) {
          dc.drawArc(
            mXCenterPosition,
            mYCenterPosition,
            mArcRadius,
            Graphics.ARC_CLOCKWISE,
            mStartDegree,
            mEndDegree
          );
        } else {
          var degreeRange = mStartDegree.abs() + mEndDegree.abs();
          var percentage = currentValue.abs().toFloat() / maxValue.toFloat();
          var preResult = degreeRange * percentage;
          var result = mStartDegree - preResult;
          if (result != mStartDegree) {
            dc.drawArc(
              mXCenterPosition,
              mYCenterPosition,
              mArcRadius,
              mArcDirection,
              mStartDegree,
              result
            );
          }
        }

        break;
      }
      case :batteryArc: {
        // if no sag value :
        var batteryPercentage = eucData.getBatteryPercentage();
        // BatterySag, move elsewhere ?
        if (eucData.lowestBatteryPercentage > batteryPercentage.toNumber()) {
          eucData.lowestBatteryPercentage = batteryPercentage.toNumber();
        }

        if (currentValue >= maxValue) {
          if (eucData.paired == false) {
            foregroundColor = 0x545454;
          } else {
            foregroundColor = mMainColor;
          }

          dc.setColor(foregroundColor, 0x000000);
          dc.drawArc(
            mXCenterPosition,
            mYCenterPosition,
            mArcRadius,
            Graphics.ARC_CLOCKWISE,
            mStartDegree,
            mEndDegree
          );
        } else {
          //System.println(computedPercentageLoadDrop);

          if (eucData.paired == false) {
            foregroundColor = 0x545454;
          } else {
            foregroundColor = mMainColor;
          }
          dc.setColor(foregroundColor, 0x000000);
          // Render green arc
          var degreeRange = mStartDegree - mEndDegree;
          var secondPercentage = currentValue.toFloat() / maxValue.toFloat();
          var secondResult =
            degreeRange - degreeRange * secondPercentage + mEndDegree;
          if (secondResult != mStartDegree) {
            dc.drawArc(
              mXCenterPosition,
              mYCenterPosition,
              mArcRadius,
              mArcDirection,
              mStartDegree,
              secondResult
            );
          }

          if (
            currentValue != 0 &&
            1 - eucData.lowestBatteryPercentage / currentValue >
              eucData.sagThreshold
          ) {
            if (eucData.paired == false) {
              foregroundColor = 0x545454;
            } else {
              foregroundColor = mSecondColor;
            }

            dc.setColor(foregroundColor, 0x000000);
            // Render yellow arc

            var percentage =
              eucData.lowestBatteryPercentage.toFloat() / maxValue.toFloat();
            var result = degreeRange - degreeRange * percentage + mEndDegree;
            if (result != mStartDegree) {
              //draw a line instead of an arc fill :
              dc.setColor(mSecondColor, 0x000000);
              dc.drawArc(
                mXCenterPosition,
                mYCenterPosition,
                mArcRadius,
                mArcDirection,
                mStartDegree,
                result
                //result - 1
              );
            }
          }
        }
        break;
      }
      case :temperatureArc: {
        if (currentValue != 0.0) {
          //System.println(WheelData.temperature.toNumber());
          //System.println(currentValue);
          if (
            currentValue >= 0.75 * eucData.maxDisplayedTemperature &&
            currentValue < 0.8 * eucData.maxDisplayedTemperature
          ) {
            foregroundColor = mSecondColor;
            //System.println("secondColor");
          } else if (currentValue > 0.8 * eucData.maxDisplayedTemperature) {
            foregroundColor = mThirdColor;
            //System.println("thirdColor");
          } else {
            foregroundColor = mMainColor;
            //System.println("mainColor");
          }
        } else {
          foregroundColor = mMainColor;
          //System.println("mainColor");
        }
        if (eucData.paired == false) {
          foregroundColor = 0x545454;
        }
        dc.setColor(foregroundColor, 0x000000);

        if (currentValue >= maxValue) {
          dc.drawArc(
            mXCenterPosition,
            mYCenterPosition,
            mArcRadius,
            Graphics.ARC_CLOCKWISE,
            mStartDegree,
            mEndDegree
          );
        } else {
          var degreeRange = mStartDegree.abs() + mEndDegree.abs();
          var percentage = currentValue.toFloat() / maxValue.toFloat();
          var preResult = degreeRange * percentage;
          var result = preResult + mEndDegree;
          if (result != mEndDegree) {
            dc.drawArc(
              mXCenterPosition,
              mYCenterPosition,
              mArcRadius,
              mArcDirection,
              mEndDegree,
              result
            );
          }
        }
        break;
      }
    }
  }

  function setValues(current, max) {
    currentValue = current;
    maxValue = max;
  }
}
