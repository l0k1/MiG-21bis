# gyro compass display logic.
# because i'm dumb. or something.

var l_s = 0;

setlistener("/fdm/jsbsim/systems/gyro-compass/compensation-setting",func{
  l_s = getprop("/fdm/jsbsim/systems/gyro-compass/compensation-setting");
  if ( l_s < 0 ) {
    setprop("/instrumentation/gyro-compass/display_sign",1);
  } else {
    setprop("/instrumentation/gyro-compass/display_sign",0);
  }
  setprop("/instrumentation/gyro-compass/display_num",math.abs(l_s));
  });

