///////////////////////////////////////////////////////////////////////////////
// EUCs (Gotway/Begode - Leaperkim - Kingsong - Inmotion) BLE UUIDS and profile registration
///////////////////////////////////////////////////////////////////////////////

using Toybox.BluetoothLowEnergy as Ble;
using Toybox.System as Sys;

module eucPM {
  var EUC_SERVICE;
  var EUC_CHAR;
  var EUC_CHAR2;
  var EUC_SERVICE_W;
  var EUC_CHAR_W;
  var OLD_KS_ADV_SERVICE;
  var eucProfileDef;

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
  function initInmotionV2orVESC() {
    eucProfileDef = {
      // Set the Profile
      :uuid => EUC_SERVICE,
      :characteristics => [
        {
          // Define the characteristics
          :uuid => EUC_CHAR_W, // UUID of the first characteristic
          :descriptors => [Ble.cccdUuid()],
        },
        {
          // Define the characteristics
          :uuid => EUC_CHAR, // UUID of the first characteristic
          :descriptors => [Ble.cccdUuid()],
        },
      ],
    };
  }
  function registerProfiles() {
    //System.println(eucProfileDef.toString());
    try {
      Ble.registerProfile(eucProfileDef);
    } catch (e) {
      //System.println("e=" + e.getErrorMessage());
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

  function setOldKingsong() {
    EUC_SERVICE = Ble.longToUuid(0x0000ffe000001000l, 0x800000805f9b34fbl);
    EUC_CHAR = Ble.longToUuid(0x0000ffe100001000l, 0x800000805f9b34fbl);
    OLD_KS_ADV_SERVICE = Ble.longToUuid(
      0x0000fff000001000l,
      0x800000805f9b34fbl
    );
    self.init();
  }
  function setInmotionV2orVESC() {
    EUC_SERVICE = Ble.longToUuid(0x6e400001b5a3f393l, 0xe0a9e50e24dcca9el);
    EUC_CHAR = Ble.longToUuid(0x6e400003b5a3f393l, 0xe0a9e50e24dcca9el);
    EUC_CHAR_W = Ble.longToUuid(0x6e400002b5a3f393l, 0xe0a9e50e24dcca9el);

    self.initInmotionV2orVESC();
  }

  function setManager() {
    if (eucData.wheelBrand == 0 || eucData.wheelBrand == 1) {
      // System.println("GW PM");
      setGotwayOrVeteran();
    }
    if (eucData.wheelBrand == 2) {
      setKingsong();
    }
    if (eucData.wheelBrand == 3) {
      setOldKingsong();
    }
    if (eucData.wheelBrand == 4 || eucData.wheelBrand == 5) {
      setInmotionV2orVESC();
    } else {
    }
  }
}
