class VESCDecoder {
  function decodeint16(byte1, byte2) {
    return (byte1 << 8) | byte2;
  }

  function decodeint32(byte1, byte2, byte3, byte4) {
    return (byte1 << 24) | (byte2 << 16) | (byte3 << 8) | byte4;
  }

  var packetID = 0x2f;
  var packetEnd = 0x03;
  var frame = [0]b;
  var status = "unknown";
  var startDistance = null;

  function frameBuilder(bleDelegate, value) {
    if (value[0] == packetID) {
      status = "append";
      frame = value;
    } else {
      if (status.equals("append")) {
        frame.addAll(value);
      }
    }

    if (value[value.size() - 1] == 0x03) {
      status = "complete";
      var transmittedFrame = frame;
      System.println(transmittedFrame);
      if (transmittedFrame.size() >= 66) { // ensure that packet is complete
        frameBuffer(bleDelegate, transmittedFrame);
      }
      frame = [0]b;
      status = "unknown";
    }
  }

  function frameBuffer(bleDelegate, transmittedFrame) {
    var size = transmittedFrame.size();

    eucData.temperature =
      transmittedFrame.decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
        :offset => 1,
        :endianness => Lang.ENDIAN_BIG,
      }) / 10.0;

    eucData.current =
      transmittedFrame.decodeNumber(Lang.NUMBER_FORMAT_SINT32, {
        :offset => 9,
        :endianness => Lang.ENDIAN_BIG,
      }) / 100.0;

    eucData.hPWM =
      transmittedFrame
        .decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
          :offset => 13,
          :endianness => Lang.ENDIAN_BIG,
        })
        .abs() / 10.0;

    eucData.speed =
      transmittedFrame
        .decodeNumber(Lang.NUMBER_FORMAT_SINT32, {
          :offset => 19,
          :endianness => Lang.ENDIAN_BIG,
        })
        .abs() / 1000.0;

    eucData.voltage =
      transmittedFrame.decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
        :offset => 23,
        :endianness => Lang.ENDIAN_BIG,
      }) / 10.0;

    eucData.battery =
      transmittedFrame.decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
        :offset => 25,
        :endianness => Lang.ENDIAN_BIG,
      }) / 10.0;

    eucData.totalDistance =
      transmittedFrame.decodeNumber(Lang.NUMBER_FORMAT_UINT32, {
        :offset => 62,
        :endianness => Lang.ENDIAN_BIG,
      }) / 1000.0; // in km
    if (startDistance == null) {
      startDistance = eucData.totalDistance;
    }
    eucData.tripDistance = eucData.totalDistance - startDistance;

    /*
    tempMos = decodeint16(packet[1], packet[2]) / 10.0;
    tempMot = decodeint16(packet[3], packet[4]) / 10.0;
    currMot = decodeint32(packet[5], packet[6], packet[7], packet[8]) / 100.0;
    currIn = decodeint32(packet[9], packet[10], packet[11], packet[12]) / 100.0;
    dutyNow = decodeint16(packet[21], packet[22]) / 1000.0;
    rpm = decodeint32(packet[23], packet[24], packet[25], packet[26]);
    voltage = decodeint16(packet[27], packet[28]) / 10.0;
    speed = decodeint32(packet[45], packet[46], packet[47], packet[48]);
    speed_abs = decodeint32(packet[49], packet[50], packet[51], packet[52]);
    */
  }
}
