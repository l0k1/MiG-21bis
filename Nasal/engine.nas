
var update_rate = 0.2;

var main_loop = func() {
	check_surge();

	settimer(func(){main_loop();},update_rate);
}

var check_surge = func() {
	if (getprop("/fdm/jsbsim/systems/air-intake/surge-set") == 1) {
		setprop("/fdm/jsbsim/systems/air-intake/surging",1);
	}
	if (getprop("/fdm/jsbsim/systems/air-intake/surging") == 1) {
		if (getprop("/fdm/jsbsim/fcs/throttle-redist-mil") < 0.1) {
			if (rand() > 0.9) {
				setprop("/fdm/jsbsim/systems/air-intake/surging",0);
			}
		}
	}
}

main_loop();
