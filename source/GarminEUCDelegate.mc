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
  var actionButtonTrigger = null;
  var DFlikeView = null;
  hidden var DFViewOn = false;
  function initialize(
    main_view,
    _menu2,
    _menu2Delegate,
    current_eucBleDelegate,
    q,
    _activityView,
    _actionButtonTrigger
  ) {
    eucBleDelegate = current_eucBleDelegate;
    queue = q;
    menu = _menu2;
    menu2Delegate = _menu2Delegate;
    BehaviorDelegate.initialize();
    mainView = main_view;
    activityView = _activityView;
    actionButtonTrigger = _actionButtonTrigger;
  }

  function onMenu() as Boolean {
    WatchUi.pushView(menu, menu2Delegate, WatchUi.SLIDE_UP);
    return true;
  }
  function onSwipe(swipeEvent as WatchUi.SwipeEvent) {
    if (swipeEvent.getDirection() == WatchUi.SWIPE_UP) {
      goToActivityView();
    }
    if (
      swipeEvent.getDirection() == WatchUi.SWIPE_LEFT &&
      eucData.slideToDFView == true
    ) {
      goToDFView();
    }
    return true;
  }

  function onNextPage() as Boolean {
    return false;
  }

  function onKey(keyEvent as WatchUi.KeyEvent) {
    actionButtonTrigger.triggerAction(
      eucBleDelegate,
      keyEvent.getKey(),
      self,
      queue
    );

    if (keyEvent.getKey().equals(WatchUi.KEY_ESC)) {
      var message = "Exit WheelDash?";
      var dialog = new WatchUi.Confirmation(message);
      var confirmDelegate = new MyConfirmationDelegate();
      WatchUi.pushView(dialog, confirmDelegate, WatchUi.SLIDE_IMMEDIATE);
    }

    return true;
  }

  function getActivityView() {
    return activityView;
  }

  function getDFlikeView() {
    return DFlikeView;
  }

  function getBleDelegate() {
    return eucBleDelegate;
  }
  function unpair() {
    eucBleDelegate.manualUnpair();
  }
  function goToActivityView() {
    //System.println("bringing activity view");
    WatchUi.pushView(
      activityView,
      new ActivityRecordDelegate(activityView),
      WatchUi.SLIDE_UP
    ); // Switch to activity view
  }
  function setDFlikeView(_DFLikeView) {
    DFlikeView = _DFLikeView;
  }
  function goToDFView() {
    if (DFlikeView != null) {
      if (DFViewOn == true) {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        DFViewOn = false;
      } else {
        DFViewOn = true;
        WatchUi.pushView(DFlikeView, self, WatchUi.SLIDE_IMMEDIATE);
      }
    }
  }
  function getMenu2Delegate() {
    return menu2Delegate;
  }
}

class MyConfirmationDelegate extends WatchUi.ConfirmationDelegate {
  function initialize() {
    ConfirmationDelegate.initialize();
  }

  function onResponse(response) {
    if (response == WatchUi.CONFIRM_YES) {
      System.exit();
    }
    return true;
  }
}
