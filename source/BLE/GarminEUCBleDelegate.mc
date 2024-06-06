using Toybox.System;
using Toybox.BluetoothLowEnergy as Ble;
using Toybox.WatchUi as Ui;
import Toybox.Lang;
using Toybox.Application.Storage;

class eucBLEDelegate extends Ble.BleDelegate {
  var profileManager = null;
  var service = null;
  var char = null;
  var service_w = null;
  var char_w = null;
  var horn_char_w = null;
  var queue;
  var decoder = null;
  var isFirst = false;
  private var profileNb;
  var message1 = "";
  var message2 = "";
  var message3 = "";
  var message4 = "";
  var message5 = "";
  var message6 = "";
  var message7 = "";
  var message8 = "";
  var message9 = "";
  var bleCharReadNb = 0;
  var timeWhenConnected;
  var hornProfileManager = null;
  var EUCDevice = null;
  var hornDevice = null;
  var horn_service = null;
  /*
  var V11Y = [
    0xaa, 0xaa, 0x14, 0x59, 0x84, 0x69, 0x1d, 0x0e, 0x00, 0x00, 0x00, 0x00,
    0x00, 0xe9, 0xff, 0x00, 0x00, 0x1f, 0x01, 0x22,
  ]b;
  
  var frame1 = [
    170, 85, 75, 83, 45, 83, 50, 50, 45, 48, 50, 51, 49, 0, 0, 0, 187, 20, 138,
    90, 90,
  ];

 // Lynx packet
  var frame1 = [
    0xdc, 0x5a, 0x5c, 0x53, 0x39, 0x1b, 0x00, 0x00, 0x06, 0xd0, 0x00, 0x00,
    0x07, 0x70, 0x00, 0x00, 0x00, 0x26, 0x0b, 0xcc,
  ];
  var frame2 = [
    0x0e, 0x08, 0x00, 0x00, 0x00, 0xfa, 0x00, 0xc8, 0x13, 0x8c, 0x00, 0xb4,
    0x00, 0x0b, 0x01, 0x4c, 0x80, 0xc8, 0x00, 0x00,
  ];
  var frame3 = [
    0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x01, 0x00, 0x08, 0x80, 0x80, 0x80,
    0x80, 0x0f, 0xee, 0x0f, 0xee, 0x0f, 0xee, 0x0f,
  ];
  var frame4 = [
    0xee, 0x0f, 0xef, 0x0f, 0xe8, 0x0f, 0xef, 0x0f, 0xef, 0x0f, 0xf0, 0x0f,
    0xf0, 0x0f, 0xf0, 0x0f, 0xea, 0x0f, 0xef, 0x0f,
  ];
  var frame5 = [0xef, 0x0f, 0xef, 0xda, 0xb2, 0x25, 0x18];
  */
  function initialize(pm, _profileNb, q, _decoder) {
    //System.println("init");
    message1 = "initializeBle";
    BleDelegate.initialize();
    profileManager = pm;
    profileNb = _profileNb;
    //char = profileManager.EUC_CHAR;
    queue = q;
    decoder = _decoder;

    Ble.setScanState(Ble.SCAN_STATE_SCANNING);
    isFirst = isFirstConnection();
    isFirst = false;
  }

