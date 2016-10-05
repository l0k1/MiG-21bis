#
# Code largely copied from Nikolai V. Chr.'s most excellent Viggen.
#
#
#
#
#

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
  tank1LvlGal:      "/consumables/fuel/tank[10]/level-gal_us",
  tank2LvlGal:      "/consumables/fuel/tank[11]/level-gal_us",
  tank3LvlGal:      "/consumables/fuel/tank[12]/level-gal_us",
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
  acInstrVolt:      "systems/electrical/outputs/ac-instr-voltage",
  acMainVolt:       "systems/electrical/outputs/ac-main-voltage",
  asymLoad:         "fdm/jsbsim/inertia/asymmetric-wing-load",
  combat:           "/ja37/hud/current-mode",
  dcVolt:           "systems/electrical/outputs/dc-voltage",
  elapsed:          "sim/time/elapsed-sec",
  elecMain:         "controls/electric/main",
  engineRunning:    "engines/engine/running",
  gearCmdNorm:      "/fdm/jsbsim/gear/gear-cmd-norm",
  gearsPos:         "gear/gear/position-norm",
  hz05:             "ja37/blink/five-Hz/state",
  hz10:             "ja37/blink/ten-Hz/state",
  hzThird:          "ja37/blink/third-Hz/state",
  impact:           "/ai/models/model-impact",
  mass1:            "fdm/jsbsim/inertia/pointmass-weight-lbs[1]",
  mass3:            "fdm/jsbsim/inertia/pointmass-weight-lbs[3]",
  mass5:            "fdm/jsbsim/inertia/pointmass-weight-lbs[5]",
  mass6:            "fdm/jsbsim/inertia/pointmass-weight-lbs[6]",
  MPfloat2:         "sim/multiplay/generic/float[2]",
  MPfloat9:         "sim/multiplay/generic/float[9]",
  MPint17:          "sim/multiplay/generic/int[17]",
  MPint18:          "sim/multiplay/generic/int[18]",
  MPint19:          "sim/multiplay/generic/int[19]",
  MPint9:           "sim/multiplay/generic/int[9]",
  replay:           "sim/replay/replay-state",
  serviceElec:      "systems/electrical/serviceable",
  stationSelect:    "controls/armament/station-select",
  subAmmo2:         "ai/submodels/submodel[2]/count", 
  subAmmo3:         "ai/submodels/submodel[3]/count", 
  subAmmo9:         "ai/submodels/submodel[9]/count", 
  subAmmo10:         "ai/submodels/submodel[10]/count", 
  subAmmo11:         "ai/submodels/submodel[11]/count", 
  subAmmo12:         "ai/submodels/submodel[12]/count",
  subAmmo13:         "ai/submodels/submodel[13]/count", 
  subAmmo14:         "ai/submodels/submodel[14]/count", 
  tank8Jettison:    "/consumables/fuel/tank[8]/jettisoned",
  tank8LvlNorm:     "/consumables/fuel/tank[8]/level-norm",
  tank8Selected:    "/consumables/fuel/tank[8]/selected",
  trigger:          "controls/armament/trigger",
  wow0:             "fdm/jsbsim/gear/unit[0]/WOW",
  wow1:             "fdm/jsbsim/gear/unit[1]/WOW",
  wow2:             "fdm/jsbsim/gear/unit[2]/WOW",
  dev:              "dev",
};

var pos_arm = {
	new: func(long_name, weight, type = "missile", ammo_count = 0) {
		var m = {parents:[pos_arm]};
		m.long_name = long_name;
		m.weight = weight;
		m.type = type;
		m.ammo_count = ammo_count;
		return m;
	}
};

var payloads = {
	"none":					pos_arm.new("none",0,"none"),
	"R-60":					pos_arm.new("R-60",960),
	"FAB-250":				pos_arm.new("FAB-250",520),
	"Kh-25":				pos_arm.new("Kh-25",659),
	"UB-32":				pos_arm.new("UB-32",582,"rocket",32),
	"PTB-490 Droptank":		pos_arm.new("PTB-490 Droptank",180,"tank"),
	"PTB-800 Droptank":		pos_arm.new("PTB-800 Droptank",230,"tank")
};

