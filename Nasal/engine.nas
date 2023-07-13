# TODO
# rewrite this to use props.nas, or maybe switch to jsbsim?

var update_rate = 0.2;

var main_loop = func() {
	check_surge();

	settimer(func(){main_loop();},update_rate);
}

var cdam = 0;

var check_surge = func() {
	cdam = getprop("/fdm/jsbsim/propulsion/engine[0]/damage-norm");
	if (getprop("/fdm/jsbsim/systems/air-intake/surge-set") == 1 and getprop("/fdm/jsbsim/systems/air-intake/surging") == 0) {
		cdam = cdam - (rand() / 3);
		cdam = cdam < 0.0 ? 0.0 : cdam;
		setprop("/fdm/jsbsim/propulsion/engine[0]/damage-norm",cdam);
	}

	if (getprop("/fdm/jsbsim/systems/air-intake/surge-set") == 1) {
		setprop("/fdm/jsbsim/systems/air-intake/surging",1);
	}
	if (getprop("/fdm/jsbsim/systems/air-intake/surging") == 1 and cdam > 0.1) {
		if (getprop("/fdm/jsbsim/fcs/throttle-redist-mil") < 0.1) {
			if (rand() > 0.9) {
				setprop("/fdm/jsbsim/systems/air-intake/surging",0);
			}
		}
	}

	#engine sound stuff
	cdam = -cdam + 1;
	setprop("/sounds/engineclick1",cdam * 2);
	setprop("/sounds/engineclick2",(cdam - 0.5) * 2);
}

main_loop();
