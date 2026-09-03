using Toybox.Application.Storage;
import Toybox.Lang;
using Toybox.System;
module profileSelector {
  (:fullMemory)
  function createPSMenu() {
    // System.println(eucData.JSONFetch);
    if (
      !eucData.JSONFetch.equals("done") &&
      !eucData.JSONFetch.equals("local")
    ) {
      return createMenu(
        [
          AppStorage.getSetting("wheelName_p1"),
          AppStorage.getSetting("wheelName_p2"),
          AppStorage.getSetting("wheelName_p3"),
        ],
        "Profile Selection"
      );
    } else {
      //     System.println(getJSONProfileList());
      return createMenu(getJSONProfileList(), "Profile Selection");
    }
  }

  (:lowMemory)
  function createPSMenu() {
    return createMenu(
      [
        AppStorage.getSetting("wheelName_p1"),
        AppStorage.getSetting("wheelName_p2"),
        AppStorage.getSetting("wheelName_p3"),
      ],
      "Profile Selection"
    );
  }

  (:fullMemory)
  function createPSDelegate() {
    if (eucData.JSONFetch.equals("") || eucData.JSONFetch.equals("failed")) {
      //      System.println("Legacy");
      return new PSMenuDelegate();
    } else {
      //     System.println("JSON");
      return new JSONPSMenuDelegate();
    }
  }

  (:lowMemory)
  function createPSDelegate() {
    return new PSMenuDelegate();
  }

  (:fullMemory)
  function getJSONProfileList() {
    var JSONSettingsDict = Storage.getValue("JSONSettings") as Dictionary;
    var JSONSettings = JSONSettingsDict.get("settings") as Dictionary;
    var JSONProfiles = JSONSettingsDict.get("profiles") as Dictionary;

    var profileList = new [eucData.profilesNb] as Array;
    var keys = JSONSettings.keys() as Array;
    for (var i = 0; i < keys.size(); i++) {
      //checking if additionnal profiles:
      var pStrIdx = keys[i].find("wheelName_p");
      if (pStrIdx != null) {
        var pStr = keys[i].substring(pStrIdx + 11, keys[i].length());

        if (pStr != null) {
          if (
            (JSONProfiles.get("p" + pStr) as Dictionary).get("v").equals(true)
          ) {
            var p = pStr.toNumber();

            if (p - 1 < eucData.profilesNb) {
              profileList[p - 1] = (
                JSONSettings.get(keys[i]) as Dictionary
              ).get("v");
            } else {
            }
          }
        }
      }
    }
    return profileList;
  }
}