var update_loop = func {

	if(input.replay.getValue() == TRUE) {
		# replay is active, skip rest of loop.
		settimer(update_loop, UPDATE_PERIOD);
	}
	
	# pylon payloads
	for(var i=0; i<=4; i=i+1) {
		var selected = getprop("payload/weight["~ (i) ~"]/selected");
		if(selected != "none" and getprop("payload/weight["~ (i) ~"]/weight-lb") == 0) {
			setprop("controls/armament/station["~(i)~"]/released", FALSE);
			if (payloads[selected].type == "missile") {
				if(armament.AIM.active[i] != nil and armament.AIM.active[i].type != selected) {
					armament.AIM.active[i].del();
				}
				if(armament.AIM.new(i, selected, payloads[selected].long_name) == -1 and armament.AIM.active[i].status == MISSILE_FLYING) {
					setprop("controls/armament/station["~(i+1)~"]/released", TRUE);
					setprop("payload/weight["~ (i) ~"]/selected", "none");
				}
			}
		} elsif (selected == "none") {
			if ( armament.AIM.active[i] != nil ) {
				armament.AIM.active[i].del();
			}
		}
	}
	
	
	############ MISSILE ARMING LOGIC ################
	var armSelect = pylon_select();
	for ( i = 0; i <= 4; i += 1 ) {
		var payloadName = getprop("/payload/weight[" ~ i ~ "]/selected");
		if ( armament.AIM.active[i] != nil ) {
			if ( armSelect[0] != i and armSelect[1] != i and armament.AIM.active[i].status != MISSILE_FLYING ) {
				armament.AIM.active[i].status = MISSILE_STANDBY;
			} elsif ( armament.AIM.active[i].status != MISSILE_STANDBY and armament.AIM.active[i] != MISSILE_FLYING and payloadName == "none" ) {
				armament.AIM.active[i].status = MISSILE_STANDBY;
			} elsif ( (armSelect[0] == i or armSelect[1] == i) and armament.AIM.active[i].status == MISSILE_STANDBY ) {
				armament.AIM.active[i].status = MISSILE_SEARCH;
				armament.AIM.active[i].search();
			}
		}
	}
	
	############ JSBSIM SET MASS ##############
	var selected = nil;
	for(var i=0; i<=4; i=i+1) { # set JSBSim mass
		selected = getprop("payload/weight["~i~"]/selected");
		
		if (getprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~ (i) ~"]") != payloads[selected].weight) {
			setprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~ (i) ~"]", payloads[selected].weight);
		}

		if ( selected != "PTB-800 Droptank" and selected != "PTB-490 Droptank" ) {
			#print("selected: " ~ selected);
			if(i==0) {
				#print("jettisoning 0");
				# no drop tank attached, clear tank
				setprop("/consumables/fuel/tank[11]/selected",0);
				setprop("/consumables/fuel/tank[11]/jettisoned",1);
				setprop("/consumables/fuel/tank[11]/level-norm",0);
			}
			if(i==2) {
				#print("jettisoning 2");;
				# no drop tank attached, clear tank
				setprop("/consumables/fuel/tank[10]/selected",0);
				setprop("/consumables/fuel/tank[10]/jettisoned",1);
				setprop("/consumables/fuel/tank[10]/level-norm",0);
			}
			if(i==4) {
				#print("jettisoning 4");
				# no drop tank attached, clear tank
				setprop("/consumables/fuel/tank[12]/selected",0);
				setprop("/consumables/fuel/tank[12]/jettisoned",1);
				setprop("/consumables/fuel/tank[12]/level-norm",0);
			}
		}
	}
	settimer(update_loop, UPDATE_PERIOD);
}

###########  listener for handling the trigger #########

var missile_release_listener = func {

	var armSelect = pylon_select();
	print("listener triggered");
	
	if ( getprop("controls/armament/missile-release") == 1 ) {
	
		missile_release(armSelect[0]);
		
		if ( armSelect[1] != -1 and getprop("payload/weight["~(armSelect[1])~"]/selected") != "none") {
			settimer(func { missile_release(armSelect[1]); }, 1.5);
		}
		
	}
}
  
  #pylon knob
  #0: 1/2 bomb | 16 rkt
  #1: 3/4 bomb | 8 rkt
  #2: 1/4 bomb | 4 rkt
  #3: 1/2 rkt
  #4: 3/4 rkt
  #5: 3/4 msl
  #6: 1/2 msl
  #7: 1 msl
  #8: 2 msl
  #9: 3 msl
  #10: 4 msl
  #pylons go 1,3,4,2 left to right IRL
  #pylons go 0,1,3,4 left to right internally

  #if masterarm is on and HUD in tactical mode, propagate trigger to station
