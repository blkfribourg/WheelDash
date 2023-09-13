import Toybox.Lang;
using Toybox.BluetoothLowEnergy as Ble;

module frameDecoder {
  function init() {
    if (eucData.wheelBrand == 0) {
      return new GwDecoder();
    }
    if (eucData.wheelBrand == 1) {
      return new VeteranDecoder();
    }
    if (eucData.wheelBrand == 2 || eucData.wheelBrand == 3) {
      return new KingsongDecoder();
    } else {
      return null;
    }
  }
}

class GwDecoder {
  function signedShortFromBytesBE(bytes, starting) {
    if (bytes.size() >= starting + 2) {
      return (
        ((((bytes[starting] & 0xff) << 8) | bytes[starting + 1]) << 16) >> 16
      );
    }
    return 0;
  }

  function shortFromBytesBE(bytes, starting) {
    if (bytes.size() >= starting + 2) {
      return (
        ((((bytes[starting] & 0xff) << 8) | (bytes[starting + 1] & 0xff)) <<
          16) >>
        16
      );
    }
    return 0;
  }

  function UInt32FromBytesBE(bytes, starting) {
    if (bytes.size() >= starting + 4) {
      return (
        ((bytes[starting] & 0xff) << 24) |
        ((bytes[starting + 1] & 0xff) << 16) |
        ((bytes[starting + 2] & 0xff) << 8) |
        (bytes[starting + 3] & 0xff)
      );
    }
    return 0;
  }

  var settings = 0x0000;
  function frameBuffer(transmittedFrame) {
    for (var i = 0; i < transmittedFrame.size(); i++) {
      if (checkChar(transmittedFrame[i]) == true) {
        // process frame and guess type
        if (frame[18].toNumber() == 0) {
          // Frame A
          //System.println("Frame A detected");
          processFrameA(frame);
        } else if (frame[18].toNumber() == 4) {
          // Frame B
          //System.println("Frame B detected");
          processFrameB(frame);
        }
      }
    }
  }

  // adapted from wheellog
  var oldc;
  var frame as ByteArray?;
  var state = "unknown";
  function checkChar(c) {
    if (state.equals("collecting") && frame != null) {
      frame.add(c);
      oldc = c;

      var size = frame.size();

      if (
        (size == 20 && c.toNumber() != 24) ||
        (size > 20 && size <= 24 && c.toNumber() != 90)
      ) {
        state = "unknown";
        return false;
      }

      if (size == 24) {
        state = "done";
        return true;
      }
    } else {
      if (oldc != null && oldc.toNumber() == 85 && c.toNumber() == 170) {
        // beguining of a frame
        frame = new [0]b;
        frame.add(85);
        frame.add(170);
        state = "collecting";
      }
      oldc = c;
    }
    return false;
  }

  function processFrameB(value) {
    eucData.totalDistance = UInt32FromBytesBE(value, 2) / 1000.0; // in km
    settings = shortFromBytesBE(value, 6);

    //Sys.println("byte 10 :"+settings);

    eucData.pedalMode = (settings >> 13) & 0x03;
    eucData.speedAlertMode = (settings >> 10) & 0x03;
    eucData.rollAngleMode = (settings >> 7) & 0x03;
    eucData.useMiles = settings & 0x01;
    eucData.ledMode = value[13].toNumber(); // 12 in euc dashboard by freestyl3r
    //eucData.lightMode=value[19]&0x03; unable to get light mode from wheel
    //System.println("light mode (frameA ):"+eucData.lightMode);
  }
  function processFrameA(value) {
    eucData.voltage = shortFromBytesBE(value, 2) / 100.0;
    eucData.speed = (signedShortFromBytesBE(value, 4).abs() * 3.6) / 100.0;
    eucData.tripDistance = shortFromBytesBE(value, 8) / 1000.0; //in km
    eucData.Phcurrent = signedShortFromBytesBE(value, 10) / 100.0;
    eucData.temperature = signedShortFromBytesBE(value, 12) / 340.0 + 36.53;
    eucData.hPWM = signedShortFromBytesBE(value, 14).abs() / 100.0;
  }
}

class VeteranDecoder {
  function frameBuffer(transmittedFrame) {
    for (var i = 0; i < transmittedFrame.size(); i++) {
      if (checkChar(transmittedFrame[i]) == true) {
        processFrame(frame);
      }
    }
  }

  // adapted from wheellog
  var old1 = 0;
  var old2 = 0;
  var len = 0;