  function onConnectedStateChanged(device, state) {
    //		view.deviceStatus=state;
    if (state == Ble.CONNECTION_STATE_CONNECTED) {
      if (device.getService(profileManager.EUC_SERVICE) != null) {
        //System.println("EUC connected");
        message3 = "EUC connected";
        service = device.getService(profileManager.EUC_SERVICE);
        var cccd;

        char =
          service != null
            ? service.getCharacteristic(profileManager.EUC_CHAR)
            : null;
        if (service != null && char != null) {
          // If KS -> add init seq to ble queue -------- Addition
          if (eucData.wheelBrand == 2 || eucData.wheelBrand == 3) {
            var reqModel = [
              0xaa, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
              0x00, 0x00, 0x00, 0x00, 0x00, 0x9b, 0x14, 0x5a, 0x5a,
            ]b;

            queue.add(
              [char, queue.C_WRITENR, reqModel],
              profileManager.EUC_SERVICE
            );
          }
          // End of KS addition -------------------------------
          // Inmotion V2 or VESC ---------------------------
          if (eucData.wheelBrand == 4 || eucData.wheelBrand == 5) {
            char_w = service.getCharacteristic(profileManager.EUC_CHAR_W);
            // addition for inmotion v2 request live:
            queue.reqLiveData = [
              char_w,
              queue.C_WRITENR,
              [0xaa, 0xaa, 0x14, 0x01, 0x04, 0x11]b,
            ];

            // inmotion v2 request stats :
            queue.reqStats = [
              char_w,
              queue.C_WRITENR,
              [0xaa, 0xaa, 0x14, 0x01, 0x11, 0x04]b,
            ];
            queue.UUID = profileManager.EUC_SERVICE;
          }

          // End of inmotion V2 or VESC
          cccd = char.getDescriptor(Ble.cccdUuid());
          cccd.requestWrite([0x01, 0x00]b);
          message4 = "characteristic notify enabled";
          eucData.paired = true;
          message3 = "EUC connected";
          eucData.timeWhenConnected = new Time.Moment(Time.now().value());
        } else {
          //System.println("unable to pair EUC");
          message3 = "EUC not connected";
          Ble.unpairDevice(device);
          eucData.paired = false;
        }
      }

      if (hornProfileManager != null && eucData.ESP32Horn == true) {
        if (device.getService(hornProfileManager.WH_SERVICE) != null) {
          //System.println("Horn connected");

          horn_service = device.getService(hornProfileManager.WH_SERVICE);

          horn_char_w =
            horn_service != null
              ? horn_service.getCharacteristic(hornProfileManager.WH_CHAR_W)
              : null;
          if (horn_service != null && horn_char_w != null) {
            message4 = "Horn connected";
            eucData.ESP32HornPaired = true;
          } else {
            Ble.unpairDevice(device);
            eucData.ESP32HornPaired = false;
            message4 = "Horn not connected";
          }
        }
      }
    } else {
      if (hornDevice != null && hornDevice.equals(device)) {
        eucData.ESP32HornPaired = false;
        message4 = "Horn disconnected";
        Ble.unpairDevice(device);
        Ble.setScanState(Ble.SCAN_STATE_SCANNING);
      }
      if (EUCDevice != null && EUCDevice.equals(device)) {
        eucData.paired = false;
        message3 = "EUC disconnected";
        Ble.unpairDevice(device);
        Ble.setScanState(Ble.SCAN_STATE_SCANNING);
      }
      //BLE Disconnected
    }
  }
  function isFirstConnection() {
    // resetting profileScanResult if wheelName changed :
    if (
      !AppStorage.getSetting("wheelName_p1").equals(
        Storage.getValue("profile1Name")
      )
    ) {
      Storage.deleteValue("profile1Sr");
    }
    if (
      !AppStorage.getSetting("wheelName_p2").equals(
        Storage.getValue("profile2Name")
      )
    ) {
      Storage.deleteValue("profile2Sr");
    }
    if (
      !AppStorage.getSetting("wheelName_p3").equals(
        Storage.getValue("profile3Name")
      )
    ) {
      Storage.deleteValue("profile3Sr");
    }

    if (profileNb == 1 && Storage.getValue("profile1Sr") == null) {
      return true;
    } else if (profileNb == 2 && Storage.getValue("profile2Sr") == null) {
      return true;
    } else if (profileNb == 3 && Storage.getValue("profile3Sr") == null) {
      return true;
    } else {
      return false;
    }
  }

