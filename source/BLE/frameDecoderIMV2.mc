class IMV2Decoder {
  var frameNb = 0;
  var start_dist;

  function frameBuffer(bleDelegate, transmittedFrame) {
    if (
      bleDelegate.queue.lastPacketType.equals("live") &&
      transmittedFrame.size() == 20
    ) {
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
        transmittedFrame
          .decodeNumber(Lang.NUMBER_FORMAT_UINT16, {
            :offset => 5,
            :endianness => Lang.ENDIAN_LITTLE,
          })
          .abs() / 100.0;
      var speed =
        transmittedFrame
          .decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
            :offset => 9,
            :endianness => Lang.ENDIAN_LITTLE,
          })
          .abs() / 100.0;
      if (speed <= 100) {
        //Should investigate if wrong packet or decoding error
        eucData.speed = speed;
      }
      var pwm =
        transmittedFrame
          .decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
            :offset => 13,
            :endianness => Lang.ENDIAN_LITTLE,
          })
          .abs() / 100.0;
      if (pwm < 100.0) {
        //Should investigate if wrong packet or decoding error
        eucData.hPWM = pwm;
      }

      eucData.current =
        transmittedFrame.decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
          :offset => 7,
          :endianness => Lang.ENDIAN_LITTLE,
        }) / 100.0;
    }
    if (
      bleDelegate.queue.lastPacketType.equals("stats") &&
      transmittedFrame.size() == 20
    ) {
      eucData.totalDistance =
        transmittedFrame.decodeNumber(Lang.NUMBER_FORMAT_UINT32, {
          :offset => 5,
          :endianness => Lang.ENDIAN_LITTLE,
        }) / 100.0;

      if (start_dist == null) {
        start_dist = eucData.totalDistance;
      }
      eucData.tripDistance = eucData.totalDistance - start_dist;
    }
    if (bleDelegate.queue.lastPacketType.equals("batStats")) {
      eucData.batteryTemp1 =
        transmittedFrame.decodeNumber(Lang.NUMBER_FORMAT_SINT8, {
          :offset => 9,
          :endianness => Lang.ENDIAN_LITTLE,
        }) + 80.0; //data[4]
      eucData.batteryTemp2 =
        transmittedFrame.decodeNumber(Lang.NUMBER_FORMAT_SINT8, {
          :offset => 17,
          :endianness => Lang.ENDIAN_LITTLE,
        }) + 80.0; //data[12]
    }
  }
}
