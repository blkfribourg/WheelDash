import Toybox.Lang;
import Toybox.System;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;

class GarminEUCMenu2Delegate_generic extends WatchUi.Menu2InputDelegate {
  private var eucBleDelegate = null;
  private var queue = null;
  private var parent_menu = null;
  private var menu as CheckboxMenu?;
  private var delay = 200;
  var requestSubLabelsUpdate = false;
  private var subLabelsRefreshDuration = 2000 / eucData.updateDelay; // ~2 sec
  var main_view;
  var EUCSettingsDict;
  var EUCConfig;
  var EUCStatus;
  var EUCStatusLabels;
  var EUCConfigLabels;

  function initialize(
    current_menu,
    current_eucBleDelegate,
    q,
    m_view,
    _EUCSettingsDict
  ) {
    EUCSettingsDict = _EUCSettingsDict;
    EUCStatus = EUCSettingsDict.getConfigWithStatusDict();
    EUCStatusLabels = EUCSettingsDict.getConfigWithStatusLabels();
    EUCConfig = EUCSettingsDict.getConfig();
    EUCConfigLabels = EUCSettingsDict.getConfigLabels();

    parent_menu = current_menu;
    eucBleDelegate = current_eucBleDelegate;
    queue = q;
    Menu2InputDelegate.initialize();
    main_view = m_view;
    updateSublabels();
  }

  function onBack() {
    requestSubLabelsUpdate = false;
    WatchUi.popView(WatchUi.SLIDE_DOWN);
  }
  function onSelect(item) {
    for (var i = 0; i < EUCConfig.size(); i++) {
      //System.println("label :" + item.getLabel().toString());
      // System.println("item " + i + " : " + EUCConfigLabels[i]);
      if (item.getLabel().toString().equals(EUCConfigLabels[i])) {
        // System.println("Enter " + EUCConfigLabels[i]);
        nestedMenu(EUCConfigLabels[i], EUCConfig[i]);
      }
    }
    //System.println(item.getId().toString());
  }

  function nestedMenu(title, paramsdict) {
    // var menu = new WatchUi.Menu2({:title=>title});
    menu = new WatchUi.CheckboxMenu({ :title => title });
    var delegate;
    var menuKeys = paramsdict.keys();
    var menuVals = paramsdict.values();
    for (var i = 0; i < paramsdict.size(); i++) {
      menu.addItem(
        new CheckboxMenuItem(menuKeys[i], "", menuVals[i], false, {})
      );
    }
    delegate = new GarminEUCsubMenu2Delegate(
      title,
      parent_menu,
      self,
      eucBleDelegate,
      queue
    ); // a WatchUi.Menu2InputDelegate
    WatchUi.pushView(menu, delegate, WatchUi.SLIDE_IMMEDIATE);
    //delayUpdate.stop();
    return true;
  }

  function updateSublabels() {
    if (EUCStatus == null) {
      // System.println("null status dicts");
      return;
    }
    var menuToUpdate = parent_menu;
    //System.println("call update labels");
    if (menuToUpdate != null) {
      for (var i = 0; i < EUCConfigLabels.size(); i++) {
        for (var j = 0; j < EUCStatusLabels.size(); j++) {
          if (menuToUpdate.getItem(i).getLabel().equals(EUCStatusLabels[j])) {
            // System.println("Update item: " + i);
            menuToUpdate
              .getItem(i)
              .setSubLabel(
                EUCStatus[j].keys()[
                  EUCStatus[j]
                    .values()
                    .indexOf(EUCSettingsDict.getWheelSettingsStatus()[j])
                ]
              );
          }
        }
      }
    }
    subLabelsRefreshDuration--;
    if (subLabelsRefreshDuration <= 0) {
      subLabelsRefreshDuration = 20;
      requestSubLabelsUpdate = false;
    }
  }
  function uniqueCheck(parentMenuTitle, item) {
    //System.println(parentMenuTitle);
    for (var i = 0; i < EUCConfig.size(); i++) {
      if (parentMenuTitle.equals(EUCConfigLabels[i])) {
        uncheckExeptItem(item, EUCConfig[i]);
      }
    }
  }
  function uncheckExeptItem(item, paramsdict) {
    for (var i = 0; i < paramsdict.size(); i++) {
      if (item != menu.getItem(i)) {
        var tempItem = menu.getItem(i) as CheckboxMenuItem;
        tempItem.setChecked(false);
      }
    }
  }
  function execute(parentMenuTitle) {
    for (var i = 0; i < EUCConfig.size(); i++) {
      if (parentMenuTitle.equals(EUCConfigLabels[i])) {
        findChecked(parentMenuTitle, EUCConfig[i]);
      }
    }
  }

