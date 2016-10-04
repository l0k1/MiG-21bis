###################################################################################
## Author: pinto			                                                     ##
##                                                                               ##
## Version 1.0             License: GPL 2.0+                                     ##
##                                                                               ##
###################################################################################


var clamp = func(v, min, max) { v < min ? min : v > max ? max : v }

var x_ft_s2_path = "/fdm/jsbsim/accelerations/a-pilot-x-ft_sec2";
var y_ft_s2_path = "/fdm/jsbsim/accelerations/a-pilot-y-ft_sec2";
var z_ft_s2_path = "/fdm/jsbsim/accelerations/a-pilot-z-ft_sec2";

var cv_x_offset_path = "/sim/current-view/x-offset-m";
var cv_y_offset_path = "/sim/current-view/y-offset-m";
var cv_z_offset_path = "/sim/current-view/z-offset-m";

var cv_x = 0;
var cv_y = 0;
var cv_z = 0;
var cv = "";

var x_ratio = 0.000075; #ratio: 30 = 0.035 (fwd/back, speed)
var y_ratio = 0.000300; #ratio: 30 = 0.05 (left/right, yaw)
var z_ratio = 0.000050; #ratio 300 = .04 (up/down, g's)

var view = "Cockpit View";

var movement_init = func {
	if ( getprop("/sim/flight-model") == "jsb" ) {
		if ( getprop("/sim/current-view/name") == view ) {
			cv_x = getprop(cv_x_offset_path);
			cv_y = getprop(cv_y_offset_path);
			cv_z = getprop(cv_z_offset_path);
			movement();
		}else{
			settimer(movement_init,1);
		}
	}
}

var movement = func {
	#jsbsim x = -flightgear z
	#jsbsim y = flightgear x
	#jsbsim z = flightgear y
	if ( getprop("/sim/current-view/name") == view ) {
		setprop(cv_x_offset_path,cv_x + (getprop(y_ft_s2_path) * -1 * y_ratio));
		setprop(cv_y_offset_path,cv_y + (getprop(z_ft_s2_path) * z_ratio));
		setprop(cv_z_offset_path,cv_z + (getprop(x_ft_s2_path) * x_ratio));
	}
    settimer(movement, 0);
}

var init_listener = setlistener("sim/signals/fdm-initialized", func {
	movement_init();
	removelistener(init_listener);
}, 0, 0);
