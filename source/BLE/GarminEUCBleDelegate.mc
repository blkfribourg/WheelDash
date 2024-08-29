using Toybox.System;
using Toybox.BluetoothLowEnergy as Ble;
using Toybox.WatchUi as Ui;
import Toybox.Lang;
using Toybox.Application.Storage;

class eucBLEDelegate extends Ble.BleDelegate {
  var euc_service = null;
  var euc_char = null;
  var euc_char_w = null;
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

  var EUCDevice = null;
  var hornDevice = null;
  var horn_service = null;
  var engo_service = null;
  var engo_tx = null;
  var engo_rx = null;
  var engo_userInput = null;
  var engoDevice = null;
  var engoCfgOK;
  var cfgReadFlag = false;
  var engoGestureOK = false;
  var engoGestureNotif = false;
  var _cbCharacteristicWrite = null;
  var rawcmd = null;
  var rawcmdError = null;
  var engoDisplayInit = false;
  var cfgList = new [0]b;
  var isUpdatingBleParams as Toybox.Lang.Boolean = false;
  var isBleParamsUpdated as Toybox.Lang.Boolean = false;
  var firstChar;
  var deviceNb = 1;
  var connNb = 0;
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
  function initialize(_profileNb, q, _decoder) {
    //System.println("init");
    message1 = "initializeBle";
    BleDelegate.initialize();

    profileNb = _profileNb;
    //char = profileManager.EUC_CHAR;
    queue = q;
    decoder = _decoder;

    Ble.setScanState(Ble.SCAN_STATE_SCANNING);
    isFirst = isFirstConnection();
    //isFirst = false;
    if (eucData.useEngo == true) {
      deviceNb = deviceNb + 1;
    }
    if (eucData.ESP32Horn == true) {
      deviceNb = deviceNb + 1;
    }
  }

