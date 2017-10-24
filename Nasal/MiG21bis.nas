#GLOBAL VARS
UPDATE_TIME = 0.15;

var main_loop = func (){
	performance();
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

test_support();
main_loop();