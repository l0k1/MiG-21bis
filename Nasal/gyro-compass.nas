# gyro compass display logic.
# because i'm dumb. or something.

var l_s = 0;

setlistener("/instrumentation/gyro-compass/latitude-setting",func{
  l_s = getprop("/instrumentation/gyro-compass/latitude-setting");
  if ( l_s < 0 ) {
    setprop("/instrumentation/gyro-compass/display_sign",1);
  } else {
    setprop("/instrumentation/gyro-compass/display_sign",0);
  }
  setprop("/instrumentation/gyro-compass/display_num",math.abs(l_s));
  });

