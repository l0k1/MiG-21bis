# RADAR ALTIMETER

# set a radar altimeter limit based on the position of the knob.

var alt_setting_to_feet = [0.0, 65.6, 131.23, 196.85, 328.08, 656.17, 984.25, 1312.34, 1968.5];

setlistener( "/instrumentation/altimeter/altitude-limit-select", func{
	setprop("/instrumentation/altimeter/altitude-limit-select-ft", alt_setting_to_feet[getprop("/instrumentation/altimeter/altitude-limit-select")]);
});

var calc_safe_altitude = func(){
	var low_limit = getprop("/instrumentation/altimeter/altitude-limit-select-ft");
	setprop("/autopilot/settings/safe-alt",getprop("/position/altitude-ft") - getprop("/position/altitude-agl-ft") + (low_limit + (M2FT * (150 + (20-150) * ((low_limit * FT2M) - 20) / (600-20)))));
}

var calc_down_angle = func(){
	var angle_deg = vector.Math.angleBetweenVectors(vector.Math.eulerToCartesian3Z(getprop("/orientation/heading-deg"), getprop("/orientation/pitch-deg"), getprop("/orientation/roll-deg")), [0,0,1]);
	if ( angle_deg < 20 ) {
		angle_deg = 0;
	} elsif ( angle_deg > 105 ) {
		angle_deg = 85;
	} else {
		angle_deg = angle_deg - 20;
	}
	#print(angle_deg);
	setprop("/instrumentation/altimeter/radar-altimeter-angle-rad", angle_deg * D2R);
	settimer(func(){calc_down_angle();},0.1);
}

calc_down_angle();