import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
using Toybox.Timer;

using Toybox.System;
class messageView extends WatchUi.View {
  var BleDelegate;
  (:fullMemory)
  var textToDisplay;
  var profileNb;
  var popViewDelay;
  var isDone = false;
  var psDelegate;
  var messageType;
  (:fullMemory)
  private var cStrings = ({}) as Dictionary<Lang.Symbol, Lang.String>; // and also cached strings
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
    popViewDelay = 2000;
    View.initialize();
  }

  (:fullMemory)
  function onLayout(dc) {
    if (messageType.equals("1stConn")) {
      var messageX = dc.getWidth() / 2;
      var messageY = dc.getHeight() / 2;
      if (WatchUi has :getSubscreen && WatchUi.getSubscreen() != null) {
        messageX = 68;
        messageY = 98;
      }
      cStrings[:firstConn as Lang.Symbol] =
        WatchUi.loadResource(Rez.Strings.firstConnStr) as Lang.String;
      cStrings[:connected] = WatchUi.loadResource(Rez.Strings.connectedStr);
      textToDisplay = new WatchUi.Text({
        :text => Lang.format(cStrings[:firstConn], [profileNb]),
        :color => Graphics.COLOR_WHITE,
        :font => Graphics.FONT_XTINY,
        :locX => messageX,
        :locY => messageY,
        :justification => Graphics.TEXT_JUSTIFY_CENTER |
        Graphics.TEXT_JUSTIFY_VCENTER,
      });
    }
  }

  (:lowMemory)
  function onLayout(dc) {
    // Avoid loading the long localized strings and allocating WatchUi.Text
    // while the profile selector is still being released.
  }

  // Called when this View is brought to the foreground. Restore
  // the state of this View and prepare it to be shown. This includes
  // loading resources into memory.
  function onShow() {
  }

  // Update the view
  (:fullMemory)
  function onUpdate(dc) {
    if (eucData.paired == true) {
      if (messageType.equals("1stConn")) {
        textToDisplay.setText(Lang.format(cStrings[:connected], [profileNb]));
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
        if (psDelegate != null) {
          // WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
          WatchUi.pushView(
            psDelegate.getView(),
            psDelegate.getDelegate(),
            WatchUi.SLIDE_IMMEDIATE
          );
        }
      }
    }
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    dc.clear();
    textToDisplay.draw(dc);
  }

  (:lowMemory)
  function onUpdate(dc) {
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    dc.clear();
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

    var centerX = dc.getWidth() / 2;
    if (eucData.paired == true) {
      dc.drawText(
        centerX,
        dc.getHeight() / 2,
        Graphics.FONT_XTINY,
        "Wheel connected",
        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
      );
      popViewDelay = popViewDelay - eucData.updateDelay;
      if (popViewDelay < 0 && psDelegate != null) {
        WatchUi.pushView(
          psDelegate.getView(),
          psDelegate.getDelegate(),
          WatchUi.SLIDE_IMMEDIATE
        );
      }
    } else {
      var centerY = dc.getHeight() / 2;
      dc.drawText(centerX, centerY - 22, Graphics.FONT_XTINY,
        "First connection", Graphics.TEXT_JUSTIFY_CENTER);
      dc.drawText(centerX, centerY - 7, Graphics.FONT_XTINY,
        "Turn wheel on", Graphics.TEXT_JUSTIFY_CENTER);
      dc.drawText(centerX, centerY + 8, Graphics.FONT_XTINY,
        "Only one wheel", Graphics.TEXT_JUSTIFY_CENTER);
    }
  }
}

class ECMessageView extends WatchUi.View {
  var textToDisplay;

  var popViewDelay;

  var psDelegate;
  var messageType;
  var WaitMsg;
  function initialize(_psDelegate) {
    psDelegate = _psDelegate;

    popViewDelay = 2000;
    View.initialize();
  }

  function onLayout(dc) {
    var messageX = dc.getWidth() / 2;
    var messageY = dc.getHeight() / 2;
    if (WatchUi has :getSubscreen && WatchUi.getSubscreen() != null) {
      messageX = 68;
      messageY = 98;
    }
    WaitMsg = WatchUi.loadResource(Rez.Strings.ECProfilesStr);
    textToDisplay = new WatchUi.Text({
      :text => Lang.format(WaitMsg, [eucData.fetchCnt + 1]),
      :color => Graphics.COLOR_WHITE,
      :font => Graphics.FONT_XTINY,
      :locX => messageX,
      :locY => messageY,
      :justification => Graphics.TEXT_JUSTIFY_CENTER |
      Graphics.TEXT_JUSTIFY_VCENTER,
    });
  }
  // Called when this View is brought to the foreground. Restore
  // the state of this View and prepare it to be shown. This includes
  // loading resources into memory.
  function onShow() {}

  // Update the view
  function onUpdate(dc) {
    if (
      eucData.JSONFetch.equals("local") ||
      eucData.JSONFetch.equals("failed")
    ) {
      if (eucData.JSONFetch.equals("local")) {
        textToDisplay.setText(
          "Failed to retrieve\nEasy Config Settings\nLoading\nlocal JSON"
        );
        popViewDelay = popViewDelay - eucData.updateDelay;
        if (popViewDelay < 0) {
          WatchUi.switchToView(
            Application.getApp().getPSView(),
            Application.getApp().getPSDelegate(),
            WatchUi.SLIDE_IMMEDIATE
          );
        }
      }
      if (eucData.JSONFetch.equals("failed")) {
        textToDisplay.setText(
          "Failed to retrieve\nEasy Config Settings\nLoading\nIQ configuration"
        );
        popViewDelay = popViewDelay - eucData.updateDelay;
        if (popViewDelay < 0) {
          WatchUi.switchToView(
            Application.getApp().getPSView(),
            Application.getApp().getPSDelegate(),
            WatchUi.SLIDE_IMMEDIATE
          );
        }
      }
    } else {
      textToDisplay.setText(
        Lang.format(WaitMsg, [eucData.fetchCnt + 1]) as Lang.String
      );

      if (eucData.JSONFetch.equals("done")) {
        WatchUi.switchToView(
          Application.getApp().getPSView(),
          Application.getApp().getPSDelegate(),
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
