using Toybox.Math;
using Toybox.System;

function dummyGen() {
  eucData.paired = true;
  var rd = (Math.rand() % 13) + 54;
  if (rd > 60) {
    eucData.voltage = rd;
  }
}
