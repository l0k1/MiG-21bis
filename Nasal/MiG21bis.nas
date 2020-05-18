#This file is for mostly random one-off stuff that doesn't really need it's own file

#GLOBAL VARS
UPDATE_TIME = 0.15;

var TRUE = 1;
var FALSE = 0;

var a = 0;
var main_loop = func (){
    #performance();
    logTime();
    if (getprop("/gear/gear/wow") == 1) {
        a = getprop("/orientation/pitch-deg");
    } else {
        a = getprop("/orientation/alpha-deg");
    }
    a = a > 170 ? a - 180 : a;
    a = math.abs(a) > 20 ? 20 * math.sgn(a) * -1 : a * -1;
    setprop("/instrumentation/magnetic-compass/pitch-offset-deg",a);
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
    } elsif ( button == 1 and getprop("/controls/flight/flap-panel/up") != 1 ) {
        setprop("/controls/flight/flap-panel/up",1);
        setprop("/controls/flight/flap-panel/takeoff",0);
        setprop("/controls/flight/flap-panel/landing",0);
    setprop("/controls/flight/flaps",0);
    } elsif ( button == 2 and getprop("/controls/flight/flap-panel/takeoff") != 1 ) {
        setprop("/controls/flight/flap-panel/up",0);
        setprop("/controls/flight/flap-panel/takeoff",1);
        setprop("/controls/flight/flap-panel/landing",0);
    setprop("/controls/flight/flaps",0.5);
    } elsif ( button == 3 and getprop("/controls/flight/flap-panel/landing") != 1 ) {
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
var starter_time_req = 0;

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
    if (runthru == 0) {
        starter_time = systime();
        starter_time_req = (rand() * 2) + 3.75;
        #print(starter_time_req);
    }
    if ( start_mode.getValue() == 0 or
                    dc_prop.getValue() < 25 or
                    (start_button.getValue() == 0 and systime() - starter_time < starter_time_req)) {
        #print("starter failed");
        starter.setValue(0);
        cutoff.setValue(0);
        start_ignition_signal.setValue(0);
        runthru = 0;
        return;
    }

    if ( runthru == 0 ) {
        starter.setValue(1);
        cutoff.setValue(1);
        start_ignition_signal.setValue(1);
        runthru = 1;
        settimer(func(){engine_startup();},0.2);
    } elsif ( runthru == 1 ) {
        cutoff.setValue(0);
        runthru = 2;
        settimer(func(){engine_startup();},0.2);
    } elsif (systime() - starter_time >= starter_time_req and start_ignition_signal.getValue() == 1 ) {
        start_ignition_signal.setValue(0);
        settimer(func(){engine_startup();},0.2);
    } elsif (eng_running.getValue()) {
        runthru = 0;
        starter.setValue(0);
    } else {
        settimer(func(){engine_startup();},0.2);
  }
}

setlistener("/controls/engines/engine[0]/start-button",engine_startup);
setlistener("/controls/engines/engine[0]/starting-switch",func(){
    if (eng_running.getValue()) { return; }
    if (start_mode.getValue() == 0){
        starter.setValue(0);
        cutoff.setValue(1);
    }
});

setlistener("/fdm/jsbsim/fcs/aru-override-switch",func(){
    setprop("/fdm/jsbsim/fcs/aru-setting-pos",getprop("/fdm/jsbsim/fcs/aru"));
});

var autostart_state = 0;
var autostart = func(v = 1) {
    if (v == 0 and eng_running.getValue()) {
        #engine is running running, shut it down
        #print("shutting down engine");
        autostart_state = 0;
        cutoff.setValue(1);
        return;
    }
    if (v == 1 and autostart_state == 0) {
        setprop("/fdm/jsbsim/electric/switches/rhfsp/no-3-tk-gp-pump",1);
        setprop("/fdm/jsbsim/electric/switches/rhfsp/no-1-tk-gp-pump",1);
        setprop("/fdm/jsbsim/electric/switches/rhfsp/service-tk-pump",1);
        setprop("/fdm/jsbsim/electric/switches/rhfsp/bat-ext-pwr-sup",1);
        setprop("/fdm/jsbsim/electric/switches/rhfsp/dc-gen",1);
        setprop("/fdm/jsbsim/electric/switches/rhfsp/ac-gen-ext-pwr",1);
        setprop("/fdm/jsbsim/electric/switches/lvfsp/fire-ftg-eqpt",1);
        setprop("/fdm/jsbsim/electric/switches/lvfsp/engine-starting-unit",1);
        setprop("/controls/engines/engine[0]/starting-switch",1);
        screen.log.write("Warning! Autostart only starts the engines!", 1.0, 0.2, 0);
        screen.log.write("It is up to the you to set the gauges", 1.0, 0.2, 0);
        screen.log.write("and switches according to your needs.", 1.0, 0.2, 0);
        autostart_state = 1;
        settimer(func(){autostart();},0.5);
    } elsif (autostart_state == 1) {
        if (dc_prop.getValue() > 25) {
            autostart_state = 2;
            setprop("/controls/engines/engine[0]/start-button",1);
            settimer(func(){autostart();},2.0);
        } else {
            settimer(func(){autostart();},0.5);
        }
    } elsif (autostart_state == 2) {
        if (!start_ignition_signal.getValue()) {
            #print("signal not detected, returning to normal");
            setprop("/controls/engines/engine[0]/start-button",0);
            autostart_state = 0;
            return;
        } else {
            #print("setting timer");
            settimer(func(){autostart();},0.2);
        }
    }
}

