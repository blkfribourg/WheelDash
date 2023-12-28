import Toybox.System;
import Toybox.WatchUi;
import Toybox.Lang;
class ActionButton {
  var eucDict;
  var lightToggleIndex = 0;

  var recordActivityButton;
  var cycleLightButton;
  var beepButton;
  var queue;
  var delay;
  var queueRequired;
  function setEUCDict() {
    eucDict = getEUCSettingsDict();
  }
  function triggerAction(bleDelegate, keyNumber, _mainDelegate, _queue) {
    if (eucData.paired == true) {
      queueRequired = false;
      queue = _queue;
      if (recordActivityButton == keyNumber) {
        _mainDelegate.goToActivityView();
      }
      //if (bleDelegate != null && eucData.paired == true) {
      if (cycleLightButton == keyNumber) {
        queueRequired = true;
        // Action = cycle light modes
        if (eucData.wheelBrand == 0) {
          // gotway/begode
          queue.add(
            [
              bleDelegate.getChar(),
              queue.C_WRITENR,
              string_to_byte_array(
                eucDict.dictLightsMode.values()[lightToggleIndex] as String
              ),
            ],
            bleDelegate.getPMService()
          );

          lightToggleIndex = lightToggleIndex + 1;
          if (lightToggleIndex > 2) {
            lightToggleIndex = 0;
          }
        }
        if (eucData.wheelBrand == 1) {
          //System.println(eucDict.dictLightsMode.values()[lightToggleIndex]);
          queue.add(
            [
              bleDelegate.getChar(),
              queue.C_WRITENR,
              string_to_byte_array(
                eucDict.dictLightsMode.values()[lightToggleIndex] as String
              ),
            ],
            bleDelegate.getPMService()
          );
          lightToggleIndex = lightToggleIndex + 1;
          if (lightToggleIndex > 1) {
            lightToggleIndex = 0;
          }
        }
        if (eucData.wheelBrand == 2 || eucData.wheelBrand == 3) {
          var data = [
            0xaa, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x14, 0x5a, 0x5a,
          ]b;
          data[2] =
            eucDict.dictLightsMode.values()[lightToggleIndex].toNumber() + 0x12;
          data[3] = 0x01;
          data[16] = 0x73;
          queue.add(
            [bleDelegate.getChar(), queue.C_WRITENR, data],
            bleDelegate.getPMService()
          );
          lightToggleIndex = lightToggleIndex + 1;
          if (lightToggleIndex > 1) {
            lightToggleIndex = 0;
          }
        }
        //Inmotion
        if (eucData.wheelBrand == 4) {
          var data = [0xaa, 0xaa, 0x14, 0x03, 0x60, 0x40, 0x00, 0x37]b;
          lightToggleIndex = lightToggleIndex + 1;
          if (lightToggleIndex > 1) {
            lightToggleIndex = 0;
          }
          data[6] = lightToggleIndex;
          data[7] = data[7] - lightToggleIndex;
          queue.add(
            [bleDelegate.getChar(), queue.C_WRITENR, data],
            bleDelegate.getPMService()
          );

          data = [0xaa, 0xaa, 0x14, 0x01, 0x04, 0x11]b;
          queue.add(
            [bleDelegate.getChar(), queue.C_WRITENR, data],
            bleDelegate.getPMService()
          );
        }
      }
      if (beepButton == keyNumber) {
        queueRequired = true;
        // Action = beep beep
        if (eucData.wheelBrand == 0 || eucData.wheelBrand == 1) {
          queue.add(
            [
              bleDelegate.getChar(),
              queue.C_WRITENR,
              string_to_byte_array("b" as String),
            ],
            bleDelegate.getPMService()
          );
        }
        if (eucData.wheelBrand == 2 || eucData.wheelBrand == 3) {
          var data = [
            0xaa, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x88, 0x14, 0x5a, 0x5a,
          ]b;
          queue.add(
            [bleDelegate.getChar(), queue.C_WRITENR, data],
            bleDelegate.getPMService()
          );
        }
        if (eucData.wheelBrand == 4) {
          var data = [0xaa, 0xaa, 0x14, 0x04, 0x60, 0x41, 0x18, 0x01, 0x28]b;

          queue.add(
            [bleDelegate.getChar(), queue.C_WRITENR, data],
            bleDelegate.getPMService()
          );

          data = [0xaa, 0xaa, 0x14, 0x01, 0x04, 0x11]b;
          queue.add(
            [bleDelegate.getChar(), queue.C_WRITENR, data],
            bleDelegate.getPMService()
          );
        }
      }
      //}
      if (queueRequired == true) {
        queue.delayTimer.start(method(:timerCallback), delay, true);
      }
    }
  }

  function timerCallback() {
    queue.run();
  }
}
