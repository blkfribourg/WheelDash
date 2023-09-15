import Toybox.Lang;
using Toybox.StringUtil;
using Toybox.Math;
using Toybox.System;

// convert string to byte, used when sending string command via BLE
function string_to_byte_array(plain_text) {
  var options = {
    :fromRepresentation => StringUtil.REPRESENTATION_STRING_PLAIN_TEXT,
    :toRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,
    :encoding => StringUtil.CHAR_ENCODING_UTF8,
  };
  var result = StringUtil.convertEncodedString(plain_text, options);
  return result;
}

//Just a round function with formating
function valueRound(value, format) {
  var rounded;
  rounded = Math.round(value * 100) / 100;
  return rounded.format(format);
}

//Returns the EUC settings class from the selected EUC brand
function getEUCSettingsDict() {
  if (eucData.wheelBrand == 0) {
    return new gotwayConfig();
  }
  if (eucData.wheelBrand == 1) {
    return new veteranConfig();
  }
  if (eucData.wheelBrand == 2 || eucData.wheelBrand == 3) {
    return new kingsongConfig();
  } else {
    return new dummyConfig();
  }
}

// Generate  Menu
import Toybox.WatchUi;
function createMenu(labels, title) {
  var menu = new WatchUi.Menu2({ :title => title });

  if (labels != null) {
    for (var i = 0; i < labels.size(); i++) {
      menu.addItem(new MenuItem(labels[i], "", labels[i], {}));
    }
    return menu;
  }
  return null;
}

function splitstr(str as Lang.String, char) {
  var stringArray = new [0];
  var strlength = str.length();
  for (var i = 0; i < strlength; i++) {
    var endidx = str.find(char);
    if (endidx != null) {
      var substr = str.substring(0, endidx);
      if (substr != null) {
        stringArray.add(substr);
        var startidx = endidx + 1;
        str = str.substring(startidx, strlength - substr.length());
        System.println("str = " + str);
      }
    } else {
      if (str.length() > 0) {
        stringArray.add(str);
        break;
      } else {
        break;
      }
    }
  }
  return stringArray;
}
