#GLOBAL VARS
UPDATE_TIME = 0.15;

#DIALOGS

var radio_dialog = gui.Dialog.new("vor_ils_radio/dialog","Aircraft/MiG-21bis/Dialogs/vor_ils_radio.xml");

var main_loop = func (){
	update_vor_freq();
	update_ils_freq();
	vor_intercept_angle();
	settimer(func{main_loop();},UPDATE_TIME);
}

### VOR RADIO HANDLING/CHANNEL SELECTION
### VOR radio outputs to nav[0], ILS radio outputs to nav[1]
### I was using listeners for this, it wasn't working perfectly, so just updating in the main loop.

var update_vor_freq = func () {
	var channel = getprop("/instrumentation/vor-radio/selection");
	setprop("instrumentation/nav[0]/frequencies/selected-mhz",getprop("/instrumentation/vor-radio/preset[" ~ channel ~ "]"));
}

### ILS RADIO HANDLING/CHANNEL SELECTION

var update_ils_freq = func () {
	var channel = getprop("/instrumentation/ils-radio/selection");
	setprop("instrumentation/nav[1]/frequencies/selected-mhz",getprop("/instrumentation/ils-radio/preset[" ~ channel ~ "]"));
}

### VOR INTERCEPT ANGLE

var vor_intercept_angle = func () {
	if (getprop("instrumentation/nav[0]/in-range") == 1) {
		var inter_heading = getprop("/instrumentation/nav[0]/radials/target-auto-hdg-deg");
		var my_heading = getprop("/orientation/heading-deg");
		var normed = math.clamp(my_heading - inter_heading,-10,10);
		setprop("instrumentation/nav[0]/intercept-norm",normed);
	} else {
		setprop("instrumentation/nav[0]/intercept-norm",0);
	}
}

main_loop();