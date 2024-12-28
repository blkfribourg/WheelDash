import Toybox.Communications;
import Toybox.System;
import Toybox.Lang;
import Toybox.Timer;
using Toybox.WatchUi;
using Toybox.Application.Storage;

function checkSettingsURL() {
  var settingsUrl = AppStorage.getSetting("settingsUrl");
  var uidsize = 10;
  if (settingsUrl.length() > uidsize) {
    var web = new WebSettings();
    var url = settingsUrl.substring(0, settingsUrl.length() - uidsize);
    var uid = settingsUrl.substring(-uidsize, null);
    web.setParams(uid, url);
    web.startFetchTimer();
  }
}
class WebSettings {
  var confirm = false;
  var fetchCnt = 0;
  var fetchTimer = new Timer.Timer();
  var jsonSettings;
  var uid;
  var url;
  var callable = new Lang.Method($, :onReceive);

  function setParams(_uid, _url) {
    uid = _uid;
    url = _url;
  }

  function startFetchTimer() {
    eucData.PSlock = true; // stop profile selector 10 sec timer
    fetchTimer.start(method(:fetch), 1000, false);
  }

  function fetch() {
    var options = {
      :method => Communications.HTTP_REQUEST_METHOD_POST, // set HTTP method
      :headers => {
        // set headers
        "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED,
        //"Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
      },
      // set response type
      :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
    };
    if (Communications has :makeWebRequest) {
      //  System.println(url);
      Communications.makeWebRequest(
        url,
        { "uid" => uid },
        options,
        method(:onReceive)
      );
      fetchCnt++;
    }
  }
  function setSettings(json as Dictionary) {
    if (eucData.profilesNb > 3) {
      Storage.setValue("JSONSettings", json);
      System.println("writing json to local storage"); // saving json to appstorage:
    } else {
      var settings = json.get("settings") as Dictionary;
      var keys = settings.keys() as Array;
      for (var i = 0; i < keys.size(); i++) {
        //System.println(keys[i]);
        var currentKey = settings.get(keys[i]) as Dictionary;
        var type = currentKey.get("t") as String;
        var value = currentKey.get("v") as String;

        if (type.equals("f")) {
          value = value.toFloat();
          // System.println(value);
        }
        if (type.equals("i")) {
          value = value.toNumber();
        }
        try {
          var IQVal = AppStorage.getSetting(keys[i] as String);
          if (IQVal != null) {
            if (!IQVal.equals(value)) {
              AppStorage.setSetting(keys[i] as String, value);
            }
          }
        } catch (e) {
          // System.println(e);
        }
      }
    }
    eucData.settingsChanged = true;
  }
  function settingsChanged(json as Dictionary) {
    // checking if a stored JSON exists :
    var storedJSON = Storage.getValue("JSONSettings") as Dictionary;
    //if stored JSON exists and is the same as the new one, return false
    if (storedJSON != null) {
      if (compareJSON(storedJSON, json) == true) {
        System.println("localJSON is identical");

        return false;
      }
    } else {
      System.println("no localJSON detected");
      Storage.setValue("JSONSettings", json);
    }

    var settings = json.get("settings") as Dictionary;
    //System.print(settings);
    var keys = settings.keys() as Array;
    for (var i = 0; i < keys.size(); i++) {
      //System.println(keys[i]);
      var currentKey = settings.get(keys[i]) as Dictionary;
      var type = currentKey.get("t") as String;
      var value = currentKey.get("v") as String;

      //checking if additionnal profiles:
      var pStrIdx = keys[i].find("_p");
      if (pStrIdx != null) {
        var pStr = keys[i].substring(pStrIdx + 2, null);
        if (pStr != null) {
          if (pStr.toNumber() > eucData.profilesNb) {
            //  System.println("new profile detected:" + pStr);
            eucData.profilesNb = pStr.toNumber(); // updating last profile id
          }
        }
      }
      // if additionnal profiles detected and JSON isn't exisiting on local storage, return true:
      if (eucData.profilesNb > 3 && storedJSON == null) {
        return true;
      }
      if (type.equals("f")) {
        value = value.toFloat();
        // System.println(value);
      }
      if (type.equals("i")) {
        value = value.toNumber();
      }
      try {
        var IQVal = AppStorage.getSetting(keys[i] as String);
        if (IQVal != null) {
          if (!IQVal.equals(value)) {
            //AppStorage.setSetting(keys[i] as String, value);
            return true;
            //eucData.settingsChanged = true;
          }
        }
      } catch (e) {
        // System.println(e);
      }
    }

    return false;
  }
  function confirmUpdate(data) {
    var message = "Settings conflict detected!\nUpdate local?";
    var dialog = new WatchUi.Confirmation(message);
    WatchUi.pushView(
      dialog,
      new SettingConfirmationDelegate(self, data),
      WatchUi.SLIDE_IMMEDIATE
    );
  }
  public function onReceive(
    responseCode as Number,
    data as Dictionary<String, Object?> or String or Null
  ) as Void {
    System.println(responseCode);
    // System.println(data);
    if (responseCode == 200 && data != null) {
      fetchTimer.stop();

      if (settingsChanged(data) == true) {
        confirmUpdate(data);
        return;
      } else {
        eucData.PSlock = false;
      }
    } else {
      if (fetchCnt < 3) {
        startFetchTimer();
      } else {
        eucData.PSlock = false;
      }
    }
  }
  function compareJSON(json1 as Dictionary, json2 as Dictionary) {
    // if jsons are identical returns true, else returns false

    var keys1 = json1.keys() as Array;
    var keys2 = json2.keys() as Array;
    if (keys1.size() != keys2.size()) {
      return false;
    }
    System.println(keys1.size());
    for (var i = 0; i < keys1.size(); i++) {
      var firstLvl = json1.get(keys1[i]) as Dictionary;
      if (firstLvl instanceof Dictionary) {
        var secondLvlKeys = firstLvl.keys();
        for (var j = 0; j < secondLvlKeys.size(); j++) {
          // System.println(secondLvlKeys);
          if (secondLvlKeys instanceof Array) {
            var thirdLvl = firstLvl.get(secondLvlKeys[j]);

            if (thirdLvl instanceof Dictionary) {
              var thirdLvlKeys = thirdLvl.keys();
              if (thirdLvlKeys instanceof Array) {
                for (var k = 0; k < thirdLvlKeys.size(); k++) {
                  var value1 = (
                    (json1.get(keys1[i]) as Dictionary).get(secondLvlKeys[j]) as
                      Dictionary
                  ).get(thirdLvlKeys[k]);
                  var value2 = (
                    (json2.get(keys1[i]) as Dictionary).get(secondLvlKeys[j]) as
                      Dictionary
                  ).get(thirdLvlKeys[k]);

                  if (!value1.equals(value2)) {
                    //System.println("keys " + keys1[i] + " are different");
                    return false;
                  }
                }
              }
            }
          }
          //  System.println(secondLvl);
        }
      } else {
        var value1 = json1.get(keys1[i]);
        var value2 = json2.get(keys1[i]);

        if (!value1.equals(value2)) {
          //System.println("keys " + keys1[i] + " are different");
          return false;
        }
      }
    }
    return true;
  }
}

class SettingConfirmationDelegate extends WatchUi.ConfirmationDelegate {
  var parent;
  var data;

  function initialize(_parent, _data) {
    parent = _parent;
    data = _data;
    ConfirmationDelegate.initialize();
  }

  function onResponse(response) {
    if (response == WatchUi.CONFIRM_YES) {
      //deleting last profile id on storage (to avoid a non existing profile to be loaded) :
      Storage.deleteValue("lastProfile");

      parent.setSettings(data);
    }
    eucData.PSlock = false;

    return true;
  }
}
