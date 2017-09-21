# RADAR ALTIMETER

# set a radar altimeter limit based on the position of the knob.

var alt_setting_to_feet = [0.0, 65.6, 131.23, 196.85, 328.08, 656.17, 984.25, 1312.34, 1968.5];

setlistener( "/instrumentation/altimeter/altitude-limit-select", func{
	setprop("/instrumentation/altimeter/altitude-limit-select-ft", alt_setting_to_feet[getprop("/instrumentation/altimeter/altitude-limit-select")]);
});
