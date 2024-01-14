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
        }) + 80; //data[4]
      eucData.batteryTemp2 =
        transmittedFrame.decodeNumber(Lang.NUMBER_FORMAT_SINT8, {
          :offset => 17,
          :endianness => Lang.ENDIAN_LITTLE,
        }) + 80; //data[12]
    }
  }
}
/*

        var updateStep = 0;
        var stateCon = 0;

        private static byte calcCheck(byte[] buffer) {

            int check = 0;
            for (byte c : buffer) {
                check = (check ^ c) & 0xFF;
            }
            return (byte) check;
        }

        public static Message getCarType() {
            Message msg = new Message();
            msg.flags = Flag.Initial.getValue();
            msg.command = Command.MainInfo.getValue();
            msg.data = new byte[]{(byte)0x01};
            return msg;
        }
       
            function IMv2Callback() {
                if (updateStep == 0) {
                    if (stateCon == 0) {
                        // replace with blequeue add + trigger 
                        // getCarType is message with Flag = 0x11
                        //                       with command = 0x02
                        //                       and data = 0x01
                        ->170 170 17 2 1 +check

                        //message is encapsulated with 0xAA 0xAA +  

                        // buff.write(flags);
                        //buff.write(data.length+1);
                        //buff.write(command);
            try {       //buffer.write(data);

                        // + checksum : 
            try {       
                buff.write(data);
            } catch (IOException e) {
                e.printStackTrace();
            }
            return buff.toByteArray();
                        if (WheelData.getInstance().bluetoothCmd(Message.getCarType().writeBuffer())) {
                            Timber.i("Sent car type message");
                        } else updateStep = 35;

                    } else if (stateCon == 1) {
                        if (WheelData.getInstance().bluetoothCmd(Message.getSerialNumber().writeBuffer())) {
                            Timber.i("Sent s/n message");
                        } else updateStep = 35;

                    } else if (stateCon == 2) {
                        if (WheelData.getInstance().bluetoothCmd(Message.getVersions().writeBuffer())) {
                            stateCon += 1;
                            Timber.i("Sent versions message");
                        } else updateStep = 35;

                    } else if (settingCommandReady) {
    					if (WheelData.getInstance().bluetoothCmd(settingCommand)) {
                            settingCommandReady = false;
                            requestSettings = true;
                            Timber.i("Sent command message");
                        } else updateStep = 35; // after +1 and %10 = 0
    				} else if (stateCon == 3 | requestSettings) {
                        if (WheelData.getInstance().bluetoothCmd(Message.getCurrentSettings().writeBuffer())) {
                            stateCon += 1;
                            Timber.i("Sent unknown data message");
                        } else updateStep = 35;

                    }
                    else if (stateCon == 4) {
                        if (WheelData.getInstance().bluetoothCmd(Message.getUselessData().writeBuffer())) {
                            Timber.i("Sent useless data message");
                            stateCon += 1;
                        } else updateStep = 35;

                    }
                    else if (stateCon == 5) {
                        if (WheelData.getInstance().bluetoothCmd(Message.getStatistics().writeBuffer())) {
                            Timber.i("Sent statistics data message");
                            stateCon += 1;
                        } else updateStep = 35;

                    }
                    else  {
                        if (WheelData.getInstance().bluetoothCmd(InmotionAdapterV2.Message.getRealTimeData().writeBuffer())) {
                            Timber.i("Sent realtime data message");
                            stateCon = 5;
                        } else updateStep = 35;

                    }


				}
                updateStep += 1;
                updateStep %= 10;
                Timber.i("Step: %d", updateStep);
            }
        };
       // keepAliveTimer = new Timer();
        //keepAliveTimer.scheduleAtFixedRate(timerTask, 100, 25);
    
}*/
