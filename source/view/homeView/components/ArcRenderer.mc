import Toybox.WatchUi;
import Toybox.Application.Properties;
import Toybox.Application.Storage;
import Toybox.System;

class ArcRenderer extends WatchUi.Drawable {
  private var mMainColor,
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
    var backgroundColor = 0x333333;
    dc.setPenWidth(mArcSize);

    var foregroundColor;

    // Calculating position of the foreground
    // About this part... Oh boy, don't even try to understand what is here,
    // because I just don't care about readability here, bc if it works - don't
    // touch it, and i have a spent a lot of nerves while trying to code this
    // crap (ggoraa comment)

    dc.setColor(backgroundColor, 0x000000);
    dc.drawArc(
      mXCenterPosition,
      mYCenterPosition,
      mArcRadius,
      Graphics.ARC_CLOCKWISE,
      mStartDegree,
      mEndDegree
    );

    switch (mArcType) {
      case :speedArc: {
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
            foregroundColor = mMainColor;
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
          var percentage = currentValue.toFloat() / maxValue.toFloat();
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
