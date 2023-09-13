using Toybox.Application;
using Toybox.Application.Properties;
using Toybox.System;
import Toybox.Lang;

module AppStorage {
  var runtimeDb = {};

  function setSetting(key as String, value) as Void {
    if (Toybox.Application has :Properties) {
      Properties.setValue(key, value);
    } else {
      Application.getApp().setProperty(key, value);
    }
  }

  function getSetting(key as String) as Application.PropertyValueType {
    if (Toybox.Application has :Properties) {
      return Properties.getValue(key);
    } else {
      return Application.getApp().getProperty(key);
    }
  }
}
