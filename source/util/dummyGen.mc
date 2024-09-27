using Toybox.Math;
using Toybox.System;

function dummyGen() {
  eucData.paired = true;
  /*
  var rd = (Math.rand() % 13) + 54;
  if (rd > 60) {
    eucData.voltage = rd;
  }*/
  eucData.speed = eucData.speed + 1;
  eucData.hPWM = eucData.hPWM + 1;
  eucData.tripDistance = 22.1;

  eucData.totalDistance = 12903.3;
  eucData.voltage = 66.3;

  if (eucData.speed > 120) {
    eucData.speed = 12;
  } else {
    eucData.temperature = 63.2;
  }
  if (eucData.hPWM > 100) {
    eucData.hPWM = 0;
  }
}