var load_radios = func(path) {
    path = path.getValue();
    if (io.stat(path) == nil){
        return;
    }
    var mode = -1;
    var index = 0;
    var vi = io.open(path,'r');
    var data = split("\n",string.replace(io.readfile(path),"\r",""));

    # clear out old settings

    for (var i = 0; i < 20; i = i + 1) {
        setprop("/instrumentation/vor-radio/preset["~i~"]",0);
        setprop("/instrumentation/vor-radio/ident["~i~"]","");
        setprop("/instrumentation/adf-radio/preset["~i~"]",0);
        setprop("/instrumentation/adf-radio/ident["~i~"]","");
        setprop("/instrumentation/comm-radio/preset["~i~"]",0);
        setprop("/instrumentation/comm-radio/ident["~i~"]","");
        setprop("/instrumentation/ils-radio/preset["~i~"]",0);
        setprop("/instrumentation/ils-radio/ident["~i~"]","");
    }

    foreach (var datum; data){
        if (left(datum,1) == "#") { continue; }
        if (datum == "nav") { 
            mode = 0;
            index = 0;
            continue;
        } elsif (datum == "adf") { 
            mode = 1;
            index = 0;
            continue;
        } elsif (datum == "comm") { 
            mode = 2;
            index = 0;
            continue;
        } elsif (datum == "ils") {
            mode = 3;
            index = 0;
            continue;
        }
        if (datum == "") { continue; }
        if (mode == -1) { continue; }
        if ( ((mode == 0 or mode == 2 or mode == 3) and index > 19) or (mode == 1 and index > 8) ) {continue;}

        var ident = "";
        if ( size(split(" ",datum)) > 1 ) {
            ident = split(" ",datum)[1];
            datum = split(" ",datum)[0];
        }

        if (mode == 0) {
            setprop("/instrumentation/vor-radio/preset["~index~"]",datum);
            setprop("/instrumentation/vor-radio/ident["~index~"]",ident);
        } elsif (mode == 1) {
            setprop("/instrumentation/adf-radio/preset["~index~"]",datum);
            setprop("/instrumentation/adf-radio/ident["~index~"]",ident);
        } elsif (mode == 2) {
            setprop("/instrumentation/comm-radio/preset["~index~"]",datum);
            setprop("/instrumentation/comm-radio/ident["~index~"]",ident);
        } elsif (mode == 3) {
            setprop("/instrumentation/ils-radio/preset["~index~"]",datum);
            setprop("/instrumentation/ils-radio/ident["~index~"]",ident);
        }
        index = index + 1;

    }
    radio_canvas.rp.update_text();
    radio.update_nav_radio();
    #debug.dump(data);
}

#var file_selector = gui.FileSelector.new(dir: getprop("/sim/fg-home"), callback: load_radios, title: "Select Radio Config File", button: "Load");
var file_selector = nil;
var get_radio_file_gui = func() {
    file_selector.open();
}

var jsbsim_random = func() {
    setprop("/fdm/jsbsim/random/rand-0",rand());
    setprop("/fdm/jsbsim/random/rand-1",rand());
    setprop("/fdm/jsbsim/random/rand-2",rand());
    setprop("/fdm/jsbsim/random/rand-3",rand());
    settimer(jsbsim_random,0);
}

var load_interior = func{
    setprop("/sim/current-view/view-number", 0);
    #print("..Done!");
}

var dmg = 0;

var toggle_damage = func{
    dmg = !getprop("payload/armament/msg");
    setprop("payload/armament/msg",dmg);
    if (dmg) {
        screen.log.write("Damage enabled!", 1.0, 0.2, 0.2);
        setprop("sim/menubar/default/menu[2]/item[0]/enabled",0);
        setprop("sim/menubar/default/menu[5]/item[0]/enabled",0);
        setprop("sim/menubar/default/menu[5]/item[1]/enabled",0);
        setprop("sim/menubar/default/menu[5]/item[2]/enabled",0);
        setprop("sim/menubar/default/menu[7]/item[4]/enabled",0);
        wow_menu_change();
    } else {
        screen.log.write("Damage disabled!", 1.0, 0.2, 0.2);
        setprop("sim/menubar/default/menu[2]/item[0]/enabled",1);
        setprop("sim/menubar/default/menu[5]/item[0]/enabled",1);
        setprop("sim/menubar/default/menu[5]/item[1]/enabled",1);
        setprop("sim/menubar/default/menu[5]/item[2]/enabled",1);
        setprop("sim/menubar/default/menu[7]/item[4]/enabled",1);
    }
}

