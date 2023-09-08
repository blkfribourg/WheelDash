import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
using Toybox.System;
using Toybox.Lang;
using Toybox.BluetoothLowEnergy as Ble;
using Toybox.Timer;

class GarminEUCsubMenu2Delegate extends WatchUi.Menu2InputDelegate {
  var fromMenu = null;
  var eucBleDelegate = null;
  var queue = null;
  var delay = 200;
  var parent_delegate = null;
  var parent_menu as CheckboxMenu;

  function initialize(title, parent_m, parent_d, current_eucBleDelegate, q) {
    fromMenu = title;
    eucBleDelegate = current_eucBleDelegate;
    queue = q;
    parent_menu = parent_m;
    parent_delegate = parent_d;
    Menu2InputDelegate.initialize();
  }

  function onSelect(item) {
    parent_delegate.uniqueCheck(fromMenu, item);
  }
  function onDone() {
    parent_delegate.execute(fromMenu);
    WatchUi.popView(WatchUi.SLIDE_DOWN);
  }
}
