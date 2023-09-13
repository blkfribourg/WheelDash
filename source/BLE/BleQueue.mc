using Toybox.System as Sys;
using Toybox.BluetoothLowEnergy as Ble;
using Toybox.WatchUi as Ui;

class BleQueue {
  var commDelay = 2;
  var delayTimer = null;
  var run_id = 0;
  enum {
    D_READ,
    D_WRITE,
    C_READ,
    C_WRITER,
    C_WRITENR,
    UPDATE,
  }

  var queue = [];
  var isRunning = false;

  function initialize() {
    delayTimer = new Timer.Timer();
  }

  function add(data, uuid) {
    if (data[0] != null || data[1] == UPDATE) {
      queue.add(data);
      //Sys.println("add OK ? Data = " + data);
    } else {
      //Sys.println("not queued: null char for "+uuid+" fun="+data[1]);
    }
  }

  function run() {
    if (queue.size() == 0) {
      isRunning = false;
      //stopping timer
      delayTimer.stop();
      return;
    }
    isRunning = true;
    var char = queue[0][0];
    if (queue[0][1] == D_READ) {
      var cccd = char.getDescriptor(Ble.cccdUuid());
      cccd.requestRead();
    } else if (queue[0][1] == D_WRITE) {
      var cccd = char.getDescriptor(Ble.cccdUuid());
      cccd.requestWrite(queue[0][2]);
    } else if (queue[0][1] == C_READ) {
      char.requestRead();
    } else if (queue[0][1] == C_WRITER) {
      char.requestWrite(queue[0][2], {
        :writeType => Ble.WRITE_TYPE_WITH_RESPONSE,
      });
    } else if (queue[0][1] == C_WRITENR) {
      //Sys.println("start running queue");
      //Sys.println("queue content "+queue[0][2]);
      char.requestWrite(queue[0][2], { :writeType => Ble.WRITE_TYPE_DEFAULT });
    }
    var autorun = false;

    if (queue.size() > 0) {
      queue = queue.slice(1, queue.size());
    }
  }
}