var wow_menu_change = func{
    var wowstatus = getprop("fdm/jsbsim/gear/unit/WOW") and getprop("fdm/jsbsim/gear/unit[1]/WOW") and getprop("fdm/jsbsim/gear/unit[2]/WOW");
    #print(wowstatus);
    if (dmg) {
        if (wowstatus) {
            setprop("sim/menubar/default/menu[2]/item[1]/enabled",1);
            setprop("sim/menubar/default/menu[5]/item[4]/enabled",1);
            setprop("sim/menubar/default/menu[5]/item[9]/enabled",1);
            setprop("sim/menubar/default/menu[5]/item[10]/enabled",1);
            setprop("sim/menubar/default/menu[5]/item[11]/enabled",1);
            setprop("sim/menubar/default/menu[100]/item[0]/enabled",1);
            setprop("sim/menubar/default/menu[100]/item[2]/enabled",1);
            setprop("sim/menubar/default/menu[100]/item[3]/enabled",1);
            setprop("sim/menubar/default/menu[100]/item[4]/enabled",1);
            setprop("sim/menubar/default/menu[100]/item[5]/enabled",1);
            setprop("sim/menubar/default/menu[100]/item[6]/enabled",1);
            setprop("sim/menubar/default/menu[100]/item[8]/enabled",1);
            setprop("sim/menubar/default/menu[100]/item[9]/enabled",1);
            setprop("sim/menubar/default/menu[100]/item[12]/enabled",1);
        } else {
            setprop("sim/menubar/default/menu[2]/item[1]/enabled",0);
            setprop("sim/menubar/default/menu[5]/item[4]/enabled",0);
            setprop("sim/menubar/default/menu[5]/item[9]/enabled",0);
            setprop("sim/menubar/default/menu[5]/item[10]/enabled",0);
            setprop("sim/menubar/default/menu[5]/item[11]/enabled",0);
            setprop("sim/menubar/default/menu[100]/item[0]/enabled",0);
            setprop("sim/menubar/default/menu[100]/item[2]/enabled",0);
            setprop("sim/menubar/default/menu[100]/item[3]/enabled",0);
            setprop("sim/menubar/default/menu[100]/item[4]/enabled",0);
            setprop("sim/menubar/default/menu[100]/item[5]/enabled",0);
            setprop("sim/menubar/default/menu[100]/item[6]/enabled",0);
            setprop("sim/menubar/default/menu[100]/item[8]/enabled",0);
            setprop("sim/menubar/default/menu[100]/item[9]/enabled",0);
            setprop("sim/menubar/default/menu[100]/item[12]/enabled",0);
        }
    }
    if (!wowstatus) {
        setprop("sim/menubar/default/menu[100]/item[13]/enabled",0);
    } else {
        setprop("sim/menubar/default/menu[100]/item[13]/enabled",1);
    }
}

var init = setlistener("/sim/signals/fdm-initialized", func() {
    # Load exterior at startup to avoid stale sim at first external view selection. ( taken from TU-154B )
    # print("Loading exterior, wait...");
    # return to cabin to next cycle
    settimer( load_interior, 0 );
    setprop("/sim/current-view/view-number", 1);
    setprop("/sim/gui/tooltips-enabled", TRUE);


    file_selector = gui.FileSelector.new(dir: getprop("/sim/fg-home"), callback: load_radios, title: "Select Radio Config File", button: "Load");

    screen.log.write("Welcome to MiG-21bis!", 1.0, 0.2, 0.2);
    dmg = getprop("payload/armament/msg");
    if (dmg) {
        screen.log.write("Damage enabled!", 1.0, 0.2, 0.2);
        setprop("sim/menubar/default/menu[2]/item[0]/enabled",0);
        setprop("sim/menubar/default/menu[5]/item[0]/enabled",0);
        setprop("sim/menubar/default/menu[5]/item[1]/enabled",0);
        setprop("sim/menubar/default/menu[5]/item[2]/enabled",0);
        setprop("sim/menubar/default/menu[7]/item[4]/enabled",0);
    }
    
    test_support();
    main_loop();
    jsbsim_random();
    #
    setlistener("gear/gear[0]/wow",func(){wow_menu_change()},nil,0);
    setlistener("gear/gear[1]/wow",func(){wow_menu_change()},nil,0);
    setlistener("gear/gear[2]/wow",func(){wow_menu_change()},nil,0);
    setlistener("sim/menubar/default/menu[7]/item[4]/enabled", func() {
        if (dmg) {
            setprop("sim/menubar/default/menu[7]/item[4]/enabled",0);
        }
        });
    # randomize startup values for DME, radial setting, compass, and fuel
    setprop("/instrumentation/fuel/knob-level",int((rand() * 1600) + 169)); # fuel
    setprop("/fdm/jsbsim/systems/gyro-compass/heading-change",getprop("/orientation/heading-deg") + int((rand() * 100) - 50)); # gyro compass heading
    setprop("/instrumentation/dead-reckoner/distance-adjust",int(rand() * 30)); # dme
    setprop("/instrumentation/dead-reckoner/azimuth-adjust",math.periodic(0, 360, int(rand() * 360))); #ins azimuth
    setprop("/instrumentation/nav/radials/selected-deg",math.periodic(0, 360, int(rand() * 360)))
});