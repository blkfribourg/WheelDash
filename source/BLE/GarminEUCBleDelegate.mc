using Toybox.System;
using Toybox.BluetoothLowEnergy as Ble;
using Toybox.WatchUi as Ui;
import Toybox.Lang;
using Toybox.Application.Storage;

class eucBLEDelegate extends Ble.BleDelegate {
  var profileManager = null;
  var device = null;
  var service = null;
  var char = null;
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
  /*
  var frame1 = [
    170, 85, 75, 83, 45, 83, 50, 50, 45, 48, 50, 51, 49, 0, 0, 0, 187, 20, 138,
    90, 90,
  ];
*/
  function initialize(pm, _profileNb, q, _decoder) {
    message1 = "initializeBle";
    BleDelegate.initialize();
    profileManager = pm;
    profileNb = _profileNb;
    char = profileManager.EUC_CHAR;
    queue = q;
    decoder = _decoder;

    //System.println(profileManager.EUC_SERVICE);
    //System.println(profileManager.EUC_CHAR);
    /*if (eucData.wheelBrand == 2) {
      decoder.processFrame(frame1);
    }
    */
    Ble.setScanState(Ble.SCAN_STATE_SCANNING);
    isFirst = isFirstConnection();
  }

  function onConnectedStateChanged(device, state) {
    //		view.deviceStatus=state;
    if (state == Ble.CONNECTION_STATE_CONNECTED) {
      message3 = "BLE connected";
      var cccd;
      service = device.getService(profileManager.EUC_SERVICE);
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
          var reqSerial = [
            0xaa, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x14, 0x5a, 0x5a,
          ]b;
          var reqAlarms = [
            0xaa, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x98, 0x14, 0x5a, 0x5a,
          ]b;
          queue.add(
            [char, queue.C_WRITENR, reqModel],
            profileManager.EUC_SERVICE
          );
          queue.add(
            [char, queue.C_WRITENR, reqSerial],
            profileManager.EUC_SERVICE
          );
          queue.add(
            [char, queue.C_WRITENR, reqAlarms],
            profileManager.EUC_SERVICE
          );
        }
        // End of addition -------------------------------
        cccd = char.getDescriptor(Ble.cccdUuid());
        cccd.requestWrite([0x01, 0x00]b);
        message4 = "characteristic notify enabled";
        eucData.paired = true;
        message5 = "BLE paired";
        eucData.timeWhenConnected = new Time.Moment(Time.now().value());

        /* NOT WORKING
        if (device.getName() != null || device.getName().length != 0) {
          eucData.name = device.getName();
        } else {
          eucData.name = "Unknown";
        }*/
      } else {
        message6 = "unable to pair";
        Ble.unpairDevice(device);
        eucData.paired = false;
      }
    } else {
      Ble.unpairDevice(device);
      Ble.setScanState(Ble.SCAN_STATE_SCANNING);
      eucData.paired = false;
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
          if (eucData.wheelBrand == 0 || eucData.wheelBrand == 1) {
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
                //decoder.setBleDelegate(self);
                //decoder.setQueue(queue);
              }
            }
          }
          if (wheelFound == true) {
            storeSR(result);
            Ble.setScanState(Ble.SCAN_STATE_OFF);
            device = Ble.pairDevice(result as Ble.ScanResult);
          }
        }
      }
    } else {
      Ble.setScanState(Ble.SCAN_STATE_OFF);
      var result = loadSR();
      if (result != false) {
        device = Ble.pairDevice(result as Ble.ScanResult);
      }
    }
  }

  function timerCallback() {
    queue.run();
  }
  function onDescriptorWrite(desc, status) {
    message7 = "descWrite";
    // If KS fire queue
    // send getName request for KS using ble queue
    if ((eucData.wheelBrand == 2 || eucData.wheelBrand == 3) && char != null) {
      queue.delayTimer.start(method(:timerCallback), 200, true);
      //decoder.requestName();
      /*
      char.requestWrite(
        [
          0xaa, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
          0x00, 0x00, 0x00, 0x00, 0x00, 0x9b, 0x14, 0x5a, 0x5a,
        ]b,
        { :writeType => Ble.WRITE_TYPE_DEFAULT }
      );
      */
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
  /*
    hidden function string_to_byte_array(plain_text) {
    var options = {
		:fromRepresentation => StringUtil.REPRESENTATION_STRING_PLAIN_TEXT,
        :toRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,
        :encoding => StringUtil.CHAR_ENCODING_UTF8
    };
    
    //System.println(Lang.format("Converting '$1$' to ByteArray", [ plain_text ]));
    var result = StringUtil.convertEncodedString(plain_text, options);
    //System.println(Lang.format("           '$1$'..", [ result ]));
    
    return result;
}
*/

  var shouldAdd;
  var srList as Array?;
  var rssiList as Array?;
  var RssiIteration = eucData.RssiIteration;

  function addSr(sr as Ble.ScanResult) {
    if (srList == null || rssiList == null) {
      srList = [sr];
      rssiList = [sr.getRssi()];
    } else {
      shouldAdd = true;
      for (var i = 0; i < srList.size(); i++) {
        var currentSr = srList[i] as Ble.ScanResult;
        if (sr.isSameDevice(currentSr) == true) {
          shouldAdd = false;
          rssiList[i] = (rssiList[i] + sr.getRssi()) / 2; // averaging Rssi
          RssiIteration = RssiIteration - 1;
        }
      }
      if (shouldAdd == true) {
        srList.add(sr);
        rssiList.add(sr.getRssi());
      }
    }
  }
  function getBestSr() {
    var strgstRssi = -255;
    var srIdx = -1;
    //if (srList.size() != rssiList.size()) {
    // eucData.wheelName = "RSSI ERROR";
    //}
    for (var i = 0; i < rssiList.size(); i++) {
      if (strgstRssi < rssiList[i]) {
        strgstRssi = rssiList[i];
        srIdx = i;
      }
    }
    if (srIdx != -1 && srIdx < srList.size()) {
      return srList[srIdx];
    } else {
      return null;
    }
  }

  function bestRssi(sr as Ble.ScanResult) {
    addSr(sr);
    if (RssiIteration <= 0) {
      // eucData.wheelName = "BESTRSSI";
      var SRToConnect = getBestSr();
      if (SRToConnect != null) {
        Ble.setScanState(Ble.SCAN_STATE_OFF);
        device = Ble.pairDevice(SRToConnect as Ble.ScanResult);
      }
    }
  }

  function getChar() {
    return char;
  }

  function getPMService() {
    return profileManager.EUC_SERVICE;
  }

  function manualUnpair() {
    if (device != null) {
      Ble.unpairDevice(device);
    }
  }
}
