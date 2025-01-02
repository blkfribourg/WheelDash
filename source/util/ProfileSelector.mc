using Toybox.Application.Storage;
import Toybox.Lang;
using Toybox.System;
module profileSelector {
  function createPSMenu() {
    //System.println("createPSMenu profileNB:" + eucData.profilesNb);
    if (eucData.profilesNb < 4) {
      return createMenu(
        [
          AppStorage.getSetting("wheelName_p1"),
          AppStorage.getSetting("wheelName_p2"),
          AppStorage.getSetting("wheelName_p3"),
        ],
        "Profile Selection"
      );
    } else {
      return createMenu(getJSONProfileList(), "Profile Selection");
    }
  }

  function createPSDelegate() {
    if (eucData.profilesNb < 4) {
      return new PSMenuDelegate();
    } else {
      return new JSONPSMenuDelegate();
    }
  }
  function getJSONProfileList() {
    var JSONSettingsDict = Storage.getValue("JSONSettings") as Dictionary;
    var JSONSettings = JSONSettingsDict.get("settings") as Dictionary;
    var JSONProfiles = JSONSettingsDict.get("profiles") as Dictionary;
    var profileList = new [0];
    var keys = JSONSettings.keys() as Array;
    for (var i = 0; i < keys.size(); i++) {
      //checking if additionnal profiles:
      var pStrIdx = keys[i].find("wheelName_p");
      if (pStrIdx != null) {
        var pStr = keys[i].substring(pStrIdx + 11, null);
        if (pStr != null) {
          if (
            (JSONProfiles.get("p" + pStr) as Dictionary).get("v").equals(true)
          ) {
            profileList.add((JSONSettings.get(keys[i]) as Dictionary).get("v"));
          }
        }
      }
    }
    return profileList;
  }
}
