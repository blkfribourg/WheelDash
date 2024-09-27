import Toybox.Graphics;
import Toybox.WatchUi;
using Toybox.Timer;

using Toybox.System;
class messageView extends WatchUi.View {
  var BleDelegate;
  var textToDisplay;
  var profileNb;
  var popViewDelay = 2000;
  var isDone = false;
  var psDelegate;
  var messageType;
  private var cStrings = {}; // and also cached strings
  function initialize(_BleDelegate, _profileNb, _psDelegate, _messageType) {
    BleDelegate = _BleDelegate;
    profileNb = _profileNb;
    psDelegate = _psDelegate;
    messageType = _messageType;
    /*
    textToDisplay =
      "Profile " +
      profileNb +
      " 1st connection\nPlease turn on your wheel\n and wait for connection\n\n(please ensure only one wheel is ON!)\n\nIf you enjoy this app :\n ko-fi.com/blkfri ;)";
      */
    // }
    View.initialize();
  }

  function onLayout(dc) {
    if (messageType.equals("1stConn")) {
      cStrings[:firstConn] = WatchUi.loadResource(Rez.Strings.firstConnStr);
      cStrings[:connected] = WatchUi.loadResource(Rez.Strings.connectedStr);
      textToDisplay = new WatchUi.Text({
        :text => Lang.format(cStrings[:firstConn], [profileNb]),
        :color => Graphics.COLOR_WHITE,
        :font => Graphics.FONT_XTINY,
        :locX => dc.getWidth() / 2,
        :locY => dc.getHeight() / 2,
        :justification => Graphics.TEXT_JUSTIFY_CENTER |
        Graphics.TEXT_JUSTIFY_VCENTER,
      });
    } else {
      cStrings[:spdLimiter] = WatchUi.loadResource(Rez.Strings.spdLimiterStr);
      textToDisplay = new WatchUi.Text({
        :text => Lang.format(cStrings[:spdLimiter], [profileNb]),
        :color => Graphics.COLOR_WHITE,
        :font => Graphics.FONT_XTINY,
        :locX => dc.getWidth() / 2,
        :locY => dc.getHeight() / 2,
        :justification => Graphics.TEXT_JUSTIFY_CENTER |
        Graphics.TEXT_JUSTIFY_VCENTER,
      });
    }
  }
  // Called when this View is brought to the foreground. Restore
  // the state of this View and prepare it to be shown. This includes
  // loading resources into memory.
  function onShow() {}

  // Update the view
  function onUpdate(dc) {
    //System.println("first");
    if (eucData.paired == true) {
      if (messageType.equals("1stConn")) {
        textToDisplay.setText(Lang.format(cStrings[:connected], [profileNb]));
      } else {
        textToDisplay.setText(cStrings[:spdLimiter]);
      }
      /*
      textToDisplay =
        "Profile " +
        profileNb +
        " connected !\n\nSaving wheel unique identifier";
        */
      popViewDelay = popViewDelay - eucData.updateDelay;

      if (popViewDelay < 0) {
        // eucData.spdLimFeatEnabled
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        WatchUi.pushView(
          psDelegate.getView(),
          psDelegate.getDelegate(),
          WatchUi.SLIDE_IMMEDIATE
        );
      }
    }

    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    dc.clear();
    /*
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

    dc.drawText(
      dc.getWidth() / 2,
      dc.getHeight() / 2,
      Graphics.FONT_XTINY,
      textToDisplay,
      Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
    );*/
    textToDisplay.draw(dc);
  }
}