  function findChecked(parentMenuTitle, paramsdict) {
    for (var i = 0; i < paramsdict.size(); i++) {
      var tempItem = menu.getItem(i) as CheckboxMenuItem;
      if (tempItem.isChecked()) {
        sendCommand(parentMenuTitle, tempItem.getId().toString());
      }
    }
  }
  function sendCommand(fromMenu, cmd) {
    // execute command specific to Gotway/begode
    if (eucData.wheelBrand == 0) {
      if (
        EUCSettingsDict.getConfigToLock().indexOf(fromMenu) != -1 &&
        eucData.correctedSpeed > 2
      ) {
        //moving and locked settting
      } else {
        gotwayMenuCmd(fromMenu, cmd);
        /*
        if (EUCSettingsDict.getConfigToLock().indexOf(fromMenu) != -1) {
          System.println("executing locked setting because not moving");
        } else {
          System.println("executing non-locked setting");
        }*/
      }
    }
    if (eucData.wheelBrand == 1) {
      if (
        EUCSettingsDict.getConfigToLock().indexOf(fromMenu) != -1 &&
        eucData.correctedSpeed > 2
      ) {
        //moving and locked settting
      } else {
        eucBleDelegate.sendCmd(cmd);
        /*
        if (EUCSettingsDict.getConfigToLock().indexOf(fromMenu) != -1) {
          System.println("executing locked setting because not moving");
        } else {
          System.println("executing non-locked setting");
        }*/
      }
    }
    // execute command specific to Kingsong
    if (eucData.wheelBrand == 2) {
      if (
        EUCSettingsDict.getConfigToLock().indexOf(fromMenu) != -1 &&
        eucData.correctedSpeed > 2
      ) {
        //moving and locked settting
      } else {
        kingsongMenuCmd(fromMenu, cmd);
        /*
        if (EUCSettingsDict.getConfigToLock().indexOf(fromMenu) != -1) {
          System.println("executing locked setting because not moving");
        } else {
          System.println("executing non-locked setting");
        }*/
      }
    }
    queue.delayTimer.start(method(:timerCallback), delay, true);
    requestSubLabelsUpdate = true;
  }

  function gotwayMenuCmd(parentMenu, cmd) {
    var command = null;
    var enc_cmd = null;
    if (parentMenu.equals("Leds Mode")) {
      command = "W";
      enc_cmd = string_to_byte_array(command as String);

      queue.add(
        [eucBleDelegate.getChar(), queue.C_WRITENR, enc_cmd],
        eucBleDelegate.getPMService()
      );
      command = "M";
      enc_cmd = string_to_byte_array(command as String);

      queue.add(
        [eucBleDelegate.getChar(), queue.C_WRITENR, enc_cmd],
        eucBleDelegate.getPMService()
      );
      command = cmd;
      enc_cmd = string_to_byte_array(command as String);
      queue.add(
        [eucBleDelegate.getChar(), queue.C_WRITENR, enc_cmd],
        eucBleDelegate.getPMService()
      );
    }
    if (parentMenu.equals("Beep Volume")) {
      command = "W";
      enc_cmd = string_to_byte_array(command as String);

      queue.add(
        [eucBleDelegate.getChar(), queue.C_WRITENR, enc_cmd],
        eucBleDelegate.getPMService()
      );
      command = "B";
      enc_cmd = string_to_byte_array(command as String);

      queue.add(
        [eucBleDelegate.getChar(), queue.C_WRITENR, enc_cmd],
        eucBleDelegate.getPMService()
      );
      command = cmd;
      enc_cmd = string_to_byte_array(command as String);
      queue.add(
        [eucBleDelegate.getChar(), queue.C_WRITENR, enc_cmd],
        eucBleDelegate.getPMService()
      );
    } else {
      eucBleDelegate.sendCmd(cmd);
    }
  }

