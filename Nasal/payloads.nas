# $Id$

var UPDATE_PERIOD = 0.1;

var FALSE = 0;
var TRUE = 1;

var MISSILE_STANDBY = -1;
var MISSILE_SEARCH = 0;
var MISSILE_LOCK = 1;
var MISSILE_FLYING = 2;
############### Main loop ###############

input = {
  replay:           "sim/replay/replay-state",
  elapsed:          "sim/time/elapsed-sec",
  elapsedInit:      "sim/time/elapsed-at-init-sec",
  fullInit:         "sim/time/full-init",
  tank0LvlNorm:     "/consumables/fuel/tank[0]/level-norm",
  tank8LvlNorm:     "/consumables/fuel/tank[8]/level-norm",
  tank0LvlGal:      "/consumables/fuel/tank[0]/level-gal_us",
  tank1LvlGal:      "/consumables/fuel/tank[1]/level-gal_us",
  tank2LvlGal:      "/consumables/fuel/tank[2]/level-gal_us",
  tank3LvlGal:      "/consumables/fuel/tank[3]/level-gal_us",
  tank4LvlGal:      "/consumables/fuel/tank[4]/level-gal_us",
  tank5LvlGal:      "/consumables/fuel/tank[5]/level-gal_us",
  tank6LvlGal:      "/consumables/fuel/tank[6]/level-gal_us",
  tank7LvlGal:      "/consumables/fuel/tank[7]/level-gal_us",
  tank8LvlGal:      "/consumables/fuel/tank[8]/level-gal_us",
  stationSelect:    "controls/armament/station-select",
  mass1:            "fdm/jsbsim/inertia/pointmass-weight-lbs[1]",
  mass3:            "fdm/jsbsim/inertia/pointmass-weight-lbs[3]",
  tank8Flow:        "fdm/jsbsim/propulsion/tank[8]/external-flow-rate-pps",
  tank8Selected:    "/consumables/fuel/tank[8]/selected",
  tank8Jettison:    "/consumables/fuel/tank[8]/jettisoned",
  trigger:          "controls/armament/trigger",
  MPfloat2:         "sim/multiplay/generic/float[2]",
  MPfloat9:         "sim/multiplay/generic/float[9]",
  MPint9:           "sim/multiplay/generic/int[9]",
  MPint17:          "sim/multiplay/generic/int[17]",
  MPint18:          "sim/multiplay/generic/int[18]",
  subAmmo2:         "ai/submodels/submodel[2]/count",
  subAmmo3:         "ai/submodels/submodel[3]/count",
  impact:           "/ai/models/model-impact",
};

