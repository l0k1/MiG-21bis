
### VOR/ILS radio frequency handling using preset channels and a letdown/navig/landing switch
    
# /instrumentation/nav[0]/nav-mode-switch:
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
    var freq = getprop("/instrumentation/adf-radio/preset[" ~ selection ~ "]");
    switch_state = 0;
    setprop("/instrumentation/adf[0]/frequencies/selected-khz",freq);
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
setlistener("/instrumentation/adf/inbound-outbound-switch",func(){update_adf_radio();});

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

# inner/outer switch loop
var freq = 0;
var last_freq = 0;
var switch_state = 0;
var arc_sel = 0;
var gear_pos = 0;
var in_out_state = 0;

var bearing = 0;
var last_bearing = 0;

var hold_freq = 0;
var change_freq = 0;

var arc_sel_map = [2,2,4,4,6,6,8,8];

var inner_outer_adf_finder = func() {
    switch_state = getprop("/instrumentation/adf/inbound-outbound-switch");
    freq = getprop("/instrumentation/adf-radio/preset[" ~ getprop("/instrumentation/adf-radio/selection") ~ "]");
    gear_pos = getprop("/fdm/jsbsim/gear/gear-pos-norm");
    arc_sel = getprop("/instrumentation/adf/arc-sel");
    in_out_state = getprop("/instrumentation/adf/in-out-state");
    var chel = getprop("/instrumentation/adf-radio/selection");
    #/instrumentation/adf/indicated-bearing-deg
    #/fdm/jsbsim/gear/gear-pos-norm == 1
    #/instrumentation/adf/arc-sel

    if (gear_pos != 1) {
        print("blahhhhh 1");
        # if gear isn't up, do nothing. make sure adf freq is operationg normally.
        if (freq != last_freq) {
            setprop("/instrumentation/adf[0]/frequencies/selected-khz",freq);
        }
        in_out_state = 0;
        last_freq = freq;
        return;
    } elsif (gear_pos == 1 and switch_state == 1){
        print("blahhhhh 2");
        freq = getprop("/instrumentation/adf-radio/preset[" ~ arc_sel_map[arc_sel] ~ "]");
        if (freq != last_freq) {
            setprop("/instrumentation/adf[0]/frequencies/selected-khz",freq);
        }
        in_out_state = 0;
        last_freq = freq;
    } elsif (gear_pos == 1 and switch_state == 0 and in_out_state == 0 and math.mod(chel,2) == 0 and chel != 8) {
        #determine rate at which the adf is passing
        bearing = math.periodic(getprop("/instrumentation/adf/indicated-bearing-deg"),-180,180);
        print(math.abs(bearing - last_bearing));

        if (math.abs(bearing - last_bearing) > 10 and getprop("/fdm/jsbsim/instrumentation/pitot/airspeed-kts") > 75) {
            # wild guess here. means if change is more than 5 degrees in one secone.
            in_out_state = 1;
            print("hmm");
            change_freq = getprop("/instrumentation/adf-radio/preset[" ~ arc_sel_map[arc_sel] ~ "]");
            hold_freq = freq;
            settimer(func(){
                print("yeeeeeeeeeeessssssssss");
                if (getprop("/instrumentation/adf[0]/frequencies/selected-khz") == hold_freq) {
                    setprop("/instrumentation/adf[0]/frequencies/selected-khz",change_freq);
                }
            },(math.mod(arc_sel,2) * 4) + 4);
                
        }
        last_bearing = bearing;
    }

    settimer(func(){inner_outer_adf_finder();},1);
}

inner_outer_adf_finder();
