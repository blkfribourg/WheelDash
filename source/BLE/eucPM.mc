using Toybox.BluetoothLowEnergy as Ble;
using Toybox.System as Sys;

class eucPM {
  var EUC_SERVICE;
  var EUC_CHAR;
  var EUC_CHAR2;

  private var eucProfileDef;

  function init() {
    eucProfileDef = {
      :uuid => EUC_SERVICE,
      :characteristics => [
        {
          :uuid => EUC_CHAR,
          :descriptors => [Ble.cccdUuid()],
        },
      ],
    };
  }

  function initKS() {
    eucProfileDef = {
      // Set the Profile
      :uuid => EUC_SERVICE,
      :characteristics => [
        {
          // Define the characteristics
          :uuid => EUC_CHAR, // UUID of the first characteristic
          :descriptors => [Ble.cccdUuid()],
        },
        {
          :uuid => EUC_CHAR2, // UUID of the 2nd characteristic
          :descriptors => [Ble.cccdUuid()],
        },
      ],
    };
  }

  function registerProfiles() {
    System.println(eucProfileDef.toString());
    try {
      Ble.registerProfile(eucProfileDef);
    } catch (e) {
      System.println("e=" + e.getErrorMessage());
    }
  }

  function setGotwayOrVeteran() {
    EUC_SERVICE = Ble.longToUuid(0x0000ffe000001000l, 0x800000805f9b34fbl);
    EUC_CHAR = Ble.longToUuid(0x0000ffe100001000l, 0x800000805f9b34fbl);
    self.init();
  }

  function setKingsong() {
    EUC_SERVICE = Ble.longToUuid(0x0000ffe000001000l, 0x800000805f9b34fbl);
    EUC_CHAR = Ble.longToUuid(0x0000ffe100001000l, 0x800000805f9b34fbl);
    EUC_CHAR2 = Ble.longToUuid(0x0000ffe200001000l, 0x800000805f9b34fbl);
    self.initKS();
  }
  function setManager() {
    if (eucData.wheelBrand == 0 || eucData.wheelBrand == 1) {
      // System.println("GW PM");
      setGotwayOrVeteran();
    }
    if (eucData.wheelBrand == 2) {
      setKingsong();
    } else {
    }
  }
}
