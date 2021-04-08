###################################################################################
## Author: pinto			                                                     ##
##                                                                               ##
## Version 1.0             License: GPL 2.0+                                     ##
##                                                                               ##
###################################################################################


var clamp = func(v, min, max) { v < min ? min : v > max ? max : v }

var cv_x_offset_path = "/sim/current-view/x-offset-m";
var cv_y_offset_path = "/sim/current-view/y-offset-m";
var cv_z_offset_path = "/sim/current-view/z-offset-m";

var severity_path = "/sim/current-view/headshake-severity";

var seatheight_path = "/fdm/jsbsim/electric/output/seat-height";

var cv_path = "/sim/current-view/name";
var enable_path = "/sim/enable-headshake";

setprop(severity_path, 0);

var cv_x = 0;
var cv_y = 1.2813;
var cv_z = -3.33;
var mv = 0;

var x_ratio = 0.000175; #ratio: 30 = 0.035 (fwd/back, speed)
var y_ratio = 0.000300; #ratio: 30 = 0.05 (left/right, yaw)
var z_ratio = 0.000150; #ratio 300 = .04 (up/down, g's)

var view = "Cockpit View";

var sm = 0;

var movement = func {
	#jsbsim x = -flightgear z
	#jsbsim y = flightgear x/
	#jsbsim z = flightgear y
	if ( getprop(cv_path) == view and getprop(enable_path) ) {
		cv_y = cv_y + (getprop(seatheight_path) * 0.001);
		if (cv_y < 1.13) {
			cv_y = 1.13;
		} elsif (cv_y > 1.35) {
			cv_y = 1.35;
		}
		sev = getprop(severity_path);
		setprop(cv_x_offset_path, cv_x + ((rand() * 2 - 1) * x_ratio * sev));
		setprop(cv_y_offset_path, cv_y + ((rand() * 2 - 1) * y_ratio * sev));
		setprop(cv_z_offset_path, cv_z + ((rand() * 2 - 1) * z_ratio * sev));
	}
    settimer(movement, 0);
}

var init_listener = setlistener("sim/signals/fdm-initialized", func {
	movement();
	removelistener(init_listener);
}, 0, 0);
