import Toybox.System;
import Toybox.WatchUi;
import Toybox.Lang;
class ActionButton {
  var eucDict;
  var lightToggleIndex = 0;
  //var lockStatus = 0;
  var recordActivityButton;
  var cycleLightButton;
  var beepButton;
  //var lockButton;
  var queue;
  var queueRequired;
  function setEUCDict() {
    eucDict = getEUCSettingsDict();
  }
  function triggerAction(bleDelegate, keyNumber, _mainDelegate, _queue) {
    if (eucData.paired == true) {
      queueRequired = false;
      queue = _queue;
      /*
      if (lockButton == keyNumber) {
        //inmotion
        if (eucData.wheelBrand == 4) {
          var data = [0xaa, 0xaa, 0x14, 0x04, 0x60, 0x31, 0x00, 0x00]b; // Thanks Seba ;)

          lockStatus = lockStatus + 1;
          if (lockStatus > 1) {
            lockStatus = 0;
          }

          data[6] = lockStatus;
          data[7] = xorChkSum(data.slice(0, data.size() - 1));
         
          queue.flush();
          queue.add(
            [bleDelegate.getCharW(), queue.C_WRITENR, data],
            bleDelegate.getPMService()
          );
        
        }
      }
      */
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
          if (eucData.model.equals("V11")) {
            var data = [0xaa, 0xaa, 0x14, 0x03, 0x60, 0x50, 0x00, 0x27]b;
            lightToggleIndex = lightToggleIndex + 1;
            if (lightToggleIndex > 1) {
              lightToggleIndex = 0;
            }
            data[6] = lightToggleIndex;
            data[7] = data[7] - lightToggleIndex;

            queue.flush();
            queue.add(
              [bleDelegate.getCharW(), queue.C_WRITENR, data],
              bleDelegate.getPMService()
            );
          }
          if (eucData.model.equals("V12")) {
            var data = [0xaa, 0xaa, 0x14, 0x04, 0x60, 0x50, 0x00, 0x00, 0x00]b; // Thanks Seba ;)

            lightToggleIndex = lightToggleIndex + 1;
            if (lightToggleIndex > 1) {
              lightToggleIndex = 0;
            }
            /*
            if (lightToggleIndex > 3) {
              lightToggleIndex = 0;
            }
            if (lightToggleIndex == 1) {
              data[6] = 0x01;
              data[7] = 0x00;
            }
            if (lightToggleIndex == 2) {
              data[6] = 0x00;
              data[7] = 0x01;
            }
            if (lightToggleIndex == 3) {
              data[6] = 0x01;
              data[7] = 0x01;
            }
            */
            // For now only high+low beam (Elric request ;))
            data[6] = lightToggleIndex;
            data[7] = lightToggleIndex;
            data[8] = xorChkSum(data.slice(0, data.size() - 1));

            queue.flush();
            queue.add(
              [bleDelegate.getCharW(), queue.C_WRITENR, data],
              bleDelegate.getPMService()
            );
          }
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
          var data = [0xaa, 0xaa, 0x14, 0x04, 0x60, 0x51, 0x18, 0x01, 0x00]b; // Thanks Seba ;)
          if (eucData.imHornSound != 0) {
            data[6] = eucData.imHornSound.format("%02d").toNumberWithBase(16);
          }

          data[8] = xorChkSum(data.slice(0, data.size() - 1));
          queue.flush();
          queue.add(
            [bleDelegate.getCharW(), queue.C_WRITENR, data],
            bleDelegate.getPMService()
          );
        }
      }
      //}
      if (queueRequired == true) {
        queue.delayTimer.start(
          method(:timerCallback),
          eucData.BLECmdDelay,
          false
        );
        if (eucData.wheelBrand == 4) {
          queue.delayTimer.start(
            method(:timerCallback),
            eucData.BLECmdDelay,
            true
          ); //dirty workaround
        }
      }
    }
  }

  function timerCallback() {
    queue.run();
  }
}