  function onConnectedStateChanged(device, state) {
    //		view.deviceStatus=state;
    if (state == Ble.CONNECTION_STATE_CONNECTED) {
      if (device.getService(eucPM.EUC_SERVICE) != null) {
        //System.println("EUC connected");
        message3 = "EUC connected";
        euc_service = device.getService(eucPM.EUC_SERVICE);
        var cccd;

        euc_char =
          euc_service != null
            ? euc_service.getCharacteristic(eucPM.EUC_CHAR)
            : null;
        if (euc_service != null && euc_char != null) {
          // If KS -> add init seq to ble queue -------- Addition
          if (eucData.wheelBrand == 2 || eucData.wheelBrand == 3) {
            var reqModel = [
              0xaa, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
              0x00, 0x00, 0x00, 0x00, 0x00, 0x9b, 0x14, 0x5a, 0x5a,
            ]b;

            queue.add([euc_char, queue.C_WRITENR, reqModel], eucPM.EUC_SERVICE);
          }
          // End of KS addition -------------------------------
          // Inmotion V2 or VESC ---------------------------
          if (eucData.wheelBrand == 4 || eucData.wheelBrand == 5) {
            if (eucData.speedLimit != 0) {
              //request settings
              var getSettings = [0xaa, 0xaa, 0x14, 0x02, 0x20, 0x20, 0x16]b;
              queue.add(
                [euc_char_w, queue.C_WRITENR, getSettings],
                eucPM.EUC_SERVICE
              );
              queue.lastPacketType = "settings";
            }
            euc_char_w = euc_service.getCharacteristic(eucPM.EUC_CHAR_W);
            // addition for inmotion v2 request live:
            queue.reqLiveData = [
              euc_char_w,
              queue.C_WRITENR,
              [0xaa, 0xaa, 0x14, 0x01, 0x04, 0x11]b,
            ];

            // inmotion v2 request stats :
            queue.reqStats = [
              euc_char_w,
              queue.C_WRITENR,
              [0xaa, 0xaa, 0x14, 0x01, 0x11, 0x04]b,
            ];
            queue.UUID = eucPM.EUC_SERVICE;
          }

          // End of inmotion V2 or VESC
          cccd = euc_char.getDescriptor(Ble.cccdUuid());
          cccd.requestWrite([0x01, 0x00]b);
          message4 = "characteristic notify enabled";
          eucData.paired = true;
          message3 = "EUC connected";
          eucData.timeWhenConnected = new Time.Moment(Time.now().value());
        } else {
          //System.println("unable to pair EUC");
          message3 = "EUC not connected";
          try {
            unpair(device);
            eucData.paired = false;
            firstChar = false;
          } catch (e instanceof Lang.Exception) {
            // System.println(e.getErrorMessage());
          }
        }
      }

      if (eucData.ESP32Horn == true) {
        if (device.getService(hornPM.WH_SERVICE) != null) {
          //System.println("Horn connected");

          horn_service = device.getService(hornPM.WH_SERVICE);

          horn_char_w =
            horn_service != null
              ? horn_service.getCharacteristic(hornPM.WH_CHAR_W)
              : null;
          if (horn_service != null && horn_char_w != null) {
            message4 = "Horn connected";
            eucData.ESP32HornPaired = true;
          } else {
            unpair(device);
            eucData.ESP32HornPaired = false;
            message4 = "Horn not connected";
          }
        }
      }
      if (eucData.useEngo == true) {
        if (device.getService(engoPM.BLE_SERV_ACTIVELOOK) != null) {
          // System.println("Engo connected");

          engo_service = device.getService(engoPM.BLE_SERV_ACTIVELOOK);

          engo_tx =
            engo_service != null
              ? engo_service.getCharacteristic(engoPM.BLE_CHAR_TX)
              : null;

          engo_rx =
            engo_service != null
              ? engo_service.getCharacteristic(engoPM.BLE_CHAR_RX)
              : null;

          engo_userInput =
            engo_service != null
              ? engo_service.getCharacteristic(engoPM.BLE_CHAR_USERINPUT)
              : null;

          if (
            engo_service != null &&
            engo_tx != null &&
            engo_rx != null &&
            engo_userInput != null
          ) {
            // System.println("EngoNotifOn");
            var cccd = engo_tx.getDescriptor(Ble.cccdUuid());
            try {
              cccd.requestWrite([0x01, 0x00]b);
            } catch (e instanceof Lang.Exception) {
              // System.println(e.getErrorMessage());
            }
            eucData.engoPaired = true;
          } else {
            System.print("notif fail");
            try {
              unpair(device);
              eucData.engoPaired = false;
            } catch (e instanceof Lang.Exception) {
              // System.println(e.getErrorMessage());
            }
          }
        }
      }
    } else {
      if (hornDevice != null && hornDevice.equals(device)) {
        eucData.ESP32HornPaired = false;
        message4 = "Horn disconnected";
        unpair(device);
        Ble.setScanState(Ble.SCAN_STATE_SCANNING);
      }
      if (EUCDevice != null && EUCDevice.equals(device)) {
        eucData.paired = false;
        message3 = "EUC disconnected";
        unpair(device);
        Ble.setScanState(Ble.SCAN_STATE_SCANNING);
      }
      if (engoDevice != null && engoDevice.equals(device)) {
        eucData.engoPaired = false;
        //System.println("Engo Disconnected");
        resetEngo();
        try {
          unpair(device);
        } catch (e instanceof Lang.Exception) {
          // System.println(e.getErrorMessage());
        }
        Ble.setScanState(Ble.SCAN_STATE_SCANNING);
      }
      //BLE Disconnected
    }
  }
  function pair(result as Ble.ScanResult) {
    var dev = Ble.pairDevice(result);
    if (dev != null) {
      connNb = connNb + 1;
    }
    return dev;
  }
  function unpair(device) {
    Ble.unpairDevice(device);
    connNb = connNb - 1;
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
    // System.println("scanning");
    if (isFirst) {
      var wheelFound = false;
      for (
        var result = scanResults.next();
        result != null;
        result = scanResults.next()
      ) {
        if (result instanceof Ble.ScanResult) {
          if (eucData.wheelBrand == 0 || eucData.wheelBrand == 1) {
            // Begode/Leaperkim
            wheelFound = contains(
              result.getServiceUuids(),
              eucPM.EUC_SERVICE,
              result
            );
          }
          if (eucData.wheelBrand == 3 && eucPM.OLD_KS_ADV_SERVICE != null) {
            wheelFound = contains(
              result.getServiceUuids(),
              eucPM.OLD_KS_ADV_SERVICE,
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
                advModel.equals("Adv") //V14
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
              EUCDevice = pair(result as Ble.ScanResult);
            } catch (e instanceof Lang.Exception) {
              System.println("EUCError: " + e.getErrorMessage());
            }
          }
        }
      }
    } else {
      // System.println("Scanning for other devices");
      for (
        var result = scanResults.next();
        result != null;
        result = scanResults.next()
      ) {
        if (result instanceof Ble.ScanResult) {
          //System.println(result.getServiceUuids().next());
          if (eucData.useEngo == true) {
            if (eucData.engoPaired == false) {
              if (
                contains(
                  result.getServiceUuids(),
                  engoPM.BLE_ENGO_MAIN,
                  result
                ) == true
              ) {
                //  System.println("EngoFound!");
                //  Ble.setScanState(Ble.SCAN_STATE_OFF);
                try {
                  // Do something here
                  engoDevice = pair(result as Ble.ScanResult);
                } catch (e instanceof Lang.Exception) {
                  System.println("hornError: " + e.getErrorMessage());
                }
                //System.println("ConnectedToHorn?");
              }
            }
          }

          if (eucData.ESP32Horn == true) {
            if (eucData.ESP32HornPaired == false) {
              if (
                contains(result.getServiceUuids(), hornPM.WH_SERVICE, result) ==
                true
              ) {
                //System.println("HornFOund!");
                //   Ble.setScanState(Ble.SCAN_STATE_OFF);
                try {
                  // Do something here
                  hornDevice = pair(result as Ble.ScanResult);
                } catch (e instanceof Lang.Exception) {
                  System.println("hornError: " + e.getErrorMessage());
                }
                //System.println("ConnectedToHorn?");
              }
            }
          }
        }
      }
      //
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
            advModel.equals("Adv") //V14
          ) {
            eucData.model = advModel;
          }
        }
      }
      try {
        // Do something here
        EUCDevice = pair(result as Ble.ScanResult);
      } catch (e instanceof Lang.Exception) {
        // System.println("EUCError: " + e.getErrorMessage());
      }
    }
    //  System.println("connected devices:" + connNb);
    //  System.println("expected devices:" + deviceNb);

    if (deviceNb == connNb) {
      //  System.println("stopping scan");
      Ble.setScanState(Ble.SCAN_STATE_OFF);
    }
  }

  function timerCallback() {
    queue.run();
  }
  function onDescriptorWrite(desc, status) {
    message7 = "descWrite";
    // If KS fire queue
    var currentChar = desc.getCharacteristic();
    // send getName request for KS using ble queue
    if (currentChar.equals(eucPM.EUC_CHAR)) {
      if (
        (eucData.wheelBrand == 2 || eucData.wheelBrand == 3) &&
        euc_char != null
      ) {
        queue.delayTimer.start(
          method(:timerCallback),
          eucData.BLECmdDelay,
          true
        );
      }
      // If Inmotion, trigger only once as it will be triggered at each charchanged -> didn't work so let's loop
      if (
        (eucData.wheelBrand == 4 || eucData.wheelBrand == 5) &&
        euc_char != null
      ) {
        queue.delayTimer.start(
          method(:timerCallback),
          eucData.BLECmdDelay,
          true
        );
      }
    } else {
      if (eucData.engoPaired == true) {
        // System.println("EngoPairedIsTrue, descript");
        if (currentChar.equals(engo_userInput) && engoGestureNotif == true) {
          try {
            engo_rx.requestWrite([0xff, 0x06, 0x00, 0x05, 0xaa]b, {
              :writeType => Ble.WRITE_TYPE_DEFAULT,
            });
          } catch (e instanceof Lang.Exception) {
            // System.println(e.getErrorMessage());
          }
        } else {
          enableGesture();
        }
      }
    }
  }

  function onCharacteristicWrite(
    characteristic as Toybox.BluetoothLowEnergy.Characteristic,
    status as Toybox.BluetoothLowEnergy.Status
  ) as Void {
    // _log("onCharacteristicWrite", [characteristic, status]);
    if (isUpdatingBleParams && !isBleParamsUpdated) {
      isUpdatingBleParams = false;
      if (status == Toybox.BluetoothLowEnergy.STATUS_SUCCESS) {
        isBleParamsUpdated = true;
      }
    } else {
      // TODO: Refactor to avoid callback like this
      var _cb = _cbCharacteristicWrite;
      if (_cb != null) {
        _cb.invoke(characteristic, status);
      }
    }
  }

  function onCharacteristicChanged(char, value) {
    // message7 = "CharacteristicChanged";
    if (char.equals(euc_char)) {
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
    if (char.equals(engo_tx)) {
      //System.println(value);
      //System.println("EngoCharChanged");
      if (value[1] == 0x06) {
        //firmware vers
        if (value.size() > 9) {
          var firm = value.slice(4, 8);
          //System.println("firm: " + firm);
        }

        //req cfg list
        sendRawCmd(engo_rx, [0xff, 0xd3, 0x00, 0x05, 0xaa]b);
      }
      if (value[0] == 0xff && value[1] == 0x05) {
        //battery
        eucData.engoBattery = value[4];
      }
      if (value[1] == 0xd3 && value[value.size() - 1] != 0xaa) {
        cfgReadFlag = true;
        //cfg list
        checkCfgName(value);
        return;
      }
      if (cfgReadFlag == true && value[value.size() - 1] != 0xaa) {
        checkCfgName(value);
        return;
      }
      if (cfgReadFlag == true && value[value.size() - 1] == 0xaa) {
        checkCfgName(value);
        cfgReadFlag = false;
        if (engoCfgOK != true) {
          //   System.println("wheeldash conf not found");
          engoCfgOK = false;
        }
      }
      if (engoCfgOK == false) {
        clearScreen();
        sendRawCmd(engo_rx, getWriteCmd("updating config", 195, 110, 4, 5, 16));
        sendRawCmd(engo_rx, getWriteCmd("please wait...", 195, 70, 4, 5, 16));
        System.println("uploading config");
        for (var i = 0; i < getJson(:EngoCfg1).size(); i++) {
          var cmd = arrayToRawCmd(getJson(:EngoCfg1)[i]);
          sendRawCmd(engo_rx, cmd);
          //System.println(cmd);
        }
        for (var i = 0; i < getJson(:EngoCfg2).size(); i++) {
          var cmd = arrayToRawCmd(getJson(:EngoCfg2)[i]);
          sendRawCmd(engo_rx, cmd);
          //System.println(cmd);
        }
        //   System.println("upload ongoing");

        // req Cfg list again;
        cfgList = new [0]b;
        sendRawCmd(engo_rx, [0xff, 0xd3, 0x00, 0x05, 0xaa]b);
      }
      if (engoGestureNotif == true && engoGestureOK == false) {
        if (eucData.engoTouch == 0) {
          sendRawCmd(engo_rx, [0xff, 0x21, 0x00, 0x06, 0x01, 0xaa]b);
        }

        //System.println("gesture enabled");
        engoGestureOK = true;
      }
      if (engoCfgOK == true && engoDisplayInit == false) {
        //  System.println("select cfg");
        sendRawCmd(
          engo_rx,
          [
            0xff, 0xd2, 0x00, 0x0f, 0x77, 0x68, 0x65, 0x65, 0x6c, 0x64, 0x61,
            0x73, 0x68, 0x00, 0xaa,
          ]b
        );
        //
        //System.println("clearing screen");
        clearScreen();
        //System.println("displaying page 1");

        /*
        System.println("writing text layout11");
        sendRawCmd(
          engo_rx,
          [
            0xff, 0x37, 0x00, 0x14, 0x00, 0x98, 0x00, 0x80, 0x03, 0x02, 0x0f,
            0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x20, 0x34, 0x00, 0xaa,
          ]b
        );
*/
        engoDisplayInit = true;
      }
    }
    if (engoDisplayInit == true) {
      //enable gesture
    }
    if (char.equals(engo_userInput)) {
      if (value[0] == 0x01) {
        //System.println("gesture detected");
        eucData.engoPage = eucData.engoPage + 1;
        if (eucData.engoPage > eucData.engoPageNb) {
          eucData.engoPage = 1;
        }
        clearScreen();
      }
    }
  }
  function clearScreen() {
    sendRawCmd(engo_rx, [0xff, 0x01, 0x00, 0x05, 0xaa]b);
    // sendRawCmd(engo_rx, [0xff, 0x86, 0x00, 0x06, eucData.engoPage, 0xaa]b);
  }
  function getEngoBattery() {
    sendRawCmd(engo_rx, [0xff, 0x05, 0x00, 0x05, 0xaa]b);
  }
  function resetEngo() {
    cfgReadFlag = false;
    cfgList = new [0]b;
    engoDisplayInit = false;
    engoCfgOK = null;
    engoGestureOK = false;
    engoGestureNotif = false;
  }
  function checkCfgName(value) {
    cfgList.addAll(value);
    //System.println(cfgList);
    if (cfgList[1] == 0xd3 && cfgList[cfgList.size() - 1] == 0xaa) {
      var names = new [0]b;
      var tempName = new [0]b;
      for (var i = 4; i < cfgList.size(); i++) {
        if (cfgList[i] == 0x00) {
          // dirty fix
          //System.println("config name: " + tempName);
          /*System.println(
            Toybox.StringUtil.convertEncodedString(tempName, {
              :fromRepresentation => Toybox.StringUtil
                .REPRESENTATION_BYTE_ARRAY,
              :toRepresentation => Toybox.StringUtil
                .REPRESENTATION_STRING_PLAIN_TEXT,
            })
          );*/
          if (
            Toybox.StringUtil.convertEncodedString(tempName, {
              :fromRepresentation => Toybox.StringUtil
                .REPRESENTATION_BYTE_ARRAY,
              :toRepresentation => Toybox.StringUtil
                .REPRESENTATION_STRING_PLAIN_TEXT,
            }).equals("wheeldash")
          ) {
            //checking version
            var cfgEngoVer = cfgList.slice(i + 5, i + 9);
            var cfgVer = arrayToRawCmd(
              getJson(:EngoCfg2)[getJson(:EngoCfg2).size() - 2]
            ).slice(14, 18);
            //  System.println(cfgVer);
            //  System.println(cfgEngoVer);
            if (cfgEngoVer.equals(cfgVer)) {
              //    System.println("version is up to date");
              engoCfgOK = true;
            }
          }
          names.addAll(tempName);
          tempName = new [0]b;

          i = i + 11;
        } else {
          tempName.add(cfgList[i]);
        }
      }
      //System.println("config packet: " + cfgList);
    }
  }
  function enableGesture() {
    if (engoGestureNotif == false) {
      try {
        var gcccd = engo_userInput.getDescriptor(Ble.cccdUuid());
        gcccd.requestWrite([0x01, 0x00]b);
        engoGestureNotif = true;
        //  System.println("gesture notif enabled");
      } catch (e) {
        //  System.println("could not enable notif on gesture");
      }
    }
  }

  function sendCmd(cmd) {
    //Sys.println("enter sending command " + cmd);

    if (euc_service != null && euc_char != null && cmd != "") {
      var enc_cmd = string_to_byte_array(cmd as String);
      // Sys.println("sending command " + enc_cmd.toString());
      euc_char.requestWrite(enc_cmd, { :writeType => Ble.WRITE_TYPE_DEFAULT });
      //  Sys.println("command sent !");
    }
  }

  function sendCommands(cmds) {
    if (engoCfgOK == true && engoDisplayInit == true) {
      sendRawCmd(engo_rx, cmds);
      // System.println(cmds[i]);
    }
  }
  //coder même principe pour descriptor ? ou implementer même methode qu'activelook
  function sendRawCmd(char, buffer) {
    var bufferToSend = []b;
    if (rawcmdError != null) {
      bufferToSend.addAll(rawcmdError);
      rawcmdError = null;
    }
    bufferToSend.addAll(buffer);
    try {
      if (bufferToSend.size() > 20) {
        var sendNow = bufferToSend.slice(0, 20);
        rawcmdError = bufferToSend.slice(20, null);
        _cbCharacteristicWrite = self.method(:__onWrite_finishPayload);
        char.requestWrite(sendNow, {
          :writeType => BluetoothLowEnergy.WRITE_TYPE_WITH_RESPONSE,
        });
      } else if (bufferToSend.size() > 0) {
        char.requestWrite(bufferToSend, {
          :writeType => BluetoothLowEnergy.WRITE_TYPE_WITH_RESPONSE,
        });
      }
    } catch (e) {
      rawcmdError = bufferToSend;
      rawcmd = null;
      // onBleError(e);
    }
  }

  private function contains(iter, obj, sr) {
    for (var uuid = iter.next(); uuid != null; uuid = iter.next()) {
      if (uuid.equals(obj)) {
        return true;
      }
    }
    return false;
  }
  function getQueue() {
    return queue;
  }
  function getChar() {
    return euc_char;
  }
  function getCharW() {
    return euc_char_w;
  }
  function getHornChar() {
    return horn_char_w;
  }
  function getHornService() {
    return horn_service;
  }

  function getPMService() {
    return eucPM.EUC_SERVICE;
  }

  function manualUnpair() {
    if (EUCDevice != null) {
      Ble.unpairDevice(EUCDevice);
    }
  }

  function __onWrite_finishPayload(c, s) {
    _cbCharacteristicWrite = null;
    if (s == 0) {
      self.sendRawCmd(c, []b);
    } else {
      throw new Toybox.Lang.InvalidValueException("(E) Could write on: " + c);
    }
  }
  var shouldAdd;

  function stringToPadByteArray(str, size, leftPadding) {
    var result = StringUtil.convertEncodedString(str, {
      :fromRepresentation => StringUtil.REPRESENTATION_STRING_PLAIN_TEXT,
      :toRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,
      :encoding => StringUtil.CHAR_ENCODING_UTF8,
    });
    if (size) {
      var padSize = size - result.size();
      if (padSize > 0) {
        var padBuffer = []b;
        do {
          padBuffer.add(0x20);
          padSize -= 1;
        } while (padSize > 0);
        if (leftPadding) {
          padBuffer.addAll(result);
          result = padBuffer;
        } else {
          result.addAll(padBuffer);
        }
      }
    }
    result.add(0x00);
    return result;
  }
}
