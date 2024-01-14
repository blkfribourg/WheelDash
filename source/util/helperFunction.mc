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
        //System.println("str = " + str);
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

function signedShortFromBytesBE(bytes, starting) {
  if (bytes.size() >= starting + 2) {
    return (
      ((((bytes[starting] & 0xff) << 8) | bytes[starting + 1]) << 16) >> 16
    );
  }
  return 0;
}

function shortFromBytesBE(bytes, starting) {
  if (bytes.size() >= starting + 2) {
    return (
      ((((bytes[starting] & 0xff) << 8) | (bytes[starting + 1] & 0xff)) <<
        16) >>
      16
    );
  }
  return 0;
}

function UInt32FromBytesBE(bytes, starting) {
  if (bytes.size() >= starting + 4) {
    return (
      ((bytes[starting] & 0xff) << 24) |
      ((bytes[starting + 1] & 0xff) << 16) |
      ((bytes[starting + 2] & 0xff) << 8) |
      (bytes[starting + 3] & 0xff)
    );
  }
  return 0;
}

function decode2bytes(byte1, byte2) {
  return (byte1 & 0xff) + (byte2 << 8);
}
function decode4bytes(byte1, byte2, byte3, byte4) {
  return (byte1 << 16) + (byte2 << 24) + byte3 + (byte4 << 8);
}

function xorChkSum(bytes) {
  var chksum = 0;
  for (var i = 0; i < bytes.size(); i++) {
    chksum = chksum ^ bytes[i];
  }
  return chksum;
}