var update_loop = func {

  # End stuff

  if(input.replay.getValue() == TRUE) {
    # replay is active, skip rest of loop.
    settimer(update_loop, UPDATE_PERIOD);
  } else {
    # set the full-init property
    if(input.elapsed.getValue() > input.elapsedInit.getValue() + 5) {
      input.fullInit.setValue(TRUE);
    } else {
      input.fullInit.setValue(FALSE);
    }

    }

    # pylon payloads
    for(var i=0; i<=4; i=i+1) {
      if(getprop("payload/weight["~ (i) ~"]/selected") != "none" and getprop("payload/weight["~ (i) ~"]/weight-lb") == 0) {
        # missile was loaded manually through payload/fuel dialog, so setting the pylon to not released
        setprop("controls/armament/station["~(i)~"]/released", FALSE);
        #print("adding "~i);
        #if(i != 2) {
        #  if (getprop("payload/weight["~ (i) ~"]/selected") == "R-60") {
            #is not center pylon and is RB24
        #    if(armament.AIM9.new(i) == -1 and armament.AIM9.active[i].status == MISSILE_FLYING) {
              #missile added through menu while another from that pylon is still flying.
              #to handle this we have to ignore that addition.
        #      setprop("controls/armament/station["~(i+1)~"]/released", TRUE);
        #      setprop("payload/weight["~ (i) ~"]/selected", "none");
              #print("refusing to mount new missile yet "~i);
        #    }
          #} elsif (getprop("payload/weight["~ (i) ~"]/selected") == "M70") {
          #    setprop("ai/submodels/submodel["~(5+i)~"]/count", 6);
        #  }
        #}
      }
      #if(i!=0 and getprop("payload/weight["~ (i-1) ~"]/selected") == "none" and getprop("payload/weight["~ (i-1) ~"]/weight-lb") != 0) {
      #  if(armament.AIM9.active[i-1] != nil) {
          # pylon emptied through menu, so remove the logic
          #print("removing "~i);
      #    armament.AIM9.active[i-1].del();
      #  }
      #}
    }

    #activate searcher on selected pylon if missile mounted
    #var armSelect = input.stationSelect.getValue();
    #for(i = 0; i <= 4; i += 1) {
    #  if(armament.AIM9.active[i] != nil) {
    #    #missile is mounted on pylon
    #    if(armSelect != i+1 and armament.AIM9.active[i].status != MISSILE_FLYING) {
    #      #pylon not selected, and not flying set missile on standby
    #      armament.AIM9.active[i].status = MISSILE_STANDBY;#print("not sel "~(i));
    #    } elsif (input.combat.getValue() != 2 or (armament.AIM9.active[i].status != MISSILE_STANDBY and armament.AIM9.active[i].status != MISSILE_FLYING and getprop("payload/weight["~ (i) ~"]/selected") == "none")) {
    #      #pylon has logic but missile not mounted and not flying or not in tactical mode
    #      armament.AIM9.active[i].status = MISSILE_STANDBY;#print("empty "~(i));
    #    } elsif (armSelect == i+1 and armament.AIM9.active[i].status == MISSILE_STANDBY and getprop("payload/weight["~ (i) ~"]/selected") != "none" and input.combat.getValue() == 2) {
    #      #pylon selected, missile mounted, in tactical mode, activate search
    #      armament.AIM9.active[i].status = MISSILE_SEARCH;#print("active "~(i));
    #      armament.AIM9.active[i].search();
    #    }
    #  }
    #}

    var selected = nil;
    for(var i=0; i<=4; i=i+1) { # set JSBSim mass
      selected = getprop("payload/weight["~i~"]/selected");
      if(selected == "none") {
        # the pylon is empty, set its pointmass to zero
        if (getprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~ (i) ~"]") != 0) {
          setprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~ (i) ~"]", 0);
        }
        if(i==0) {
        # no drop tank attached, clear tank
	setprop("/consumables/fuel/tank[11]/selected",0);
	setprop("/consumables/fuel/tank[11]/jettisoned",1);
	setprop("/consumables/fuel/tank[11]/level-norm",0);
        }
        if(i==2) {
        # no drop tank attached, clear tank
	setprop("/consumables/fuel/tank[10]/selected",0);
	setprop("/consumables/fuel/tank[10]/jettisoned",1);
	setprop("/consumables/fuel/tank[10]/level-norm",0);
        }
        if(i==4) {
        # no drop tank attached, clear tank
	setprop("/consumables/fuel/tank[12]/selected",0);
	setprop("/consumables/fuel/tank[12]/jettisoned",1);
	setprop("/consumables/fuel/tank[12]/level-norm",0);
        }
      } elsif (selected == "R-60") {
        # the pylon has a misile, give it a pointmass
        if (getprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~ (i) ~"]") != 96) {
          setprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~ (i) ~"]", 96);
        }
        if(i==0) {
        # no drop tank attached, clear tank
        setprop("/consumables/fuel/tank[2]/selected",0);
        setprop("/consumables/fuel/tank[2]/jettisoned",1);
        setprop("/consumables/fuel/tank[2]/level-norm",0);
        }
        if(i==2) {
        # no drop tank attached, clear tank
        setprop("/consumables/fuel/tank[1]/selected",0);
        setprop("/consumables/fuel/tank[1]/jettisoned",1);
        setprop("/consumables/fuel/tank[1]/level-norm",0);
        }
        if(i==4) {
        # no drop tank attached, clear tank
        setprop("/consumables/fuel/tank[3]/selected",0);
        setprop("/consumables/fuel/tank[3]/jettisoned",1);
        setprop("/consumables/fuel/tank[3]/level-norm",0);
        }
      } elsif (selected == "FAB-250") {
        # the pylon has a bomb, give it a pointmass
        if (getprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~ (i) ~"]") != 520) {
          setprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~ (i) ~"]", 520);
        }
        if(i==0) {
        # no drop tank attached, clear tank
        setprop("/consumables/fuel/tank[2]/selected",0);
        setprop("/consumables/fuel/tank[2]/jettisoned",1);
        setprop("/consumables/fuel/tank[2]/level-norm",0);
        }
        if(i==2) {
        # no drop tank attached, clear tank
        setprop("/consumables/fuel/tank[1]/selected",0);
        setprop("/consumables/fuel/tank[1]/jettisoned",1);
        setprop("/consumables/fuel/tank[1]/level-norm",0);
        }
        if(i==4) {
        # no drop tank attached, clear tank
        setprop("/consumables/fuel/tank[3]/selected",0);
        setprop("/consumables/fuel/tank[3]/jettisoned",1);
        setprop("/consumables/fuel/tank[3]/level-norm",0);
        }
      } elsif (selected == "Kh-25") {
        # the pylon has a bomb, give it a pointmass
        if (getprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~ (i) ~"]") != 659) {
          setprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~ (i) ~"]", 659);
        }
        if(i==0) {
        # no drop tank attached, clear tank
        setprop("/consumables/fuel/tank[2]/selected",0);
        setprop("/consumables/fuel/tank[2]/jettisoned",1);
        setprop("/consumables/fuel/tank[2]/level-norm",0);
        }
        if(i==2) {
        # no drop tank attached, clear tank
        setprop("/consumables/fuel/tank[1]/selected",0);
        setprop("/consumables/fuel/tank[1]/jettisoned",1);
        setprop("/consumables/fuel/tank[1]/level-norm",0);
        }
        if(i==4) {
        # no drop tank attached, clear tank
        setprop("/consumables/fuel/tank[3]/selected",0);
        setprop("/consumables/fuel/tank[3]/jettisoned",1);
        setprop("/consumables/fuel/tank[3]/level-norm",0);
        }
      } elsif (selected == "UB-32") {
        # the pylon has a bomb, give it a pointmass
        if (getprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~ (i) ~"]") != 582) {
          setprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~ (i) ~"]", 582);
        }
        if(i==0) {
        # no drop tank attached, clear tank
        setprop("/consumables/fuel/tank[2]/selected",0);
        setprop("/consumables/fuel/tank[2]/jettisoned",1);
        setprop("/consumables/fuel/tank[2]/level-norm",0);
        }
        if(i==2) {
        # no drop tank attached, clear tank
        setprop("/consumables/fuel/tank[1]/selected",0);
        setprop("/consumables/fuel/tank[1]/jettisoned",1);
        setprop("/consumables/fuel/tank[1]/level-norm",0);
        }
        if(i==4) {
        # no drop tank attached, clear tank
        setprop("/consumables/fuel/tank[3]/selected",0);
        setprop("/consumables/fuel/tank[3]/jettisoned",1);
        setprop("/consumables/fuel/tank[3]/level-norm",0);
        }
      } elsif (selected == "PTB-490 Droptank") {
        # the pylon has a drop tank, give it a pointmass
        if (getprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~ (i) ~"]") != 180) {
          setprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~ (i) ~"]", 180);
        }
      } elsif (selected == "PTB-800 Droptank") {
        # the pylon has a drop tank, give it a pointmass
        if (getprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~ (i) ~"]") != 230) {
          setprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~ (i) ~"]", 230);
        }
      }
    }

    settimer(
      #func debug.benchmark("j37 loop",
        update_loop
        #)
    , UPDATE_PERIOD);
  }


