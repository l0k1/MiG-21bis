
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