  var frame as ByteArray?;
  var state = "unknown";
  function checkChar(c) {
    if (state.equals("collecting") && frame != null) {
      var size = frame.size();

      if (
        ((size == 22 || size == 30) && c.toNumber() != 0) ||
        (size == 23 && (c & 0xfe).toNumber() != 0) ||
        (size == 31 && (c & 0xfc).toNumber() != 0)
      ) {
        state = "done";
        reset();
        return false;
      }
      frame.add(c);
      if (size == len + 3) {
        state = "done";
        reset();
        return true;
      }
      // break;
    } else if (state.equals("lensearch")) {
      frame.add(c);
      len = c & 0xff;
      state = "collecting";
      old2 = old1;
      old1 = c;
      //break;
    } else {
      if (
        c.toNumber() == 92 &&
        old1.toNumber() == 90 &&
        old2.toNumber() == 220
      ) {
        frame = new [0]b;
        frame.add(220);
        frame.add(90);
        frame.add(92);
        state = "lensearch";
      } else if (c.toNumber() == 90 && old1.toNumber() == 220) {
        old2 = old1;
      } else {
        old2 = 0;
      }
      old1 = c;
    }
    return false;
  }
  function reset() {
    old1 = 0;
    old2 = 0;
    state = "unknown";
  }

  function processFrame(value) {
    eucData.voltage =
      value.decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
        :offset => 4,
        :endianness => Lang.ENDIAN_BIG,
      }) / 100.0;
    eucData.speed =
      value.decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
        :offset => 6,
        :endianness => Lang.ENDIAN_BIG,
      }) / 10.0;
    eucData.Phcurrent =
      value.decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
        :offset => 16,
        :endianness => Lang.ENDIAN_BIG,
      }) / 10.0;
    eucData.tripDistance =
      (((value[8 + 2] & 0xff) << 24) |
        ((value[8 + 3] & 0xff) << 16) |
        ((value[8] & 0xff) << 8) |
        (value[8 + 1] & 0xff)) /
      1000.0;
    eucData.totalDistance =
      (((value[12 + 2] & 0xff) << 24) |
        ((value[12 + 3] & 0xff) << 16) |
        ((value[12] & 0xff) << 8) |
        (value[12 + 1] & 0xff)) /
      1000.0;

    /*
    eucData.temperature =
      value.decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
        :offset => 18,
        :endianness => Lang.ENDIAN_BIG,
      }) / 100.0;
      */
    //from eucWatch :
    eucData.temperature = ((value[18] << 8) | value[19]) / 100;
    // implement chargeMode/speedAlert/speedTiltback later
    eucData.version =
      value.decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
        :offset => 28,
        :endianness => Lang.ENDIAN_BIG,
      }) / 1000.0;
    eucData.hPWM =
      value.decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
        :offset => 34,
        :endianness => Lang.ENDIAN_BIG,
      }) / 100.0;
  }
}

class KingsongDecoder {
  var char;
  var bleDelegate;
  var queue;

  function setBleDelegate(_bleDelegate) {
    bleDelegate = _bleDelegate;
  }

  function setQueue(_queue) {
    queue = _queue;
  }
  function timerCallback() {
    queue.run();
  }

  function requestName() {
    var data = getEmptyRequest();
    data[16] = 155;
    queue.add([bleDelegate, queue.C_WRITENR, data], bleDelegate.getPMService());
    queue.delayTimer.start(method(:timerCallback), 200, true);
  }
  // Not using requestSerial for now
  /*
  function requestSerial(char) {
    var data = getEmptyRequest();
    data[16] = 99;
    char.requestWrite(data, { :writeType => Ble.WRITE_TYPE_DEFAULT });
  }*/
  function getEmptyRequest() {
    return [
      0xaa, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x14, 0x5a, 0x5a,
    ]b;
  }

