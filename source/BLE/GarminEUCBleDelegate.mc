///////////////////////////////////////////////////////////////////////////////
// BLE Delegate, this deals with BLE device scanning, pairing and BLE data processing
///////////////////////////////////////////////////////////////////////////////

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
  var cfgPacketsTotal = null;
  var cfgPacketsCount = 0;

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

  // Upon initialisation start scanning for supported devices
  function initialize(_profileNb, q, _decoder) {
    //System.println("init");
    message1 = "initializeBle";
    BleDelegate.initialize();

    profileNb = _profileNb;
    //char = profileManager.EUC_CHAR;
    queue = q;
    decoder = _decoder;

    Ble.setScanState(Ble.SCAN_STATE_SCANNING);
    //checking if EUC Footprint already exist (see IsFirsConnection function description)
    isFirst = isFirstConnection();
    //isFirst = false;
    if (eucData.useEngo == true) {
      deviceNb = deviceNb + 1;
    }
    if (eucData.ESP32Horn == true) {
      deviceNb = deviceNb + 1;
    }
  }

  // If a device with a registred BLE profile is paired, it trigger the onConnectedStateChanged callback.
  // This is where I initiate the communication procedure by enabling notifications on a the characteristic that supports the notify property
  function onConnectedStateChanged(device, state) {
    if (state == Ble.CONNECTION_STATE_CONNECTED) {
      // Checking we are dealing with an EUC and not another kind of supported device (horn, smartglasses)
      if (device.getService(eucPM.EUC_SERVICE) != null) {
        //System.println("EUC connected");
        message3 = "EUC connected";
        euc_service = device.getService(eucPM.EUC_SERVICE);
        var cccd;
        //Getting characteristic as a Characteristic object to enable notifications later
        euc_char =
          euc_service != null
            ? euc_service.getCharacteristic(eucPM.EUC_CHAR)
            : null;

        if (euc_service != null && euc_char != null) {
          // KS EUC specific ///////////////////////////////////////////////////////////////////////////////////////////////////////
          // Need to send a model request frame to initiate the communication with the EUC (using queue for that)
          if (eucData.wheelBrand == 2 || eucData.wheelBrand == 3) {
            var reqModel = [
              0xaa, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
              0x00, 0x00, 0x00, 0x00, 0x00, 0x9b, 0x14, 0x5a, 0x5a,
            ]b;
            queue.add([euc_char, reqModel]);
          }
          //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

          // Inmotion EUC specific /////////////////////////////////////////////////////////////////////////////////////////////////
          if (eucData.wheelBrand == 4 || eucData.wheelBrand == 5) {
            // Inmotion EUCs have a separate characteritic with a write property -> that's the characteristic used when sending BLE requests
            euc_char_w = euc_service.getCharacteristic(eucPM.EUC_CHAR_W);

            // Untested code if speed limiter is enabled, use a request to get settings frame and read the current tiltback speed value
            // (to restore correct tiltback speed when disabling speed limiter)
            if (eucData.speedLimit != 0) {
              //request settings
              var getSettings = [0xaa, 0xaa, 0x14, 0x02, 0x20, 0x20, 0x16]b;
              queue.add([euc_char_w, getSettings]);
              queue.lastPacketType = "settings";
            }
            // Storing inmotion periodic request directly in variables from the queue class :
            // inmotion v2 request live:
            queue.reqLiveData = [
              euc_char_w,
              [0xaa, 0xaa, 0x14, 0x01, 0x04, 0x11]b,
            ];
            // inmotion v2 request stats :
            queue.reqStats = [
              euc_char_w,
              [0xaa, 0xaa, 0x14, 0x01, 0x11, 0x04]b,
            ];
          }

          //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

          // Enabling notification on characteristic (Begode and Leaperkim will start sending data right aways, KS requires one BLE request, and Inmotion requires periodic BLE request)
          cccd = euc_char.getDescriptor(Ble.cccdUuid());
          // Enabling notification is done by writing 0x01 0x00 to the descriptor of the characteristic. That also trigger the onDescriptorWrite() callback -> that's where I send
          // the required requests for KS and Inmotion EUCs
          cccd.requestWrite([0x01, 0x00]b);
          message4 = "characteristic notify enabled";
          eucData.paired = true;
          message3 = "EUC connected";
          eucData.timeWhenConnected = new Time.Moment(Time.now().value());
          // At this point the EUC is considered as connected.
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

      // if the paired device is a DIY Bluetooth Horn (WheelHorn)
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

      // if the paired device is Engo smarglasses from Activelook
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
      // If a disconnection occurs, check what has been disconnected and restat a device scanning
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

  // Pair the device and increment connNb (number of connected BLE devices).
  // Note : connNb is used to know if all expected devices are connected, if it is the case I will stop scanning for supported devices.
  function pair(result as Ble.ScanResult) {
    var dev = Ble.pairDevice(result);
    if (dev != null) {
      connNb = connNb + 1;
    }
    return dev;
  }
  // Unpair the device and decrement connNb (number of connected BLE devices)
  // Note : connNb is used to know if all expected devices are connected, if it is the case I will stop scanning for supported devices.
  function unpair(device) {
    Ble.unpairDevice(device);
    connNb = connNb - 1;
  }

  // function isFirstConnection() isuUsed to dertermine if a given profile was never connected to an EUC (in order to store a BLE Footprint in the watch local storage.
  // This BLE footprint (which is simply a ScanResult object) will allow connecting ony to one specific EUC (the footprint is supposed to be unique))
  function isFirstConnection() {
    // resetting profileScanResult if wheelName changed (deleting associated footprint):
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
    // If a footprint doesn't exist, return true, else return false
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

  // This function is used to store the footprint and the EUC name on the persistant storage
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

  // This function is used to load the footprint from the persistant storage
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

  // onScanResults callback is called periodically (no idea of the frequency) when BLE Status is : scanning
  //! @param scanResults An iterator of new scan results
  function onScanResults(scanResults as Ble.Iterator) {
    // System.println("scanning");
    // Checking if scanResults match an EUC given the brand selected in the associated profile. When possible EUCs are identified by their BLE SERVICE UUID. But some time this data
    // is not available (Garmin truncate the BLE Advertising packet). When SERVICE UUID is not available the device BLE advertising name is used instead.
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
          // For some unknown reason (aka Garmin BLE implementation, advertising packet is truncated, data loss, usual business), another BLE service is shown instead of the expected one (with notify characteristic) for KS.
          // This BLE service is only used for EUC identification.
          if (eucData.wheelBrand == 3 && eucPM.OLD_KS_ADV_SERVICE != null) {
            wheelFound = contains(
              result.getServiceUuids(),
              eucPM.OLD_KS_ADV_SERVICE,
              result
            );
          }
          // Using BLE adversiting name for recent KS, name always starts with KSN.
          if (eucData.wheelBrand == 2) {
            var advName = result.getDeviceName();
            if (advName != null) {
              if (advName.substring(0, 3).equals("KSN")) {
                wheelFound = true;
              }
            }
          }
          // Using BLE adversiting name for Inmotion.
          if (eucData.wheelBrand == 4 || eucData.wheelBrand == 5) {
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
            // If a device matched expected UUID or Name, storing the footprint and stopping the BLE scanning.
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
      // Pairing to other devices is done after the first connection was done.
      // I'll probably have to implement footprint saving for other devices (otherwise the app will pair to any device with corresponding UUID).
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
                  System.println("engoError: " + e.getErrorMessage());
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
    }

    var result = loadSR(); // Load the saved EUC footprint (ScanResult object);
    if (result != false) {
      // If Inmotion get the model name from the advertising packet (used for battery % computation)
      if (eucData.wheelBrand == 4 || eucData.wheelBrand == 5) {
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
      // Pairing surrounded by try catch to avoid app crash in case of failure
      try {
        EUCDevice = pair(result as Ble.ScanResult);
      } catch (e instanceof Lang.Exception) {
        // System.println("EUCError: " + e.getErrorMessage());
      }
    }
    //  System.println("connected devices:" + connNb);
    //  System.println("expected devices:" + deviceNb);

    // Check if active connections number matches the expected devices number to stop the BLE scanning
    if (deviceNb == connNb) {
      //  System.println("stopping scan");
      Ble.setScanState(Ble.SCAN_STATE_OFF);
    }
  }

  // self explanatory, but the function name could be more meaningful :)
  function timerCallback() {
    queue.run();
  }

  // onDescriptorWrite callback is called every time a write action occured on a descriptor (in our case, the typical scenario is after enabling notification).
  function onDescriptorWrite(desc, status) {
    message7 = "descWrite";

    var currentChar = desc.getCharacteristic();
    // if the descriptor characteristic belong to registred EUC device:
    if (currentChar.equals(eucPM.EUC_CHAR)) {
      // If KS EUC, send getModel request using ble queue (getModel request was added during EUC pairing procedure)
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
      // If Inmotion, start the ble queue, if the queue is empty it will start an continuous cycle of requests using requests that were stored in Inmotion related variables in the queue class.
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
      // If descriptor write occured on something else than an EUC
      if (eucData.engoPaired == true) {
        // System.println("EngoPairedIsTrue, descript");
        // If the smartglasses pairing was successful and notifications are already enabled on the user input (button or gesture), start the smartglasses init procedure -> requesting fw version
        if (currentChar.equals(engo_userInput) && engoGestureNotif == true) {
          try {
            engo_rx.requestWrite([0xff, 0x06, 0x00, 0x05, 0xaa]b, {
              :writeType => Ble.WRITE_TYPE_DEFAULT,
            });
          } catch (e instanceof Lang.Exception) {
            // System.println(e.getErrorMessage());
          }
        } else {
          // if notification are not yet activated for gesture that means it was a write on the tx characteristic descriptor -> enabling notification on the user input characteristic
          enableGesture();
        }
      }
    }
  }
  function cfgUpdateStatus() {
    // means update started

    cfgPacketsCount++;

    eucData.engoCfgUpdate =
      ((cfgPacketsCount * 100) / cfgPacketsTotal).toString() + "%";
    if (cfgPacketsCount >= cfgPacketsTotal) {
      cfgPacketsTotal = null;
      eucData.engoCfgUpdate = "Loading";
    }
  }
  // onCharacteristricWrite is called each time a write operation occurs on a characteristic. The following code should allow getting rid of the queue system, but while it's probably
  // better in terms of performance (requests are sent again asap in case of failure) I'm not sure it's better in terms of used ressources (the timer will wait 200ms per default before resubmitting the request). To be confirmed !
  // Note: this code is from activelook garmin app.
  function onCharacteristicWrite(
    characteristic as Toybox.BluetoothLowEnergy.Characteristic,
    status as Toybox.BluetoothLowEnergy.Status
  ) as Void {
    if (characteristic.equals(engo_rx) && cfgPacketsTotal != null) {
      cfgUpdateStatus();
    }
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

  // onCharacteristicChanged callback is called each time a notification is received (that means data from the EUC or the smartglasses).
  function onCharacteristicChanged(char, value) {
    // message7 = "CharacteristicChanged";
    // If characteristic matches a the registred characteritic of a EUC
    if (char.equals(euc_char)) {
      // Decoding data depending on EUC brand.
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
    // If characteristic matches a the registred characteritic of the engo smartglasses
    if (char.equals(engo_tx)) {
      //System.println(value);
      //System.println("EngoCharChanged");

      // If frame command ID matches the version/firmware frame
      if (value[1] == 0x06) {
        //firmware vers
        if (value.size() > 9) {
          // store firmware version
          var firm = value.slice(4, 8);
          //System.println("firm: " + firm);
        }

        //send the command to get the list of configurations stored on the smartglasses
        sendRawCmd(engo_rx, [0xff, 0xd3, 0x00, 0x05, 0xaa]b);
      }
      //Checking if the received frame matches the frame with the battery % of the smartglasses
      if (value[0] == 0xff && value[1] == 0x05) {
        eucData.engoBattery = value[4];
      }
      //Checking if the received frame matches the frame containing the list of configuration stored on the smartglasses
      if (value[1] == 0xd3 && value[value.size() - 1] != 0xaa) {
        cfgReadFlag = true;
        //check if WheelDash config for engo exists in the cfg list
        checkCfgName(value);
        return;
      }
      // As config list can be sent on more than one frame checking for every frame if it contains WheelDash config name.
      if (cfgReadFlag == true && value[value.size() - 1] != 0xaa) {
        checkCfgName(value);
        return;
      }
      // if the last packet of the config list arrived (0xAA is the footer byte), checking again if WheelDash config name is in the config list.
      if (cfgReadFlag == true && value[value.size() - 1] == 0xaa) {
        checkCfgName(value);
        // As the last packet of the config list frame was received set cfgReadFlag as false
        cfgReadFlag = false;
        // if no config found the engoCfg variable is null, set it to false
        if (engoCfgOK != true) {
          engoCfgOK = false;
        }
      }
      // if no config found or update needed (see checkCfgName function), uploading config.
      if (engoCfgOK == false) {
        clearScreen();

        //System.println("uploading config");
        sendRawCmd(engo_rx, getWriteCmd("updating config", 195, 110, 4, 5, 16));
        sendRawCmd(engo_rx, getWriteCmd("please wait...", 195, 70, 4, 5, 16));
        cfgPacketsTotal = 0;
        // Engo config is stored in Resources.xml as a json object to avoid OOM error if stored in a ByteArray(splitted in two because otherwise it's too big)
        for (var i = 0; i < getJson(:EngoCfg1).size(); i++) {
          var charNb = getJson(:EngoCfg1)[i].length();
          cfgPacketsTotal = cfgPacketsTotal + Math.ceil(charNb / 40);
          var cmd = arrayToRawCmd(getJson(:EngoCfg1)[i]);
          sendRawCmd(engo_rx, cmd);
        }
        for (var i = 0; i < getJson(:EngoCfg2).size(); i++) {
          var charNb = getJson(:EngoCfg2)[i].length();
          cfgPacketsTotal = cfgPacketsTotal + Math.ceil(charNb / 40);
          var cmd = arrayToRawCmd(getJson(:EngoCfg2)[i]);
          sendRawCmd(engo_rx, cmd);
        }
        //eucData.engoCfgUpdate = null;
        // request smartglasses config list again to ensure config upload was succesful
        cfgList = new [0]b; // clearing cfgList before requesting the config list
        sendRawCmd(engo_rx, [0xff, 0xd3, 0x00, 0x05, 0xaa]b);
      }
      // If notifications are enabled on the gesture related characteristic, enable the gesture sensor on the smartglasses (not required at every boot as it is a permanent setting,
      // but that way I don't have to check the gesture sensor status.)
      if (engoGestureNotif == true && engoGestureOK == false) {
        if (eucData.engoTouch == 0) {
          sendRawCmd(engo_rx, [0xff, 0x21, 0x00, 0x06, 0x01, 0xaa]b);
        }
        //System.println("gesture enabled");
        engoGestureOK = true;
      }
      // If config was successfuly uploaded set the current config to wheeldash config and clear screen
      if (engoCfgOK == true && engoDisplayInit == false) {
        //If cfg was updated, clearing percentage progression status:
        eucData.engoCfgUpdate = null;
        //  System.println("select cfg");
        sendRawCmd(
          engo_rx,
          [
            0xff, 0xd2, 0x00, 0x0f, 0x77, 0x68, 0x65, 0x65, 0x6c, 0x64, 0x61,
            0x73, 0x68, 0x00, 0xaa,
          ]b
        );
        //

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

    // If an event is triggered on the proximity sensor or the capacitive button, a notification is sent on the userInput Characteristic -> displaying next page on the smartglasses
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
  // Self explanatory : send clear screen command
  function clearScreen() {
    sendRawCmd(engo_rx, [0xff, 0x01, 0x00, 0x05, 0xaa]b);
    // sendRawCmd(engo_rx, [0xff, 0x86, 0x00, 0x06, eucData.engoPage, 0xaa]b);
  }

  // Send battery % request
  function getEngoBattery() {
    sendRawCmd(engo_rx, [0xff, 0x05, 0x00, 0x05, 0xaa]b);
  }
  // Reset the init variables for the Engo smartglasses, required when a disconnection occured with the smartglasses
  function resetEngo() {
    cfgReadFlag = false;
    cfgList = new [0]b;
    engoDisplayInit = false;
    engoCfgOK = null;
    engoGestureOK = false;
    engoGestureNotif = false;
    cfgPacketsTotal = null;
    cfgPacketsCount = 0;
    eucData.engoCfgUpdate = null;
  }
  // checkCfgName function parse the received config list packet to check if wheeldash config is present in the config list.
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
            //System.println(cfgVer);
            //System.println(cfgEngoVer);
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

  // enableGesture enables notifications on the user_input characteristic
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

  // function sendCmd is used when no queue is required, only for EUCs.
  function sendCmd(cmd) {
    //Sys.println("enter sending command " + cmd);

    if (euc_service != null && euc_char != null && cmd != "") {
      var enc_cmd = string_to_byte_array(cmd as String);
      // Sys.println("sending command " + enc_cmd.toString());
      euc_char.requestWrite(enc_cmd, { :writeType => Ble.WRITE_TYPE_DEFAULT });
      //  Sys.println("command sent !");
    }
  }

  // function sendCommands is only used for commands related to display (it's just a way to ensure the engo are properly initialized to avoid sending unecessary commands while
  // the engo are initialising)
  function sendCommands(cmds) {
    if (engoCfgOK == true && engoDisplayInit == true) {
      sendRawCmd(engo_rx, cmds);
      // System.println(cmds[i]);
    }
  }

  // sendRawCmd split commands into packet of 20 bytes and sent a write request on the specified characteristic.
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

  //contains function is an helper function to check if one registred UUID matches the scanResult UUID. Could be moved to helperFunction.mc but exclusively used in eucBLEDelegate class.
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

  // __onWrite_finishPayload is part of an implementation of activelook garmin app. I haven't taken the time to properly understand how it work.
  function __onWrite_finishPayload(c, s) {
    _cbCharacteristicWrite = null;
    if (s == 0) {
      self.sendRawCmd(c, []b);
    } else {
      throw new Toybox.Lang.InvalidValueException("(E) Could write on: " + c);
    }
  }
  // function for padding text for engo smartglasses, should be move to helperFunction.mc
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
