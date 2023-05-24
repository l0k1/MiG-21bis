
var reset_failures = func() {
	if (!(getprop("fdm/jsbsim/gear/unit/WOW") and getprop("fdm/jsbsim/gear/unit[1]/WOW") and getprop("fdm/jsbsim/gear/unit[2]/WOW"))) {
		screen.log.write("Cannot reset airframe while flying.");
	} else {
		screen.log.write("Airframe damage reset.");
		crashandstress.repair();
	}
};