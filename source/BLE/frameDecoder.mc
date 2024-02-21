import Toybox.Lang;
using Toybox.BluetoothLowEnergy as Ble;
using Toybox.Time;

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
    }
    if (eucData.wheelBrand == 4) {
      return new IMV2Decoder();
    }
    if (eucData.wheelBrand == 5) {
      return new VESCDecoder();
    } else {
      return null;
    }
  }
}

class GwDecoder {
  var frameANb = 0;

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
    frameANb++;
    if (eucData.timeWhenConnected != null) {
      var elaspedTime = eucData.timeWhenConnected
        .subtract(new Time.Moment(Time.now().value()))
        .value();
      if (elaspedTime != 0) {
        eucData.BLEReadRate = frameANb / elaspedTime;
      }
    }
    eucData.voltage = shortFromBytesBE(value, 2) / 100.0;
    eucData.speed = (signedShortFromBytesBE(value, 4).abs() * 3.6) / 100.0;
    eucData.tripDistance = shortFromBytesBE(value, 8) / 1000.0; //in km
    eucData.Phcurrent = signedShortFromBytesBE(value, 10) / 100.0;
    if (eucData.useFahrenheit == 1) {
      eucData.temperature =
        (signedShortFromBytesBE(value, 12) / 340.0 + 36.53) * 1.8 + 32.0;
    } else {
      eucData.temperature = signedShortFromBytesBE(value, 12) / 340.0 + 36.53;
    }
    eucData.hPWM = signedShortFromBytesBE(value, 14).abs() / 100.0;
  }
}

class VeteranDecoder {
  function calculateCRC32(rawData, offset, crcLastIndex) {
    var crc = 0xffffffff;
    for (var i = 0; i < crcLastIndex; i++) {
      // https://stackoverflow.com/questions/5253194/implementing-logical-right-shift-in-c
      var mask_8 = ~(-1 << 8) << (32 - 8);
      var crc_shifted_8 = ~mask_8 & ((crc >> 8) | mask_8);

      crc = crc_shifted_8 ^ crc32Table[(crc & 0xff) ^ rawData[i + offset]];
    }
    crc ^= 0xffffffff;
    return crc;
  }