  function storeSR(sr) {
    if (profileNb == 1) {
      Storage.setValue("profile1Sr", sr);
      Storage.setValue("profile1Name", AppStorage.getSetting("wheelName_p1"));
    } else if (profileNb == 2) {
      Storage.setValue("profile2Sr", sr);
      Storage.setValue("profile2Name", AppStorage.getSetting("wheelName_p2"));
    } else if (profileNb == 3) {
      Storage.setValue("profile3Sr", sr);
      Storage.setValue("profile3Name", AppStorage.getSetting("wheelName_p3"));
    }
  }
  function loadSR() {
    if (profileNb == 1) {
      return Storage.getValue("profile1Sr");
    } else if (profileNb == 2) {
      return Storage.getValue("profile2Sr");
    } else if (profileNb == 3) {
      return Storage.getValue("profile3Sr");
    } else {
      return false;
    }
  }
  //! @param scanResults An iterator of new scan results
  function onScanResults(scanResults as Ble.Iterator) {
    if (isFirst) {
      var wheelFound = false;
      for (
        var result = scanResults.next();
        result != null;
        result = scanResults.next()
      ) {
        if (result instanceof Ble.ScanResult) {
          System.println(result.getDeviceName());
          if (eucData.wheelBrand == 0 || eucData.wheelBrand == 1) {
            // Begode/Leaperkim
            wheelFound = contains(
              result.getServiceUuids(),
              profileManager.EUC_SERVICE,
              result
            );
          }
          if (
            eucData.wheelBrand == 3 &&
            profileManager.OLD_KS_ADV_SERVICE != null
          ) {
            wheelFound = contains(
              result.getServiceUuids(),
              profileManager.OLD_KS_ADV_SERVICE,
              result
            );
          }
          if (eucData.wheelBrand == 2) {
            var advName = result.getDeviceName();
            if (advName != null) {
              if (advName.substring(0, 3).equals("KSN")) {
                wheelFound = true;
              }
            }
          }
          if (eucData.wheelBrand == 4 || eucData.wheelBrand == 5) {
            // V11 or V12 only for now
            var advName = result.getDeviceName();
            if (advName != null) {
              var advModel = advName.substring(0, 3);
              if (
                advModel.equals("V11") ||
                advModel.equals("V12") ||
                advModel.equals("V13") ||
                advModel.equals("V14")
              ) {
                eucData.model = advModel;
                wheelFound = true;
              }
            }
          }
          if (wheelFound == true) {
            storeSR(result);
            Ble.setScanState(Ble.SCAN_STATE_OFF);
            try {
              EUCDevice = Ble.pairDevice(result as Ble.ScanResult);
            } catch (e instanceof Lang.Exception) {
              System.println("EUCError: " + e.getErrorMessage());
            }
          }
        }
      }
    } else {
      if (
        hornProfileManager != null &&
        hornProfileManager has :WH_SERVICE &&
        eucData.ESP32Horn == true
      ) {
        if (eucData.ESP32HornPaired == false) {
          for (
            var result = scanResults.next();
            result != null;
            result = scanResults.next()
          ) {
            if (result instanceof Ble.ScanResult) {
              if (
                contains(
                  result.getServiceUuids(),
                  hornProfileManager.WH_SERVICE,
                  result
                ) == true
              ) {
                //System.println("HornFOund!");
                Ble.setScanState(Ble.SCAN_STATE_OFF);
                try {
                  // Do something here
                  hornDevice = Ble.pairDevice(result as Ble.ScanResult);
                } catch (e instanceof Lang.Exception) {
                  System.println("hornError: " + e.getErrorMessage());
                }
                //System.println("ConnectedToHorn?");
              }
            }
          }
        }
      } else {
        Ble.setScanState(Ble.SCAN_STATE_OFF);
      }

      var result = loadSR(); // as Ble.ScanResult;
      if (result != false) {
        if (eucData.wheelBrand == 4 || eucData.wheelBrand == 5) {
          // V11 or V12 only for now
          var advName = result.getDeviceName();
          if (advName != null) {
            var advModel = advName.substring(0, 3);
            if (
              advModel.equals("V11") ||
              advModel.equals("V12") ||
              advModel.equals("V13") ||
              advModel.equals("V14")
            ) {
              eucData.model = advModel;
            }
          }
        }
        try {
          // Do something here
          EUCDevice = Ble.pairDevice(result as Ble.ScanResult);
        } catch (e instanceof Lang.Exception) {
          System.println("EUCError: " + e.getErrorMessage());
        }
      }
    }
  }

  function timerCallback() {
    queue.run();
  }
  function onDescriptorWrite(desc, status) {
    message7 = "descWrite";
    // If KS fire queue

    if ((eucData.wheelBrand == 2 || eucData.wheelBrand == 3) && char != null) {
      queue.delayTimer.start(method(:timerCallback), eucData.BLECmdDelay, true);
    }
    // If Inmotion, trigger only once as it will be triggered at each charchanged -> didn't work so let's loop
    if ((eucData.wheelBrand == 4 || eucData.wheelBrand == 5) && char != null) {
      queue.delayTimer.start(method(:timerCallback), eucData.BLECmdDelay, true);
    }
  }

  function onCharacteristicWrite(desc, status) {}

  function onCharacteristicChanged(char, value) {
    // message7 = "CharacteristicChanged";
    if (
      decoder != null &&
      (eucData.wheelBrand == 0 || eucData.wheelBrand == 1)
    ) {
      decoder.frameBuffer(value);
    }
    if (
      decoder != null &&
      (eucData.wheelBrand == 2 || eucData.wheelBrand == 3)
    ) {
      message8 = "decoding";
      decoder.processFrame(value);
    }
    if (eucData.wheelBrand == 4 || eucData.wheelBrand == 5) {
      decoder.frameBuffer(self, value);
    }
  }

  function sendCmd(cmd) {
    //Sys.println("enter sending command " + cmd);

    if (service != null && char != null && cmd != "") {
      var enc_cmd = string_to_byte_array(cmd as String);
      // Sys.println("sending command " + enc_cmd.toString());
      char.requestWrite(enc_cmd, { :writeType => Ble.WRITE_TYPE_DEFAULT });
      //  Sys.println("command sent !");
    }
  }

  function sendRawCmd(cmd) {
    //Sys.println("enter sending command " + cmd);
    char.requestWrite(cmd, { :writeType => Ble.WRITE_TYPE_DEFAULT });
    //  Sys.println("command sent !");
  }

  private function contains(iter, obj, sr) {
    for (var uuid = iter.next(); uuid != null; uuid = iter.next()) {
      if (uuid.equals(obj)) {
        return true;
      }
    }
    return false;
  }

  function getChar() {
    return char;
  }
  function getCharW() {
    return char_w;
  }

  function getPMService() {
    return profileManager.EUC_SERVICE;
  }

  function manualUnpair() {
    if (EUCDevice != null) {
      Ble.unpairDevice(EUCDevice);
    }
  }
  function setHornProfile(_hornPM) {
    hornProfileManager = _hornPM;
  }
  function getHornService() {
    return horn_service;
  }

  function getHornChar() {
    return horn_char_w;
  }
}