############################# main init ###############


var main_init = func {
  setprop("sim/time/elapsed-at-init-sec", getprop("sim/time/elapsed-sec"));

  setprop("/consumables/fuel/tank[1]/jettisoned", FALSE);
  setprop("/consumables/fuel/tank[2]/jettisoned", FALSE);
  setprop("/consumables/fuel/tank[3]/jettisoned", FALSE);

  # Load exterior at startup to avoid stale sim at first external view selection. ( taken from TU-154B )
  print("Loading exterior, wait...");
  # return to cabin to next cycle
  settimer( load_interior, 0 );
  setprop("/sim/current-view/view-number", 1);
  setprop("/sim/gui/tooltips-enabled", TRUE);

  # setup property nodes for the loop
  foreach(var name; keys(input)) {
      input[name] = props.globals.getNode(input[name], 1);
  }

  #screen.log.write("Welcome to MiG-21bis, version "~getprop("sim/aircraft-version"), 1.0, 0.2, 0.2);

  # start the main loop
	settimer(func { update_loop() }, 0.1);
}

var load_interior = func{
    setprop("/sim/current-view/view-number", 0);
    print("..Done!");
  }

var main_init_listener = setlistener("sim/signals/fdm-initialized", func {
	main_init();
	removelistener(main_init_listener);
 }, 0, 0);

var re_init_listener = setlistener("/sim/signals/reinit", func {
  re_init();
 }, 0, 0);


var noop = func {
  #does nothing, but important
}
