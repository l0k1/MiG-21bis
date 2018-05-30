#GLOBAL VARS
UPDATE_TIME = 0.15;

var main_loop = func (){
	performance();
  logTime();
	settimer(func{main_loop();},UPDATE_TIME);
}

### SETS PERFORMANCE PROPERTIES FOR FDM CHECKING

var performance = func () {
	#roll rate per second
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

setlistener("/instrumentation/misc-panel-1/hlt-heat-rqst",func() {
  # if the guard is down, the switch can move up but not down
  #
  if ( getprop("/instrumentation/misc-panel-1/guard") == 0 ) {
    if ( getprop("/instrumentation/misc-panel-1/hlt-heat-rqst") == 0 ) {
      setprop("/instrumentation/misc-panel-1/hlt-heat",0);
    }
    setprop("/instrumentation/misc-panel-1/hlt-heat-rqst",0);
  } else {
    setprop("/instrumentation/misc-panel-1/hlt-heat",getprop("/instrumentation/misc-panel-1/hlt-heat-rqst"));
  }
});

var logTime = func{
  #log time and date for outputing ucsv files for converting into KML files for google earth.
  if (getprop("logging/log[0]/enabled") == 1 and getprop("sim/time/utc/year") != nil) {
    var date = getprop("sim/time/utc/year")~"/"~getprop("sim/time/utc/month")~"/"~getprop("sim/time/utc/day");
    var time = getprop("sim/time/utc/hour")~":"~getprop("sim/time/utc/minute")~":"~getprop("sim/time/utc/second");

    setprop("logging/date-log", date);
    setprop("logging/time-log", time);
  }
}

var flap_setting = func(button) {
  # button 0 = off
  # button 1 = up
  # button 2 = takeoff
  # button 3 = landing
  if ( button == 0 ) {
    setprop("/controls/flight/flap-panel/up",0);
    setprop("/controls/flight/flap-panel/takeoff",0);
    setprop("/controls/flight/flap-panel/landing",0);
  } elsif ( button == 1 ) {
    setprop("/controls/flight/flap-panel/up",1);
    setprop("/controls/flight/flap-panel/takeoff",0);
    setprop("/controls/flight/flap-panel/landing",0);
    setprop("/controls/flight/flaps",0);
  } elsif ( button == 2 ) {
    setprop("/controls/flight/flap-panel/up",0);
    setprop("/controls/flight/flap-panel/takeoff",1);
    setprop("/controls/flight/flap-panel/landing",0);
    setprop("/controls/flight/flaps",0.5);
  } elsif ( button == 3 ) {
    setprop("/controls/flight/flap-panel/up",0);
    setprop("/controls/flight/flap-panel/takeoff",0);
    setprop("/controls/flight/flap-panel/landing",1);
    setprop("/controls/flight/flaps",1);
  }
}

var flap_keybind = func(button) {
  # button = 0 increase (flaps down)
  # button = 1 decrease (flaps up)
  if ( button == 0 ) {
    if (getprop("/controls/flight/flap-panel/up")) {
      flap_setting(2);
    } elsif (getprop("/controls/flight/flap-panel/takeoff")) {
      flap_setting(3);
    }
  } else {
    if (getprop("/controls/flight/flap-panel/landing")) {
      flap_setting(2);
    } elsif (getprop("/controls/flight/flap-panel/takeoff")) {
      flap_setting(1);
    }
  }
}

var gear_setting = func(dir) {
  # dir = -1, decrease (neutral/gears down)
  # dir = 1, increase (neutral/gears up)
  var cur_setting = getprop("/controls/gear/requested-setting");
  var pin_setting = getprop("/controls/gear/up-pin");
  if (dir == 1) {
    if (cur_setting == -1) {
      setprop("/controls/gear/requested-setting",0);
      setprop("fdm/jsbsim/gear/gear-rqst-norm",getprop("fdm/jsbsim/gear/gear-pos-norm"));
    } elsif (cur_setting == 0 and pin_setting) {
      setprop("/controls/gear/requested-setting",1);
      setprop("fdm/jsbsim/gear/gear-rqst-norm",0);
    }
  } elsif (dir == -1) {
    if (cur_setting == 1) {
      setprop("/controls/gear/requested-setting",0);
      setprop("fdm/jsbsim/gear/gear-rqst-norm",getprop("fdm/jsbsim/gear/gear-pos-norm"));
    } elsif (cur_setting == 0) {
      setprop("/controls/gear/requested-setting",-1);
      setprop("fdm/jsbsim/gear/gear-rqst-norm",1);
    }
  }
}

var runthru = 0;
var starter_time = 0;

var dc_prop = props.globals.getNode("/fdm/jsbsim/electric/output/engine-starting-unit"); # most of the electrical routing happens in the electric.xml jsbsim file
var n1 = props.globals.getNode("/engines/engine[0]/n1");
var eng_running = props.globals.getNode("/engines/engine[0]/running");
var start_button = props.globals.getNode("/controls/engines/engine[0]/start-button");
var start_mode = props.globals.getNode("/controls/engines/engine[0]/starting-switch");
var starter = props.globals.getNode("/controls/engines/engine[0]/starter");
var cutoff = props.globals.getNode("/controls/engines/engine[0]/cutoff");
var start_ignition_signal = props.globals.getNode("/controls/engines/engine[0]/start-ignition-signal");

var engine_startup = func() {
  # props not yet accounted for, r/set circuit breaker, service tk pump circuit breaker
  if ( start_mode.getValue == 0 or
					dc_prop.getValue < 100 or
					(start_button.getValue() == 0 and systime() - starter_time < 3)) {
		starter.setValue(0);
		cutoff.setValue(0);
		start_ignition_signal.setValue(0);
		runthru = 0;
		return;
	}

	if ( runthru == 0 ) {
		starter.setValue(1);
		cutoff.setValue(1);
		starter_time = systime();
		runthru = 1;
	} elsif ( runthru == 1 ) {
		cutoff.setValue(0);
		runthru = 2;
	} elsif (eng_running.getValue()) {
		runthru = 0;
		starter.setValue(0);
	} else {
      settimer(func(){engine_startup();},0.2);
  }
}

  #/controls/engines/engine[~n~]/starter set to true
  #/controls/engines/engine[~n~]/cutoff toggled with 0.1 sec delay
  #after n1 stabs
  #/controls/engines/engine[~n~]/starter set to false

test_support();
main_loop();
