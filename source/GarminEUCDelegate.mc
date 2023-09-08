import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.System;
class GarminEUCDelegate extends WatchUi.BehaviorDelegate {
  var eucBleDelegate = null;
  var queue = null;
  var menu = null;
  var mainView = null;
  var activityView = null;
  var menu2Delegate = null;
  function initialize(
    main_view,
    _menu2,
    _menu2Delegate,
    current_eucBleDelegate,
    q
  ) {
    eucBleDelegate = current_eucBleDelegate;
    queue = q;
    menu = _menu2;
    menu2Delegate = _menu2Delegate;
    BehaviorDelegate.initialize();
    mainView = main_view;
    activityView = new ActivityRecordView();
  }

  function onMenu() as Boolean {
    WatchUi.pushView(menu, menu2Delegate, WatchUi.SLIDE_UP);
    return true;
  }

  function onNextPage() as Boolean {
    WatchUi.pushView(
      activityView,
      new ActivityRecordDelegate(activityView),
      WatchUi.SLIDE_UP
    ); // Switch to activity view
    return true;
  }

  function onKey(keyEvent as WatchUi.KeyEvent) {
    if (keyEvent.getKey().equals(WatchUi.KEY_ENTER)) {
      ActionButton.triggerAction(eucBleDelegate);
    }
    if (keyEvent.getKey().equals(WatchUi.KEY_ESC)) {
      WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }

    return true;
  }

  function getActivityView() {
    return activityView;
  }
}
