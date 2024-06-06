import Toybox.System;
import Toybox.WatchUi;
import Toybox.Lang;
class ActionButton {
  var eucDict;
  var lightToggleIndex = 0;
  //var lockStatus = 0;
  var recordActivityButton;
  var DFViewButton;
  var cycleLightButton;
  var beepButton;
  //var lockButton;
  var queue;
  var queueRequired;
  function setEUCDict() {
    eucDict = getEUCSettingsDict();
  }
  function triggerAction(bleDelegate, keyNumber, _mainDelegate, _queue) {
    if (DFViewButton == keyNumber && eucData.dfViewOnly == false) {
      _mainDelegate.goToDFView();
    }
    //  ESP32 Horn triggers even if EUCs disconnected
    if (eucData.ESP32HornPaired == true) {
      if (queue == null) {
        queue = _queue;
      }

      if (beepButton == keyNumber) {
        queueRequired = true;

        //System.println("HornButton");
        queue.add(
          [bleDelegate.getHornChar(), queue.C_WRITENR, [0x68]b],
          bleDelegate.getHornService()
        );
      }
    }

    if (eucData.paired == true) {
      queueRequired = false;
      if (queue == null) {
        queue = _queue;
      }
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
        if (eucData.wheelBrand == 4 || eucData.wheelBrand == 5) {
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
        if (eucData.ESP32HornPaired == true && eucData.ESP32Horn == true) {
          //System.println("HornButton");
          queue.add(
            [bleDelegate.getHornChar(), queue.C_WRITENR, [0x68]b],
            bleDelegate.getHornService()
          );
        } else {
          // Action = beep beep
          if (
            eucData.wheelBrand == 0 ||
            (eucData.wheelBrand == 1 && eucData.version < 3)
          ) {
            queue.add(
              [
                bleDelegate.getChar(),
                queue.C_WRITENR,
                string_to_byte_array("b" as String),
              ],
              bleDelegate.getPMService()
            );
          }
          if (eucData.wheelBrand == 1 && eucData.version >= 3) {
            queue.add(
              [
                bleDelegate.getChar(),
                queue.C_WRITENR,
                [
                  0x4c, 0x6b, 0x41, 0x70, 0x0e, 0x00, 0x80, 0x80, 0x80, 0x01,
                  0xca, 0x87, 0xe6, 0x6f,
                ]b,
              ],
              bleDelegate.getPMService()
            );
          }
          if (eucData.wheelBrand == 2 || eucData.wheelBrand == 3) {
            var data = [
              0xaa, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
              0x00, 0x00, 0x00, 0x00, 0x00, 0x88, 0x14, 0x5a, 0x5a,
            ]b;

            if (eucData.KSVoiceMode == true) {
              queue.add(
                [
                  bleDelegate.getChar(),
                  queue.C_WRITENR,
                  [
                    0xaa, 0x55, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x73, 0x14, 0x5a, 0x5a,
                  ]b,
                ],
                bleDelegate.getPMService()
              );
            }
            queue.add(
              [bleDelegate.getChar(), queue.C_WRITENR, data],
              bleDelegate.getPMService()
            );
            if (eucData.KSVoiceMode == true) {
              //deactivate KSVoiceMode let's try 0x02 val
              queue.add(
                [
                  bleDelegate.getChar(),
                  queue.C_WRITENR,
                  [
                    0xaa, 0x55, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x73, 0x14, 0x5a, 0x5a,
                  ]b,
                ],
                bleDelegate.getPMService()
              );
            }
          }
          if (eucData.wheelBrand == 4 || eucData.wheelBrand == 5) {
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
      }
      //}
    }
    if (queueRequired == true) {
      queue.delayTimer.start(method(:timerCallback), eucData.BLECmdDelay, true);
    }
  }

  function timerCallback() {
    queue.run();
  }
}