  function processFrame(value) {
    //System.println("Processing KS frame");
    /*
    if (eucData.KSName == null) {
      requestName(char);
    } else if (eucData.KSSerial == null) {
      requestSerial(char);
    }
    */
    if (value.size() >= 20) {
      var a1 = value[0] & 255;
      var a2 = value[1] & 255;
      if (a1 != 170 || a2 != 85) {
        return false;
      }
      if ((value[16] & 255) == 0xa9) {
        //System.println("live data processing");
        // Live data
        var voltage = decode2bytes(value[2], value[3]) / 100.0;
        eucData.voltage = voltage; //wd.setVoltage(voltage);

        eucData.speed = decode2bytes(value[4], value[5]) / 100.0;

        if (
          eucData.model.equals("KS-18L") &&
          eucData.KS18L_scale_toggle == true
        ) {
          eucData.totalDistance =
            (0.83 * decode4bytes(value[6], value[7], value[8], value[9])) /
            1000.0;
        } else {
          eucData.totalDistance =
            decode4bytes(value[6], value[7], value[8], value[9]) / 1000.0;
        }
        //eucData.current = decode2bytes(value[10], value[11]);
        var KScurrent = (value[11] << 8) | value[10];
        if (32767 < KScurrent) {
          KScurrent = KScurrent - 65536;
        }
        eucData.current = KScurrent / 100.0;
        eucData.temperature = decode2bytes(value[12], value[13]) / 100.0;

        if ((value[15] & 255) == 224) {
          var mMode = value[14]; // don't know what it is
        }
        return true;
      } else if ((value[16] & 255) == 0xb9) {
        // Distance/Time/Fan Data
        eucData.tripDistance =
          decode4bytes(value[2], value[3], value[4], value[5]) / 1000.0;
        eucData.fanStatus = value[12];
        eucData.chargingStatus = value[13];
        eucData.temperature2 = decode2bytes(value[14], value[15]) / 100.0;
      } else if ((value[16] & 255) == 187) {
        // Name and Type data : Don't get why it's so "twisted" but OK ...
        var end;
        var i = 0;
        var advName = "";
        while (i < 14 && value[i + 2] != 0) {
          i++;
        }
        end = i + 2;
        for (i = 2; i < end; i++) {
          advName = advName + value[i].toChar().toString();
        }
        //System.println(advName);
        var model = "";
        var ss = splitstr(advName, "-");
        for (i = 0; i < ss.size() - 1; i++) {
          if (i != 0) {
            model = model + "-";
          }
          model = model + ss[i];
          // System.println("." + model + ".");
        }

        eucData.model = model;
      } else if ((value[16] & 255) == 0xb3) {
        //I don't care about that for now
        /*
        // Serial Number
        var sndata = new [18]b;
        var dataIndex = 2;
        var sndataIndex = 0;
        for (var i = 0; i < 14; i++) {
          sndata[sndataIndex] = value[dataIndex];
          sndataIndex++;
          dataIndex++;
        }

        dataIndex = 17;
        for (var i = 0; i < 3; i++) {
          sndata[sndataIndex] = value[dataIndex];
          sndataIndex++;
          dataIndex++;
        }

        sndata[17] = 0;
        eucData.KSSerial = sndata.toString(); // doesn't convert to char but not really using serial for now
*/
      } else if ((value[16] & 255) == 0xf5) {
        //cpu load
        eucData.cpuLoad = value[14];
        eucData.hPWM = value[15];
        return false;
      } else if ((value[16] & 255) == 0xf6) {
        //speed limit (PWM?)
        eucData.speedLimit = decode2bytes(value[2], value[3]) / 100.0;
        return false;
      } else if ((value[16] & 255) == 0xa4 || (value[16] & 255) == 0xb5) {
        //max speed and alerts
        eucData.KSMaxSpeed = value[10] & 255;

        eucData.KSAlarm3Speed = value[8] & 255;
        eucData.KSAlarm2Speed = value[6] & 255;
        eucData.KSAlarm1Speed = value[4] & 255;

        // after received 0xa4 send same repeat data[2] =0x01 data[16] = 0x98
        /*
        if ((value[16] & 255) == 164) {
          value[16] = 0x98;
          //let's use queue to be safe :
          queue.add(
            [bleDelegate, queue.C_WRITENR, value],
            bleDelegate.getPMService()
          );
          queue.delayTimer.start(method(:timerCallback), 200, true);
        }*/
        return true;
      } else if ((value[16] & 255) == 0xf1 || (value[16] & 255) == 0xf2) {
        // F1 - 1st BMS, F2 - 2nd BMS. F3 and F4 are also present but empty
      } else if ((value[16] & 255) == 0xe1 || (value[16] & 255) == 0xe2) {
        // e1 - 1st BMS, e2 - 2nd BMS.
      } else if ((value[16] & 255) == 0xe5 || (value[16] & 255) == 0xe6) {
        // e5 - 1st BMS, e6 - 2nd BMS.
      }
    }
    return false;
  }

  function decode2bytes(byte1, byte2) {
    return (byte1 & 0xff) + (byte2 << 8);
  }
  function decode4bytes(byte1, byte2, byte3, byte4) {
    return (byte1 << 16) + (byte2 << 24) + byte3 + (byte4 << 8);
  }
}