  function kingsongMenuCmd(parentMenu, cmd) {
    // would be more elegent to reuse fct getEmptyRequest()
    var cmd_frame = [
      0xaa, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x14, 0x5a, 0x5a,
    ]b;
    System.println("empty_frame: " + cmd_frame.toString());
    if (parentMenu.equals("Lights")) {
      cmd_frame[2] = cmd.toNumber() + 0x12;
      cmd_frame[3] = 1;
      cmd_frame[16] = 115;
      System.println("lights_frame: " + cmd_frame.toString());
    }
    if (parentMenu.equals("Strobe Mode")) {
      cmd_frame[2] = cmd.toNumber();
      cmd_frame[16] = 83;
      System.println("strobe_frame: " + cmd_frame.toString());
    }
    if (parentMenu.equals("Leds Mode")) {
      cmd_frame[2] = cmd.toNumber();
      cmd_frame[16] = 108;
      System.println("leds_frame: " + cmd_frame.toString());
    }
    if (parentMenu.equals("Pedal Mode")) {
      cmd_frame[2] = cmd.toNumber();
      cmd_frame[3] = 224;
      cmd_frame[16] = 135;
      cmd_frame[17] = 21;
      System.println("pedal_frame: " + cmd_frame.toString());
    }
    eucBleDelegate.sendRawCmd(cmd_frame);
  }

  function timerCallback() {
    queue.run();
  }
}

/*
//! Custom menu adapted from garmin sdk samples, I was using an icon to identify currently selected item but not showing on my garmin venu -> switched to checkbox items for menu
class CustomEucMenu extends WatchUi.CustomMenu {
    var title="";
    //! Constructor
    //! @param itemHeight The pixel height of menu items rendered by this menu
    //! @param backgroundColor The color for the menu background
    public function initialize(itemHeight as Number, backgroundColor as ColorValue,titleToShow) {
        CustomMenu.initialize(itemHeight, backgroundColor, {:titleItemHeight=>20});
        title=titleToShow;
    }

    //! Draw the menu title
    //! @param dc Device Context
    public function drawTitle(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
        dc.setPenWidth(3);
        dc.drawLine(0, dc.getHeight() - 2, dc.getWidth(), dc.getHeight() - 2);
        dc.setPenWidth(1);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_TINY, title, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

}
//! This is the custom item drawable.
//! It draws the label it is initialized with at the center of the region
class CustomItem extends WatchUi.CustomMenuItem {

    private var _label as String;
    private var _textColor as ColorValue;

    //! Constructor
    //! @param id The identifier for this item
    //! @param label Text to display
    //! @param textColor Color of the text
    public function initialize(id as Symbol, label as String, textColor as ColorValue) {
        CustomMenuItem.initialize(id, {});
        _label = label;
        _textColor = textColor;
    }

    //! Draw the item string at the center of the item.
    //! @param dc Device Context
    public function draw(dc as Dc) as Void {
        var check_bitmap=WatchUi.loadResource($.Rez.Drawables.Check);
        var font = Graphics.FONT_SMALL;
        dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_WHITE);
        dc.clear();

        if (isSelected()) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_LT_GRAY);
            dc.clear();
            dc.drawBitmap(40, (dc.getHeight() / 2)-20, check_bitmap);
        }
        
        dc.setColor(_textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, font, _label, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

     
}
*/
