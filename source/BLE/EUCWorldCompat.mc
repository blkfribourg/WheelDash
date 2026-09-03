import Toybox.Communications;
import Toybox.System;
import Toybox.Lang;
var options = {
  :method => Communications.HTTP_REQUEST_METHOD_GET, // set HTTP method
  :headers => {
    // set headers
    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED,
  },
  // set response type
  :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
};
var callable = new Lang.Method($, :onReceive);
var api =
  "http://127.0.0.1:8080/api/values?filter=vba|vsp|vdi|vsmg|vsp|vte|vvo|vdt|vcu&attrs=0";
var main = "http://127.0.0.1:8281/main";
var distance = "http://127.0.0.1:8281/distance";
var current = "http://127.0.0.1:8281/current";
var voltage = "http://127.0.0.1:8281/voltage";
var call_cpt = null;
function EUCWorldCompat() {
  if (eucData.useEUCWorldAPI == true) {
    // System.println("API");
    makeRequest(api);
  } else {
    if (call_cpt == null) {
      makeRequest(voltage);
      makeRequest(distance);
    } else {
      call_cpt = call_cpt + 1;
      if (call_cpt == 5) {
        makeRequest(voltage);
        makeRequest(distance);
        makeRequest(current);
      } else {
        makeRequest(main);
      }
      if (call_cpt > 5) {
        call_cpt = 0;
      }
    }
  }
}
function makeRequest(url) {
  // available -> main / power / duration / temperature / current / voltage /distance /batteryLevel /energy /safetyMargin /speed
  if (Communications has :makeWebRequest) {
    Communications.makeWebRequest(url, null, options, callable);
  }
}
function onReceive(responseCode, data) {
  // System.println(responseCode);
  //System.println(data);
  if (responseCode == 200 && data != null) {
    if (eucData.useEUCWorldAPI == true) {
      parseAPIJSON(data);
    } else {
      eucData.fVal = data.get("f").toNumber();
      if (eucData.fVal == 5 || eucData.fVal == 1) {
        eucData.paired = true;
        if (call_cpt == null) {
          call_cpt = 0;
        }
        setEUCWorldValues(data);
      }
      if (eucData.fVal == 4 || eucData.fVal == 0) {
        eucData.paired = false;
      }
    }
  }
}

function setEUCWorldValues(dict) {
  if (dict.keys().indexOf("vsp") != -1) {
    //main
    eucData.battery = dict.get("vba").toNumber();
    eucData.tripDistance = dict.get("vdi").toFloat();
    eucData.hPWM = 100 - dict.get("vsmg").toFloat();
    eucData.speed = dict.get("vsp").toFloat();
    eucData.temperature = dict.get("vte").toFloat();
  }
  if (dict.keys().indexOf("vvo") != -1) {
    //voltage
    eucData.voltage = dict.get("vvo").toFloat();
  }
  if (dict.keys().indexOf("vdt") != -1) {
    //distance
    eucData.totalDistance = dict.get("vdt").toFloat();
  }
  if (dict.keys().indexOf("vcu") != -1) {
    //current
    eucData.current = dict.get("vcu").toFloat();
  }
  //a ?
  //m ?
  //pba : phone battery
  //vbacv : single cell voltage
  // vbch : ?
  //vba : EUC bat %
  //vbx : EUC bat % max
  //vbm : EUC bat % min
  //vdi : EUC distance
  //veca : Avg Energy Consumption
  //vsmg : safety margin
  //vsmn : safety margin min
  //vsp : speed ?
  //vsa : avg speed
  //vsr ? avg rding speed
  //vsx ? top speed
  //vte ? temp
  //vtx ? max temp
  //vtn ? min temp
}
function parseAPIJSON(data) {
  var vba = data.get("vba").get("v");
  var vsp = data.get("vsp").get("v");
  var vdi = data.get("vdi").get("v");
  var vsmg = data.get("vsmg").get("v");
  var vte = data.get("vte").get("v");
  var vvo = data.get("vvo").get("v");
  var vdt = data.get("vdt").get("v");
  var vcu = data.get("vcu").get("v");
  if (vba != null) {
    eucData.battery = vba.toNumber();
    eucData.paired = true;
  } else {
    eucData.paired = false;
  }
  if (vsp != null) {
    eucData.speed = vsp.toFloat();
  }

  if (vdi != null) {
    eucData.tripDistance = vdi.toFloat();
  }
  if (vsmg != null) {
    eucData.hPWM = 100 - vsmg.toFloat();
  }

  if (vte != null) {
    eucData.temperature = vte.toFloat();
  }
  if (vvo != null) {
    eucData.voltage = vvo.toFloat();
  }
  if (vdt != null) {
    eucData.totalDistance = vdt.toFloat();
  }
  if (vcu != null) {
    eucData.current = vcu.toFloat();
  }
}
