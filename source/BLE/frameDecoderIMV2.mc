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
      // V11 & V12
      if (eucData.wheelBrand == 4) {
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
      // V11Y V13 V14
      if (eucData.wheelBrand == 5) {
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
              :offset => 13,
              :endianness => Lang.ENDIAN_LITTLE,
            })
            .abs() / 100.0;
        if (speed <= 100) {
          //Should investigate if wrong packet or decoding error
          eucData.speed = speed;
        }
        /* OUT OF ARRAY 
        var pwm =
          transmittedFrame
            .decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
              :offset => 19,
              :endianness => Lang.ENDIAN_LITTLE,
            })
            .abs() / 100.0;
        if (pwm < 100.0) {
          //Should investigate if wrong packet or decoding error
          eucData.hPWM = pwm;
        }
*/
        eucData.current =
          transmittedFrame.decodeNumber(Lang.NUMBER_FORMAT_SINT16, {
            :offset => 7,
            :endianness => Lang.ENDIAN_LITTLE,
          }) / 100.0;
      }
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
    if (bleDelegate.queue.lastPacketType.equals("settings")) {
      eucData.tiltBackSpeed =
        transmittedFrame.decodeNumber(Lang.NUMBER_FORMAT_UINT16, {
          :offset => 6,
          :endianness => Lang.ENDIAN_LITTLE,
        }) / 100.0; //data[4]
    }
  }
}

/*
   Timber.i("Parse V13 realtime stats data");
            WheelData wd = WheelData.getInstance();
            int mVoltage = MathsUtil.shortFromBytesLE(data, 0);
            int mCurrent = MathsUtil.signedShortFromBytesLE(data, 2);
            //int mSpeed = MathsUtil.signedShortFromBytesLE(data, 4);
            int mSomeThing2 = MathsUtil.signedShortFromBytesLE(data, 4);
            int mPitchAngle = MathsUtil.signedShortFromBytesLE(data, 6); //not sure
            int mSpeed = MathsUtil.signedShortFromBytesLE(data, 8);
            //int mSomething0 = MathsUtil.signedShortFromBytesLE(data, 10);
            long mMileage = MathsUtil.intFromBytesRevLE(data, 10); // not sure
            int mPwm = MathsUtil.signedShortFromBytesLE(data, 14);
            int mBatPower = MathsUtil.signedShortFromBytesLE(data, 16);
            int mTorque = MathsUtil.signedShortFromBytesLE(data, 18); // not sure
            int mPitchAimAngle = MathsUtil.signedShortFromBytesLE(data, 20); // not sure
            int mMotPower = MathsUtil.signedShortFromBytesLE(data, 22); // not sure
            int mRollAngle = MathsUtil.signedShortFromBytesLE(data, 24); // not sure

            //int mRemainMileage = MathsUtil.shortFromBytesLE(data, 26) * 10;
            //int mSomeThing180 = MathsUtil.shortFromBytesLE(data, 28); // always 18000
            //int mDynamicSpeedLimit = MathsUtil.shortFromBytesLE(data, 30);
            //int mDynamicCurrentLimit = MathsUtil.shortFromBytesLE(data, 32);

            int mBatLevel1 = MathsUtil.shortFromBytesLE(data, 34);
            int mBatLevel2 = MathsUtil.shortFromBytesLE(data, 36);
            int mSomeThing200_1 = MathsUtil.shortFromBytesLE(data, 38);
            int mDynamicSpeedLimit = MathsUtil.shortFromBytesLE(data, 40);
            int x5 = MathsUtil.shortFromBytesLE(data, 42);
            int x6 = MathsUtil.shortFromBytesLE(data, 44);
            int x7 = MathsUtil.shortFromBytesLE(data, 46);
            int mSomeThing200_2 = MathsUtil.shortFromBytesLE(data, 48);
            int mDynamicCurrentLimit = MathsUtil.shortFromBytesLE(data, 50);
            int mSomeThing380 = MathsUtil.shortFromBytesLE(data, 52);


            int mMosTemp = (data[58] & 0xff) + 80 - 256;
            int mMotTemp = (data[59] & 0xff) + 80 - 256;
            int mBatTemp = (data[60] & 0xff) + 80 - 256; // 0
            int mBoardTemp = (data[61] & 0xff) + 80 - 256;
            int mCpuTemp = (data[62] & 0xff) + 80 - 256;
            int mImuTemp = (data[63] & 0xff) + 80 - 256;
            int mLampTemp = (data[64] & 0xff) + 80 - 256; // 0


*/
