using Toybox.Math;
using Toybox.System;

function dummyGen() {
  eucData.paired = true;
  /*
  var rd = (Math.rand() % 13) + 54;
  if (rd > 60) {
    eucData.voltage = rd;
  }*/
  eucData.speed=41.2;
  eucData.tripDistance = 22.1;
  
  eucData.totalDistance = 12903.3;
  eucData.voltage = 66.3;

  if ( eucData.temperature >20){
     eucData.temperature =  eucData.temperature- 0.5;
  }else{
eucData.temperature = 63.2;
  }
}
