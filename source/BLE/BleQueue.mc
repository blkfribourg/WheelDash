///////////////////////////////////////////////////////////////////////////////
// This file contains everything relative to queueing system for BLE requests.
// It is used each time there is more than one command to send, but it could
// probably be replaced by another method : check onCharacteristicWrite in
// GarminEUCBleDelegate.mc file. It allows stacking commands without a queueing
// system.
//
// The queue is also used when I have to send periodic requests, like for
// Inmotion EUCs
///////////////////////////////////////////////////////////////////////////////

using Toybox.System as Sys;
using Toybox.BluetoothLowEnergy as Ble;
using Toybox.WatchUi as Ui;

class BleQueue {
  var delayTimer = null; // queue will be executer every delayTimer
  var run_id = 0; // debug variable

  var queue = [];
  var isRunning = false;

  // Specific to Inmotion EUCs ///////////////
  // Related to periodic requests
  var reqLiveData;
  var sendAlive;
  var reqStats;
  var reqBatStats;
  var lastPacketType = "live";
  var UUID;
  var reqStatsTiming = 0;
  var reqBatStatsTiming = 3;
  var batStatsCounter = 0;
  ////////////////////////////////////////////

  function initialize() {
    delayTimer = new Timer.Timer();
  }

  function add(data, uuid) {
    if (data[0] != null) {
      queue.add(data);
      //Sys.println("add OK ? Data = " + data);
    } else {
      //Sys.println("not queued: null char for "+uuid+" fun="+data[1]);
    }
  }

  function run() {
    if (queue.size() == 0) {
      // Inmotion Specific : when queue is empty send the periodic request packets
      if (eucData.wheelBrand == 4 || eucData.wheelBrand == 5) {
        if (reqLiveData != null && UUID != null && reqStats != null) {
          reqStatsTiming = reqStatsTiming - 1;
          if (reqBatStats != null) {
            reqBatStatsTiming = reqBatStatsTiming - 1;
          }
          if (reqStatsTiming <= 0 && reqBatStatsTiming <= 0) {
            //Skipping reqBatStatsTiming to avoid to request consecutively Stats and Batstats, that would cause a freeze of 400ms+ because not requesting live during this lapse of time.
            reqBatStatsTiming = 256;
          }
          // Requesing stats (to get total mileage)
          // That's a workaround as Garmin MTU is limited to 20 bytes and is trimming BLE packets (information loss, Inmotion wheels refuses MTU size request so no luck)
          if (reqStatsTiming < 0) {
            lastPacketType = "stats";
            add(reqStats, UUID);
            reqStatsTiming = 48;
          }
          // Requesing battery statistics (to get battery temperature, again workaround to display battery temperature instead of controler temp
          // because controler temperature is not available due to MTU issue)
          if (reqBatStatsTiming < 0) {
            lastPacketType = "batStats";
            add(reqBatStats, UUID);
            reqBatStatsTiming = 256;
            batStatsCounter = batStatsCounter + 1;
          }
          // Requesting live data
          if (queue.size() == 0) {
            lastPacketType = "live";
            add(reqLiveData, UUID);
          }
        }
        //System.println(lastPacketType);
        autoRestart();
      } else {
        isRunning = false;
        //stopping timer
        // System.println("Stopping timer, queue size: " + queue.size());

        delayTimer.stop();

        return;
      }
    }

    isRunning = true;
    var char = queue[0][0];
    //writing BLE request
    try {
      char.requestWrite(queue[0][1], {
        :writeType => Ble.WRITE_TYPE_DEFAULT,
      });

      run_id = run_id + 1;
    } catch (e instanceof Toybox.Lang.Exception) {
      //System.println(e.getErrorMessage());
    }
    // removing the sent request from the queue
    if (queue.size() > 0) {
      queue = queue.slice(1, queue.size());
    }
  }
  // autorearm of the queue (for continious execution, used for Inmotion EUCs)
  function autoRestart() {
    delayTimer.start(method(:run), eucData.BLECmdDelay, false);
  }
  // clearing queue content
  function flush() {
    if (queue.size() != 0) {
      queue = [];
      delayTimer.stop();
    }
  }
}
