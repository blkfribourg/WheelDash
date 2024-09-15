///////////////////////////////////////////////////////////////////////////////
// Engo smartglasses from Activelook BLE UUIDS and profile registration
// Profile registration is called in PSMenuDelegate (Profile Selector)
///////////////////////////////////////////////////////////////////////////////

using Toybox.BluetoothLowEnergy as Ble;
using Toybox.System;

module engoPM {
  var BLE_ENGO_MAIN as Toybox.BluetoothLowEnergy.Uuid =
    Toybox.BluetoothLowEnergy.longToUuid(
      0x0000fef500001000l,
      0x800000805f9b34fbl
    );

  var BLE_SERV_ACTIVELOOK as Toybox.BluetoothLowEnergy.Uuid =
    Toybox.BluetoothLowEnergy.longToUuid(
      0x0783b03e8535b5a0l,
      0x7140a304d2495cb7l
    );
  //! Custom Service (ActiveLook® Commands Interface) Characteristics
  var BLE_CHAR_TX as Toybox.BluetoothLowEnergy.Uuid =
    Toybox.BluetoothLowEnergy.longToUuid(
      0x0783b03e8535b5a0l,
      0x7140a304d2495cb8l
    );
  var BLE_CHAR_RX as Toybox.BluetoothLowEnergy.Uuid =
    Toybox.BluetoothLowEnergy.longToUuid(
      0x0783b03e8535b5a0l,
      0x7140a304d2495cbal
    );
  var BLE_CHAR_FLOW_CONTROL as Toybox.BluetoothLowEnergy.Uuid =
    Toybox.BluetoothLowEnergy.longToUuid(
      0x0783b03e8535b5a0l,
      0x7140a304d2495cb9l
    );
  var BLE_CHAR_GESTURE_EVENT as Toybox.BluetoothLowEnergy.Uuid =
    Toybox.BluetoothLowEnergy.longToUuid(
      0x0783b03e8535b5a0l,
      0x7140a304d2495cbbl
    );
  var BLE_CHAR_TOUCH_EVENT as Toybox.BluetoothLowEnergy.Uuid =
    Toybox.BluetoothLowEnergy.longToUuid(
      0x0783b03e8535b5a0l,
      0x7140a304d2495cbcl
    );
  var BLE_CHAR_USERINPUT = BLE_CHAR_GESTURE_EVENT;
  var engoProfileDef;

  function init() {
    if (eucData.engoTouch == 1) {
      BLE_CHAR_USERINPUT = BLE_CHAR_TOUCH_EVENT;
    } else {
      BLE_CHAR_USERINPUT = BLE_CHAR_GESTURE_EVENT;
    }
    engoProfileDef = {
      :uuid => BLE_SERV_ACTIVELOOK,
      :characteristics => [
        {
          :uuid => BLE_CHAR_TX,
          :descriptors => [Ble.cccdUuid()],
        },
        {
          :uuid => BLE_CHAR_RX,
          :descriptors => [Ble.cccdUuid()],
        },
        {
          :uuid => BLE_CHAR_FLOW_CONTROL,
          :descriptors => [Ble.cccdUuid()],
        },
        {
          :uuid => BLE_CHAR_USERINPUT,
          :descriptors => [Ble.cccdUuid()],
        },
      ],
    };
  }

  function registerProfiles() {
    try {
      Ble.registerProfile(engoProfileDef);
      // System.println("Engo profile OK");
    } catch (e) {
      System.println("e=" + e.getErrorMessage());
    }
  }
}