#  if(!(armSelect == 0) {
#  } else {
#    setprop("/controls/armament/station["~armSelect~"]/trigger", FALSE);
#    if (armSelect == 1) {
#      setprop("/controls/armament/station[8]/trigger", FALSE);
#    }
#    if (armSelect == 3) {
#      setprop("/controls/armament/station[9]/trigger", FALSE);
#    }
#    if (armSelect == 7) {
#      setprop("/controls/armament/station[10]/trigger", FALSE);
#    }
#  }
var missile_release = func(pylon) {
	print("in missile release");
	if(getprop("payload/weight["~(pylon)~"]/selected") != "none") { 
		# trigger is pulled, a pylon is selected, the pylon has a missile that is locked on. The gear check is prevent missiles from firing when changing airport location.
		if (armament.AIM.active[pylon] != nil and armament.AIM.active[pylon].status == 1 and radar_logic.selection != nil) {
			#missile locked, fire it.

			#print("firing missile: "~armSelect~" "~getprop("controls/armament/station["~armSelect~"]/released"));
			var callsign = armament.AIM.active[pylon].callsign;
			var brevity = armament.AIM.active[pylon].brevity;
			armament.AIM.active[pylon].release();#print("release "~(armSelect-1));

			var phrase = brevity ~ " at: " ~ callsign;
			if (getprop("payload/armament/msg")) {
				armament.defeatSpamFilter(phrase);
			} else {
				setprop("/sim/messages/atc", phrase);
			}
			
		}
	}
}
############ Cannon impact messages #####################

var last_impact = 0;

var hit_count = 0;

var impact_listener = func {
  if (radar_logic.selection != nil and (input.elapsed.getValue()-last_impact) > 1) {
    var ballistic_name = input.impact.getValue();
    var ballistic = props.globals.getNode(ballistic_name, 0);
    if (ballistic != nil) {
      var typeNode = ballistic.getNode("impact/type");
      if (typeNode != nil and typeNode.getValue() != "terrain") {
        var lat = ballistic.getNode("impact/latitude-deg").getValue();
        var lon = ballistic.getNode("impact/longitude-deg").getValue();
        var impactPos = geo.Coord.new().set_latlon(lat, lon);

        var selectionPos = radar_logic.selection.get_Coord();

        var distance = impactPos.distance_to(selectionPos);
        if (distance < 125) {
          last_impact = input.elapsed.getValue();
          var phrase =  ballistic.getNode("name").getValue() ~ " hit: " ~ radar_logic.selection.get_Callsign();
          if (getprop("payload/armament/msg")) {
            defeatSpamFilter(phrase);
			      #hit_count = hit_count + 1;
          } else {
            setprop("/sim/messages/atc", phrase);
          }
        }
      }
    }
  }
}

############################# main init ###############

var pylon_select = func() {
	#return array of active pylons
	#returning -1 means no pylon selected
	
	#pylon knob
	#0: 1/2 bomb | 16 rkt
	#1: 3/4 bomb | 8 rkt
	#2: 1/4 bomb | 4 rkt
	#3: 1/2 rkt
	#4: 3/4 rkt
	#5: 3/4 msl
	#6: 1/2 msl
	#7: 1 msl
	#8: 2 msl
	#9: 3 msl
	#10: 4 msl
	#pylons go 1,3,4,2 left to right IRL
	#pylons go 0,1,3,4 left to right internally
	
	var knobpos = getprop("controls/armament/panel/pylon-knob");
	if ( knobpos == 0 or knobpos == 3 or knobpos == 6 ) {
		return [0,4];
	} elsif ( knobpos == 2 ) {
		return [0,3]
	} elsif ( knobpos == 1 or knobpos == 4 or knobpos == 5 ) { #3,4
		return [1,3]
	} elsif ( knobpos == 7 ) {
		return [0,-1]
	} elsif ( knobpos == 8 ) {
		return [4,-1]
	} elsif ( knobpos == 9 ) {
		return [1,-1]
	} elsif ( knobpos == 10 ) {
		return [3,-1]
	}
}
	

var main_init = func {
  print("initting!");
  setprop("sim/time/elapsed-at-init-sec", getprop("sim/time/elapsed-sec"));

  setprop("/consumables/fuel/tank[10]/jettisoned", FALSE);
  setprop("/consumables/fuel/tank[11]/jettisoned", FALSE);
  setprop("/consumables/fuel/tank[12]/jettisoned", FALSE);

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

  screen.log.write("Welcome to MiG-21bis!", 1.0, 0.2, 0.2);
	print("youze here");
  setlistener("/fdm/jsbsim/systems/armament/release", missile_release_listener);

  # setup impact listener
  setlistener("/ai/models/model-impact", impact_listener, 0, 0);
  
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

var spams = 0;
var spamList = [];

var defeatSpamFilter = func (str) {
  spams += 1;
  if (spams == 15) {
    spams = 1;
  }
  str = str~":";
  for (var i = 1; i <= spams; i+=1) {
    str = str~".";
  }
  var newList = [str];
  for (var i = 0; i < size(spamList); i += 1) {
    append(newList, spamList[i]);
  }
  spamList = newList;  
}

var spamLoop = func {
  var spam = pop(spamList);
  if (spam != nil) {
    setprop("/sim/multiplay/chat", spam);
  }
  settimer(spamLoop, 1.20);
}

spamLoop();