
### VOR/ILS radio frequency handling using preset channels and a letdown/navig/landing switch
	
# /instrumentation/nav[0]/nav-mode-swith:
#    0 = letdown mode - VOR
#    1 = navig mode   - VOR
#    2 = landing mode - ILS

# this function is as "var"-less as possible, which is why it's sort of ugly.
# basically, check where the switch is, and assign nav[0] selected frequency 
# to the frequency represented by the preset channel on the radio panel. 
var update_nav_radio = func() {
	if ( getprop("/instrumentation/nav[0]/nav-mode-switch") == 2 ) {
		setprop("/instrumentation/nav[0]/frequencies/selected-mhz",getprop("/instrumentation/ils-radio/preset[" ~ getprop("/instrumentation/ils-radio/selection") ~ "]"));
	} else {
		setprop("/instrumentation/nav[0]/frequencies/selected-mhz",getprop("/instrumentation/vor-radio/preset[" ~ getprop("/instrumentation/vor-radio/selection") ~ "]"));
	}
}
	
update_nav_radio();
setlistener("/instrumentation/nav[0]/nav-mode-switch",func(){update_nav_radio();});
setlistener("/instrumentation/nav[0]/radio-tune-update",func(){update_nav_radio();});
setlistener("/instrumentation/vor-radio/selection",func(){update_nav_radio();});
setlistener("/instrumentation/ils-radio/selection",func(){update_nav_radio();});

### comm radio frequency handling using preset channels

var update_comm_radio = func() {
	setprop("/instrumentation/comm[0]/frequencies/selected-mhz",getprop("/instrumentation/comm-radio/preset[" ~ getprop("/instrumentation/comm-radio/selection") ~ "]"));
}
	
update_comm_radio();
setlistener("/instrumentation/comm[0]/radio-tune-update",func(){update_comm_radio();});
setlistener("/instrumentation/comm-radio/selection",func(){update_comm_radio();});

### adf/ndb radio frequency handling

var update_adf_radio = func() {
	var selection = getprop("/instrumentation/adf-radio/selection");
	setprop("/instrumentation/adf[0]/frequencies/selected-khz",getprop("/instrumentation/adf-radio/preset[" ~ selection ~ "]"));
	for (var i = 0; i < 9; i = i + 1 ) {
		if ( i != selection ) {
			setprop("/instrumentation/adf-radio/animation/select["~i~"]",0)
		} else {
			setprop("/instrumentation/adf-radio/animation/select["~i~"]",1)
		}
	}
}
	
update_adf_radio();
setlistener("/instrumentation/adf[0]/radio-tune-update",func(){update_adf_radio();});
setlistener("/instrumentation/adf-radio/selection",func(){update_adf_radio();});

# comm radio volume propogation
setlistener("/instrumentation/comm-radio/volume",func(){volume_propogate();});
setlistener("/instrumentation/comm-radio/rset_comp_switch",func(){volume_propogate();});

var volume_propogate = func{
	if (getprop("/instrumentation/comm-radio/rset_comp_switch") == 0) {
		setprop("/instrumentation/comm[0]/volume",getprop("/instrumentation/comm-radio/volume"));
		setprop("/instrumentation/adf[0]/volume-norm",0);
	} else {
		setprop("/instrumentation/adf[0]/volume-norm",getprop("/instrumentation/comm-radio/volume"));
		setprop("/instrumentation/comm[0]/volume",0);
	}
}

setprop("/instrumentation/comm[0]/volume",0);
setprop("/instrumentation/adf[0]/volume-norm",0);
setprop("/instrumentation/comm-radio/volume",0);