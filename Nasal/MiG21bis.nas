#GLOBAL VARS
UPDATE_TIME = 0.15;

#DIALOGS

var radio_dialog = gui.Dialog.new("vor_ils_radio/dialog","Aircraft/MiG-21bis/Dialogs/vor_ils_radio.xml");
var smokepod_dialog = gui.Dialog.new("smokepod/dialog","Aircraft/MiG-21bis/Dialogs/smokepod_dialog.xml");

var main_loop = func (){
	performance();
	update_vor_freq();
	update_ils_freq();
	vor_intercept_angle();
	settimer(func{main_loop();},UPDATE_TIME);
}

### SETS PERFORMANCE PROPERTIES FOR FDM CHECKING

var performance = func () {
	#roll rate per second
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

setprop("/mig21/advanced-radar",0);

var test_support = func {
 
  var versionString = getprop("sim/version/flightgear");
  var version = split(".", versionString);
  var major = num(version[0]);
  var minor = num(version[1]);
  var detail = num(version[2]);
  if ( major == 2017 ) {
  	if ( minor >= 2 ) {
  		setprop("/mig21/advanced-radar",1);
  	}
  }
}

test_support();
main_loop();