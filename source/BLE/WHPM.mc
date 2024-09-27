///////////////////////////////////////////////////////////////////////////////
// DIY bluetooth horn (called WheelHorn, need to publish source and doc :) ) BLE UUIDS and profile registration
// Profile registration is called in PSMenuDelegate (Profile Selector)
///////////////////////////////////////////////////////////////////////////////

using Toybox.BluetoothLowEnergy as Ble;
using Toybox.System as Sys;

module hornPM {
  var WH_SERVICE = Ble.longToUuid(0x0000ffe0484f524el, 0x800000805f9b34fbl);
  var WH_CHAR_W = Ble.longToUuid(0x0000ffe1484f524el, 0x800000805f9b34fbl);

  var WHProfileDef = {
    :uuid => WH_SERVICE,
    :characteristics => [
      {
        :uuid => WH_CHAR_W,
        :descriptors => [Ble.cccdUuid()],
      },
    ],
  };

  function registerProfiles() {
    //System.println(eucProfileDef.toString());
    try {
      Ble.registerProfile(WHProfileDef);
    } catch (e) {
      //System.println("e=" + e.getErrorMessage());
    }
  }
}