  var crc32Table = [
    0x00000000, 0x77073096, 0xee0e612c, 0x990951ba, 0x076dc419, 0x706af48f,
    0xe963a535, 0x9e6495a3, 0x0edb8832, 0x79dcb8a4, 0xe0d5e91e, 0x97d2d988,
    0x09b64c2b, 0x7eb17cbd, 0xe7b82d07, 0x90bf1d91, 0x1db71064, 0x6ab020f2,
    0xf3b97148, 0x84be41de, 0x1adad47d, 0x6ddde4eb, 0xf4d4b551, 0x83d385c7,
    0x136c9856, 0x646ba8c0, 0xfd62f97a, 0x8a65c9ec, 0x14015c4f, 0x63066cd9,
    0xfa0f3d63, 0x8d080df5, 0x3b6e20c8, 0x4c69105e, 0xd56041e4, 0xa2677172,
    0x3c03e4d1, 0x4b04d447, 0xd20d85fd, 0xa50ab56b, 0x35b5a8fa, 0x42b2986c,
    0xdbbbc9d6, 0xacbcf940, 0x32d86ce3, 0x45df5c75, 0xdcd60dcf, 0xabd13d59,
    0x26d930ac, 0x51de003a, 0xc8d75180, 0xbfd06116, 0x21b4f4b5, 0x56b3c423,
    0xcfba9599, 0xb8bda50f, 0x2802b89e, 0x5f058808, 0xc60cd9b2, 0xb10be924,
    0x2f6f7c87, 0x58684c11, 0xc1611dab, 0xb6662d3d, 0x76dc4190, 0x01db7106,
    0x98d220bc, 0xefd5102a, 0x71b18589, 0x06b6b51f, 0x9fbfe4a5, 0xe8b8d433,
    0x7807c9a2, 0x0f00f934, 0x9609a88e, 0xe10e9818, 0x7f6a0dbb, 0x086d3d2d,
    0x91646c97, 0xe6635c01, 0x6b6b51f4, 0x1c6c6162, 0x856530d8, 0xf262004e,
    0x6c0695ed, 0x1b01a57b, 0x8208f4c1, 0xf50fc457, 0x65b0d9c6, 0x12b7e950,
    0x8bbeb8ea, 0xfcb9887c, 0x62dd1ddf, 0x15da2d49, 0x8cd37cf3, 0xfbd44c65,
    0x4db26158, 0x3ab551ce, 0xa3bc0074, 0xd4bb30e2, 0x4adfa541, 0x3dd895d7,
    0xa4d1c46d, 0xd3d6f4fb, 0x4369e96a, 0x346ed9fc, 0xad678846, 0xda60b8d0,
    0x44042d73, 0x33031de5, 0xaa0a4c5f, 0xdd0d7cc9, 0x5005713c, 0x270241aa,
    0xbe0b1010, 0xc90c2086, 0x5768b525, 0x206f85b3, 0xb966d409, 0xce61e49f,
    0x5edef90e, 0x29d9c998, 0xb0d09822, 0xc7d7a8b4, 0x59b33d17, 0x2eb40d81,
    0xb7bd5c3b, 0xc0ba6cad, 0xedb88320, 0x9abfb3b6, 0x03b6e20c, 0x74b1d29a,
    0xead54739, 0x9dd277af, 0x04db2615, 0x73dc1683, 0xe3630b12, 0x94643b84,
    0x0d6d6a3e, 0x7a6a5aa8, 0xe40ecf0b, 0x9309ff9d, 0x0a00ae27, 0x7d079eb1,
    0xf00f9344, 0x8708a3d2, 0x1e01f268, 0x6906c2fe, 0xf762575d, 0x806567cb,
    0x196c3671, 0x6e6b06e7, 0xfed41b76, 0x89d32be0, 0x10da7a5a, 0x67dd4acc,
    0xf9b9df6f, 0x8ebeeff9, 0x17b7be43, 0x60b08ed5, 0xd6d6a3e8, 0xa1d1937e,
    0x38d8c2c4, 0x4fdff252, 0xd1bb67f1, 0xa6bc5767, 0x3fb506dd, 0x48b2364b,
    0xd80d2bda, 0xaf0a1b4c, 0x36034af6, 0x41047a60, 0xdf60efc3, 0xa867df55,
    0x316e8eef, 0x4669be79, 0xcb61b38c, 0xbc66831a, 0x256fd2a0, 0x5268e236,
    0xcc0c7795, 0xbb0b4703, 0x220216b9, 0x5505262f, 0xc5ba3bbe, 0xb2bd0b28,
    0x2bb45a92, 0x5cb36a04, 0xc2d7ffa7, 0xb5d0cf31, 0x2cd99e8b, 0x5bdeae1d,
    0x9b64c2b0, 0xec63f226, 0x756aa39c, 0x026d930a, 0x9c0906a9, 0xeb0e363f,
    0x72076785, 0x05005713, 0x95bf4a82, 0xe2b87a14, 0x7bb12bae, 0x0cb61b38,
    0x92d28e9b, 0xe5d5be0d, 0x7cdcefb7, 0x0bdbdf21, 0x86d3d2d4, 0xf1d4e242,
    0x68ddb3f8, 0x1fda836e, 0x81be16cd, 0xf6b9265b, 0x6fb077e1, 0x18b74777,
    0x88085ae6, 0xff0f6a70, 0x66063bca, 0x11010b5c, 0x8f659eff, 0xf862ae69,
    0x616bffd3, 0x166ccf45, 0xa00ae278, 0xd70dd2ee, 0x4e048354, 0x3903b3c2,
    0xa7672661, 0xd06016f7, 0x4969474d, 0x3e6e77db, 0xaed16a4a, 0xd9d65adc,
    0x40df0b66, 0x37d83bf0, 0xa9bcae53, 0xdebb9ec5, 0x47b2cf7f, 0x30b5ffe9,
    0xbdbdf21c, 0xcabac28a, 0x53b39330, 0x24b4a3a6, 0xbad03605, 0xcdd70693,
    0x54de5729, 0x23d967bf, 0xb3667a2e, 0xc4614ab8, 0x5d681b02, 0x2a6f2b94,
    0xb40bbe37, 0xc30c8ea1, 0x5a05df1b, 0x2d02ef8d,
  ];

  var frameNb = 0;
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
        if (len > 38) {
          // new format with crc32
          var calc_crc = calculateCRC32(frame, 0, len);
          var provided_crc = UInt32FromBytesBE(frame, len);
          if (calc_crc == provided_crc) {
            return true;
          } else {
            return false;
          }
        }
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
    frameNb++;
    if (eucData.timeWhenConnected != null) {
      var elaspedTime = eucData.timeWhenConnected
        .subtract(new Time.Moment(Time.now().value()))
        .value();
      if (elaspedTime != 0) {
        eucData.BLEReadRate = frameNb / elaspedTime;
      }
    }

    eucData.voltage =
      value.decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
        :offset => 4,
        :endianness => Lang.ENDIAN_BIG,
      }) / 100.0;
    eucData.speed =
      value
        .decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
          :offset => 6,
          :endianness => Lang.ENDIAN_BIG,
        })
        .abs() / 10.0;
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
    if (eucData.useFahrenheit == 1) {
      eucData.temperature = (((value[18] << 8) | value[19]) / 100) * 1.8 + 32.0;
    } else {
      eucData.temperature = ((value[18] << 8) | value[19]) / 100;
    }

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
  var frameNb = 0;

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
        frameNb++;
        if (eucData.timeWhenConnected != null) {
          var elaspedTime = eucData.timeWhenConnected
            .subtract(new Time.Moment(Time.now().value()))
            .value();
          if (elaspedTime != 0) {
            eucData.BLEReadRate = frameNb / elaspedTime;
          }
        }
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

        if (eucData.useFahrenheit == 1) {
          eucData.temperature =
            (decode2bytes(value[12], value[13]) / 100.0) * 1.8 + 32.0;
        } else {
          eucData.temperature = decode2bytes(value[12], value[13]) / 100.0;
        }

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
}
