import Toybox.Lang;
using Toybox.StringUtil;
using Toybox.Math;
using Toybox.System;

// Get a point coord on a circle
function getXY(screenDiam, startingAngle, radius, angle, pos) {
  var x =
    screenDiam / 2 -
    radius * Math.sin(Math.toRadians(startingAngle - angle * pos));
  var y =
    screenDiam / 2 -
    radius * Math.cos(Math.toRadians(startingAngle - angle * pos));
  return [x, y];
}

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
  if (value == null) {
    return "--";
  } else {
    var rounded;
    rounded = Math.round(value * 100) / 100;
    return rounded.format(format);
  }
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
  }
  if (eucData.wheelBrand == 4 || eucData.wheelBrand == 5) {
    return new inmotionConfig();
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
      (((bytes[starting] & 0xff) << 24) |
        ((bytes[starting + 1] & 0xff) << 16) |
        ((bytes[starting + 2] & 0xff) << 8) |
        (bytes[starting + 3] & 0xff)) &
      0xffffffffl
    ).toNumber();
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

function kmToMiles(value) {
  return value * 0.621371192;
}

// varia sim
class fakeVariaTarget {
  var range = 0;
  var threat = 0;
  var threatSide = 0;
  var speed = 0;

  function assign() {
    range = random(0, 100);
    speed = random(0, 25);
    threat = 1;
    threatSide = 0;
  }
}

function fakeVaria(vehiculeNb) {
  var fakeTargetArray = [];

  for (var i = 0; i < 8; i++) {
    var target = new fakeVariaTarget();
    if (i < vehiculeNb) {
      target.assign();
    }
    fakeTargetArray.add(target);
  }
  return fakeTargetArray;
}

function variaMove(targetArray) {
  // System.println(targetArray.size());
  for (var i = 0; i < targetArray.size(); i++) {
    var remainingDist = targetArray[i].range - targetArray[i].speed / 5;
    if (remainingDist > 0) {
      targetArray[i].range = remainingDist;
    } else {
      if (i + 1 < targetArray.size() - 1) {
        targetArray[i].range = targetArray[i + 1].range;
        targetArray[i].speed = targetArray[i + 1].speed;
        targetArray[i].threat = targetArray[i + 1].threat;
      } else {
        targetArray[i].range = 0;
        targetArray[i].speed = 0;
        targetArray[i].threat = 0;
      }
    }
  }
  var tgNb = 0;
  for (var i = 0; i < targetArray.size(); i++) {
    if (targetArray[i].threat != 0) {
      tgNb = tgNb + 1;
    }
  }
  eucData.variaTargetNb = tgNb;

  //targetArray.remove(new fakeVariaTarget());

  return targetArray;
}
function random(min, max) {
  return (Math.rand() % max) + 1;
}

//Speed limiter
function setWDTiltBackVal(speed) {
  eucData.WDtiltBackSpd = speed;
  if (eucData.currentProfile != null) {
    var settingName = "tiltbackSpeed_p" + eucData.currentProfile;
    AppStorage.setSetting(settingName, speed);
  }
}
function speedLimiter(queue, bleDelegate, limit) {
  // System.println("Tiltback: " + limit);
  if (eucData.wheelBrand == 0) {
    var data;
    if (limit != 0) {
      queue.add([bleDelegate.getChar(), string_to_byte_array("W")]);
      queue.add([bleDelegate.getChar(), string_to_byte_array("Y")]);
      data = [limit / 10 + 48]b;
      queue.add([bleDelegate.getChar(), data]);
      data = [(limit % 10) + 48]b;
      queue.add([bleDelegate.getChar(), data]);
      queue.add([bleDelegate.getChar(), string_to_byte_array("b" as String)]);
    } else {
      queue.add([bleDelegate.getChar(), [0x22]b]);
      queue.add([bleDelegate.getChar(), string_to_byte_array("b" as String)]);
    }
  }
  if (eucData.wheelBrand == 2 || eucData.wheelBrand == 3) {
    var data = [
      0xaa, 0x55, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x31, 0x32,
      0x33, 0x34, 0x35, 0x36, 0x85, 0x14, 0x5a, 0x5a,
    ]b;
    if (eucData.KSAlarm1Speed != null) {
      data[2] = eucData.KSAlarm1Speed;
    }
    if (eucData.KSAlarm2Speed != null) {
      data[4] = eucData.KSAlarm2Speed;
    }
    if (eucData.KSAlarm3Speed != null) {
      data[6] = eucData.KSAlarm3Speed;
    }

    data[8] = limit;

    queue.add([bleDelegate.getChar(), data]);
  }
  if (eucData.wheelBrand == 4 || eucData.wheelBrand == 5) {
    var data = [0xaa, 0xaa, 0x14, 0x04, 0x60, 0x21, 0x00, 0x00, 0x00]b;
    data[6] = (limit * 100) & 0xff;
    data[7] = ((limit * 100) >> 8) & 0xff;
    data[8] = xorChkSum(data.slice(0, data.size() - 1));
    queue.flush();
    queue.add([bleDelegate.getCharW(), data]);
  }
  eucData.tiltBackSpeed = limit;
}

//engo

function arrayToRawCmd(str_bytes) {
  return Toybox.StringUtil.convertEncodedString(str_bytes, {
    :fromRepresentation => Toybox.StringUtil.REPRESENTATION_STRING_HEX,
    :toRepresentation => Toybox.StringUtil.REPRESENTATION_BYTE_ARRAY,
  });
}

function encodeint16(val) {
  return [(val >> 8) & 0xff, val & 0xff]b;
}
function getWriteCmd(text, x, y, r, f, c) {
  var hexText = getHexText(text, 0, 0);

  var cmd = [0xff, 0x37, 0x00, 0x0d + hexText.size()]b;
  cmd.addAll(encodeint16(x));
  cmd.addAll(encodeint16(y)); // to finish, add X int16, Y int8
  cmd.add(r);
  cmd.add(f);
  cmd.add(c);
  cmd.addAll(hexText);
  cmd.add(0x00);
  cmd.add(0xaa);
  return cmd;
}

function getPageCmd(payload, pageId) {
  var cmd = [0xff, 0x83, 0x00, payload.size() + 6, pageId]b;
  cmd.addAll(payload);
  cmd.add(0xaa);
  return cmd;
}

function getHexText(text, lpadding, rpadding) {
  var hexText = Toybox.StringUtil.convertEncodedString(text, {
    :fromRepresentation => Toybox.StringUtil.REPRESENTATION_STRING_PLAIN_TEXT,
    :toRepresentation => Toybox.StringUtil.REPRESENTATION_BYTE_ARRAY,
  });
  var textLength = text.length();
  System.println(textLength);
  if (lpadding > 0) {
    var leftPadding = []b;
    for (var i = 0; i < lpadding - textLength; i++) {
      leftPadding.add(0x24);
      //  System.print("left");
    }
    hexText = leftPadding.addAll(hexText);
    // System.println(hexText);
  }
  if (rpadding > 0) {
    for (var i = 0; i < rpadding; i++) {
      hexText.add(0x24);
    }
  }
  return hexText;
}

function pagePayload(textArray) {
  var payload = []b;
  for (var i = 0; i < textArray.size(); i++) {
    payload.addAll(textArray[i]);
    payload.add(0x00);
  }
  //System.println("payload: " + payload);
  return payload;
}
function getJson(symbol) {
  return WatchUi.loadResource(Rez.JsonData[symbol]);
}
