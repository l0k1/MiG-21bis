
### VOR/ILS radio frequency handling using preset channels and a letdown/navig/landing switch
	
# /instrumentation/nav[0]/nav-mode-swith:
#    0 = letdown mode - VOR
#    1 = navig mode   - VOR
#    2 = landing mode - ILS

# this function is as "var"-less as possible, which is why it's sort of ugly.
# basically, check where the switch is, and assign nav[0] selected frequency 
# to the frequency represented by the preset channel on the radio panel. 
var update_radio = func() {
	print("updating");
	if ( getprop("/instrumentation/nav[0]/nav-mode-switch") == 2 ) {
		setprop("/instrumentation/nav[0]/frequencies/selected-mhz",getprop("/instrumentation/ils-radio/preset[" ~ getprop("/instrumentation/ils-radio/selection") ~ "]"));
	} else {
		setprop("/instrumentation/nav[0]/frequencies/selected-mhz",getprop("/instrumentation/vor-radio/preset[" ~ getprop("/instrumentation/vor-radio/selection") ~ "]"));
	}
}
	
update_radio();
setlistener("/instrumentation/nav[0]/nav-mode-switch",func(){update_radio();});
setlistener("/instrumentation/nav[0]/radio-tune-update",func(){update_radio();});
setlistener("/instrumentation/vor-radio/selection",func(){update_radio();});
setlistener("/instrumentation/ils-radio/selection",func(){update_radio();});
