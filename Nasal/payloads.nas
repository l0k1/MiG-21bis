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
var ir_sar_switch = "/controls/armament/panel/ir-sar-switch";
var ag_panel_switch = "/controls/armament/panel/air-gnd-switch";

############### Main loop ###############

input = {
  replay:           "sim/replay/replay-state",
  elapsed:          "sim/time/elapsed-sec",
  impact:			"/ai/models/model-impact",
};

var pos_arm = {
	new: func(brevity, weight, type, ammo_count = 0) {
		var m = {parents:[pos_arm]};
		m.brevity = brevity;
		m.weight = weight;
		m.type = type;
		m.ammo_count = ammo_count;
		return m;
	}
};

var payloads = {
	#payload format is:
	#name: pos_arm.new(brevity code, weight, type/guidance, ammo count (optional)
	#bomb names can NOT have spaces in them.
	#type/guidance options: none (dnu),radar, ir, beam, bomb, rocket, tank, antirad, heavy
	"none":					pos_arm.new("none",0,"none"),
	# ir missiles
	"R-60":					pos_arm.new("R-60",96,"ir"),
	"R-27T1":				pos_arm.new("R-27T1",550,"ir"),
	# radar missiles
	"R-27R1":				pos_arm.new("R-27R1",560,"radar"),
	# bombs
	"FAB-250":				pos_arm.new("FAB-250",520,"bomb"),
	"FAB-500":				pos_arm.new("FAB-500",1146,"bomb"),
	# heavy
	"RN-14T":				pos_arm.new("RN-14T",856,"heavy"),
	"RN-18T":				pos_arm.new("RN-18T",1150,"heavy"),
	"RN-24":				pos_arm.new("RN-24",860,"heavy"),
	"RN-28":				pos_arm.new("RN-28",1200,"heavy"),
	# anti-radiation
	"Kh-25":				pos_arm.new("Kh-25",695,"antirad"),
	# beam
	"Kh-66":				pos_arm.new("Kh-66",632,"beam"),
	# rockets
	"UB-16":				pos_arm.new("UB-32",475,"rocket",16),
	"UB-32":				pos_arm.new("UB-32",582,"rocket",32),
	"S-21":					pos_arm.new("S-21",341,"rocket"), #no real info found (yet)
	"S-24":					pos_arm.new("S-24",518,"rocket"),
	"PTB-490 Droptank":		pos_arm.new("PTB-490 Droptank",180,"tank"),
	"PTB-800 Droptank":		pos_arm.new("PTB-800 Droptank",230,"tank"),
	"Smokepod":				pos_arm.new("smokepod",157,"tank")
};

var loop_time = 0;

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
			if (payloads[selected].type == "ir" or payloads[selected].type == "radar" or payloads[selected].type == "antirad") {
				if(armament.AIM.active[i] != nil and armament.AIM.active[i].type != selected) {
					#print("deleting "~i~" due to type != selected");
					armament.AIM.active[i].del();
				}
				if(armament.AIM.new(i, selected, payloads[selected].brevity) == -1 and armament.AIM.active[i].status == MISSILE_FLYING) {
					setprop("controls/armament/station["~(i+1)~"]/released", TRUE);
					setprop("payload/weight["~ (i) ~"]/selected", "none");
				}
			}
			if ( payloads[selected].type == "bomb" ) {
				setprop("payload/released/"~selected~"["~i~"]",0);
			}
		} elsif (selected == "none") {
			if ( armament.AIM.active[i] != nil ) {
				#print("deleting "~i~" due to pylon being none.");
				armament.AIM.active[i].del();
			}
			setprop("payload/released/"~selected~"["~i~"]",0);
		}
	}
	# need seperate logic for pylons 5/6/7/8, which is what the r-60 doubles will be using.
	
	
	############ MISSILE ARMING LOGIC ################
	var armSelect = pylon_select();
	for ( i = 0; i <= 4; i += 1 ) {
		#print("in arming logic");
		var payloadName = getprop("/payload/weight[" ~ i ~ "]/selected");
		if (payloads[payloadName].type == "ir" or payloads[payloadName].type == "radar" or payloads[payloadName].type == "antirad") {
			if ( armament.AIM.active[i] != nil ) {
				if ( armSelect[0] != i and armSelect[1] != i and armament.AIM.active[i].status != MISSILE_FLYING ) {
					#print("setting pylon " ~ i ~ " to standby");
					armament.AIM.active[i].status = MISSILE_STANDBY;
				} elsif ( armament.AIM.active[i].status != MISSILE_STANDBY and armament.AIM.active[i] != MISSILE_FLYING and payloadName == "none" ) {
					#print("setting pylon " ~ i ~ " to standby");
					armament.AIM.active[i].status = MISSILE_STANDBY;
				} elsif ( (armSelect[0] == i or armSelect[1] == i) and armament.AIM.active[i].status == MISSILE_STANDBY ) {
					#print("missile " ~i~ " should be searching.");
					armament.AIM.active[i].status = MISSILE_SEARCH;
					armament.AIM.active[i].search();
				}
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
				setprop("/consumables/fuel/tank[12]/selected",0);
				setprop("/consumables/fuel/tank[12]/jettisoned",1);
				setprop("/consumables/fuel/tank[12]/level-norm",0);
			}
			if(i==2) {
				#print("jettisoning 2");;
				# no drop tank attached, clear tank
				setprop("/consumables/fuel/tank[11]/selected",0);
				setprop("/consumables/fuel/tank[11]/jettisoned",1);
				setprop("/consumables/fuel/tank[11]/level-norm",0);
			}
			if(i==4) {
				#print("jettisoning 4");
				# no drop tank attached, clear tank
				setprop("/consumables/fuel/tank[13]/selected",0);
				setprop("/consumables/fuel/tank[13]/jettisoned",1);
				setprop("/consumables/fuel/tank[13]/level-norm",0);
			}
		} elsif ( selected == "PTB-800 Droptank" or selected == "PTB-490 Droptank" ) {
			if(i==0) {
				setprop("/consumables/fuel/tank[12]/selected",1);
			}
			if(i==2) {
				setprop("/consumables/fuel/tank[11]/selected",1);
				if ( selected == "PTB-490 Droptank" and getprop("/consumables/fuel/tank[11]/level-lbs") > 850 ) {
					setprop("/consumables/fuel/tank[11]/level-lbs",850)
				}
			}
			if(i==4) {
				setprop("/consumables/fuel/tank[13]/selected",1);
			}
		}
	}
	
	#cannon ammo counter and jamming
	if ( getprop("controls/armament/trigger") == 1 and  getprop("payload/armament/GSh-30/jammed") == 0 ) {
		var cur_ammo = getprop("payload/armament/GSh-30/ammo");
		if (cur_ammo > 0) {
			var jam_prob = rand();
			#print("jam_prob: " ~ jam_prob);
			if (jam_prob < 0.005) {
				setprop("payload/armament/GSh-30/jammed",1);
				setprop("payload/armament/GSh-30/trigger",0);
				print("GSh-30 has jammed!");
			}
			var scnd = getprop("/sim/time/elapsed-sec")  - loop_time;
			var spent= int(58.3 * scnd);
			#print("scnd: " ~ scnd);
			#print("spent: " ~ spent);
			cur_ammo = math.clamp(cur_ammo - spent,0,200);
			setprop("payload/armament/GSh-30/trigger",1);
			setprop("payload/armament/GSh-30/ammo",cur_ammo);
		} else {
			setprop("payload/armament/GSh-30/trigger",0);
			setprop("controls/armament/panel/gun-ready",0);
		}
	} else {
		setprop("payload/armament/GSh-30/trigger",0);
	}
	
	loop_time = getprop("/sim/time/elapsed-sec");
	
	settimer(update_loop, UPDATE_PERIOD);
}

########### listener for handling unjamming #########

var charge_used = [0,0,0];

var unjam = func(button) {
	print("inside unjam");
	print("button: " ~ button);
	print("button value: " ~ charge_used[button]);
	if ( charge_used[button] == 0 ) {
		charge_used[button] = 1;
		setprop("payload/armament/GSh-30/jammed",0);
	}
}

setlistener("controls/armament/panel/reload[0]", func { unjam(0); } );
setlistener("controls/armament/panel/reload[1]", func { unjam(1); } );
setlistener("controls/armament/panel/reload[2]", func { unjam(2); } );

###########  listener for handling the trigger #########

var missile_release_listener = func {
	var armSelect = pylon_select();
	
	selected0 = payloads[getprop("payload/weight["~(armSelect[0])~"]/selected") ];
	if ( armSelect[1] != -1 ) {	
		selected1 = payloads[getprop("payload/weight["~(armSelect[1])~"]/selected") ];
	}
	#print("in listener");
	#print("armselect0: " ~ armSelect[0]);
	#print("armselect1: " ~ armSelect[1]);
	#print("armselect2: " ~ armSelect[2]);
	#print("release prop: " ~ getprop("/fdm/jsbsim/systems/armament/release"));
	if (getprop("/fdm/jsbsim/systems/armament/release") == 1 )  {
		#print("selected0.type: " ~ selected0.type);
		#print("iar_sar_switch: " ~ getprop(ir_sar_switch));
		
		
		if (armSelect[2] >= 5 ) {
			# missile launch logic
			if ((selected0.type = "ir" and getprop(ir_sar_switch) == 0 ) or ( selected0.type = "radar" and getprop(ir_sar_switch) == 2 )) {
				missile_release(armSelect[0]);
			}
			if ( armSelect[1] != -1 and getprop("payload/weight["~(armSelect[1])~"]/selected") != "none") {
				if ((selected1.type = "ir" and getprop(ir_sar_switch) == 0 ) or ( selected1.type = "radar" and getprop(ir_sar_switch) == 2 )) { #if is IR/Radar missile, and weapon selector is in missile range
				settimer(func { 
					missile_release(armSelect[1]); 
					}, 0.75);
				}
			}
			

		} elsif (armSelect[2] <= 2) {
			#bombs and/or multi-rockets
			if (selected0.type == "bomb" and getprop(ag_panel_switch) == 2 ) {
				bomb_release(armSelect[0]);
			}
			if ( armSelect[1] != -1 and getprop("payload/weight["~(armSelect[1])~"]/selected") != "none") {
				if (selected1.type == "bomb" and getprop(ag_panel_switch) == 2 ) {
					settimer(func { 
						bomb_release(armSelect[1]); 
					}, 0.75);
				}
			}
		}
	}
}

var heavy_release_listener = func {
	var selected = getprop("payload/weight[2]/selected");
	if ( payloads[selected].type = "heavy" ) {
		bomb_release(2);
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
	if(getprop("payload/weight["~(pylon)~"]/selected") != "none") { 
		# trigger is pulled, a pylon is selected, the pylon has a missile that is locked on. The gear check is prevent missiles from firing when changing airport location.
		if (armament.AIM.active[pylon] != nil and armament.AIM.active[pylon].status == 1 and radar_logic.selection != nil) {
			#missile locked, fire it.

			print("firing missile: "~pylon);
			var callsign = armament.AIM.active[pylon].callsign;
			var brevity = armament.AIM.active[pylon].brevity;
			armament.AIM.active[pylon].release();
			setprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~pylon~"]",0);
			setprop("payload/weight["~(pylon)~"]/selected", "none");
			var phrase = brevity ~ " at: " ~ callsign;
			if (getprop("payload/armament/msg")) {
				defeatSpamFilter(phrase);
			} else {
				setprop("/sim/messages/atc", phrase);
			}
			
		}
	}
}

var bomb_release = func(pylon) {
	var selected = getprop("payload/weight[" ~ ( pylon ) ~ "]/selected");
	if ( selected != "none" ) {
		print("dropping bomb: " ~ payloads[selected].brevity ~ ": pylon " ~ pylon);
		setprop("payload/weight[" ~ ( pylon ) ~ "]/selected", "none" );
		setprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~pylon~"]",0);
		setprop("payload/released/"~selected~"["~pylon~"]",1);
		var phrase = payloads[selected].brevity ~ " released.";
		if (getprop("payload/armament/msg")) {
			defeatSpamFilter(phrase);
		} else {
			setprop("/sim/messages/atc", phrase);
		}
	}
}
		
############ Impact messages #####################

var hit_count = 0;
var hit_callsign = "";
var hit_timer = 0;
var closest_distance = 200;

var impact_listener = func {
	#print(payloads["FAB-500"].type);
    var ballistic_name = input.impact.getValue();
    var ballistic = props.globals.getNode(ballistic_name, 0);
	var closest_distance = 10000;
	var inside_callsign = "";
	#print("inside listener");
    if (ballistic != nil) {
		#print("ballistic isn't nil");
		var typeNode = ballistic.getNode("impact/type");
		var typeOrd = ballistic.getNode("name").getValue();
		#print("typeOrd: " ~ typeOrd);
		if (typeNode != nil) {
			#print("typenode isnt nil");
			var lat = ballistic.getNode("impact/latitude-deg").getValue();
			var lon = ballistic.getNode("impact/longitude-deg").getValue();
			var impactPos = geo.Coord.new().set_latlon(lat, lon);
			if (typeOrd == "GSh-23" and typeNode.getValue() != "terrain") {
				closest_distance = 35;
				foreach(var mp; props.globals.getNode("/ai/models").getChildren("multiplayer")){
					#print("Gau impact - hit: " ~ typeNode.getValue());
					var mlat = mp.getNode("position/latitude-deg").getValue();
					var mlon = mp.getNode("position/longitude-deg").getValue();
					var malt = mp.getNode("position/altitude-ft").getValue() * FT2M;
					var selectionPos = geo.Coord.new().set_latlon(mlat, mlon, malt);
					var distance = impactPos.distance_to(selectionPos);
					#print("distance = " ~ distance);
					if (distance < closest_distance) {
						closest_distance = distance;
						inside_callsign = mp.getNode("callsign").getValue();
					}
				}

				if ( inside_callsign != "" ) {
					#we have a successful hit
					#print("successful hit");
					if ( inside_callsign == hit_callsign ) {
						hit_count = hit_count + 1;
						#print("hit_count: " ~ hit_count);
					} else {
						#print("new callsign");
						hit_callsign = inside_callsign;
						hit_count = 1;
					}
					if ( hit_timer == 0 ) {
						hit_timer = 1;
						#print("should be going into the timer...");
						settimer(func{hitmessage(typeOrd);},1);
					}
				}
			}elsif (payloads[typeOrd] != nil and payloads[typeOrd].type == "bomb")  {
				#print("bomb impact!");
				closest_distance = 250;
				foreach(var mp; props.globals.getNode("/ai/models").getChildren("multiplayer")){
					var mlat = mp.getNode("position/latitude-deg").getValue();
					var mlon = mp.getNode("position/longitude-deg").getValue();
					var malt = mp.getNode("position/altitude-ft").getValue() * FT2M;
					var selectionPos = geo.Coord.new().set_latlon(mlat, mlon, malt);
					var distance = impactPos.distance_to(selectionPos);
					#print("distance = " ~ distance);
					if (distance < closest_distance) {
						closest_distance = distance;
						inside_callsign = mp.getNode("callsign").getValue();
					}
				}
				if (inside_callsign != "" ) {
					defeatSpamFilter(sprintf( typeOrd~" exploded: %01.1f", distance) ~ " meters from: " ~ inside_callsign);
				}
			}elsif (payloads[typeOrd] != nil and payloads[typeOrd].type == "heavy")  {
				#print("bomb impact!");
				closest_distance = 1000;
				foreach(var mp; props.globals.getNode("/ai/models").getChildren("multiplayer")){
					var mlat = mp.getNode("position/latitude-deg").getValue();
					var mlon = mp.getNode("position/longitude-deg").getValue();
					var malt = mp.getNode("position/altitude-ft").getValue() * FT2M;
					var selectionPos = geo.Coord.new().set_latlon(mlat, mlon, malt);
					var distance = impactPos.distance_to(selectionPos);
					#print("distance = " ~ distance);
					if (distance < closest_distance) {
						closest_distance = distance;
						inside_callsign = mp.getNode("callsign").getValue();
					}
				}
				if (inside_callsign != "" ) {
					defeatSpamFilter(sprintf( typeOrd~" exploded: %01.1f", distance) ~ " meters from: " ~ inside_callsign);
				}
			}
		}
	}
}

var hitmessage = func(typeOrd) {
	#print("inside hitmessage");
	message = typeOrd ~ " hit: " ~ hit_callsign ~ ": " ~ hit_count ~ " hits";
	defeatSpamFilter(message);
	hit_callsign = "";
	hit_timer = 0;
	hit_count = 0;
}

############ Smokepod Cannon Trigger Controller##############

setlistener("/controls/smokepod/trigger", func() {
	trig = getprop("/controls/smokepod/trigger");
	if ( trig ) {
		var color = getprop("/controls/smokepod/color");
		if (color == "white") { 
			var cn = 1
		}
		elsif (color == "red") { 
			var cn = 2 
		}
		elsif (color == "orange") {
			var cn = 3
		}
		elsif (color == "yellow") {
			var cn = 4
		}
		elsif (color == "green") {
			var cn = 5 
		}
		elsif (color == "blue") { 
			var cn = 6
		}
		elsif (color == "purple") { 
			var cn = 7 
		}
		elsif (color == "rainbow (2 sec)"){
			paint_the_rainbow(2.0);
			return;
		}
		elsif (color == "rainbow (4 sec)"){
			paint_the_rainbow(4.0);
			return;
		}
		elsif (color == "red white black"){
			red_white_black(2.0);
			return;
		}
		else { 
			var cn = 8;
		}
		setprop("/sim/multiplay/generic/int[19]",cn);
	} else {
		setprop("/sim/multiplay/generic/int[19]",0);
	}
});

var paint_the_rainbow = func(timer) {
	if (getprop("/controls/smokepod/trigger") ) {
		var cc = getprop("/sim/multiplay/generic/int[19]");
		if ( cc > 1 and cc < 7 ) {
			cc = cc + 1;
		} else {
			cc = 2;
		}
		setprop("/sim/multiplay/generic/int[19]",cc);
		settimer( func { paint_the_rainbow(timer); }, timer);
	}	else {
		setprop("/sim/multiplay/generic/int[19]",0);
		return;
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
		return [0,4,knobpos];
	} elsif ( knobpos == 2 ) {
		return [0,3,knobpos]
	} elsif ( knobpos == 1 or knobpos == 4 or knobpos == 5 ) { #3,4
		return [1,3,knobpos]
	} elsif ( knobpos == 7 ) {
		return [0,-1,knobpos]
	} elsif ( knobpos == 8 ) {
		return [4,-1,knobpos]
	} elsif ( knobpos == 9 ) {
		return [1,-1,knobpos]
	} elsif ( knobpos == 10 ) {
		return [3,-1,knobpos]
	}
}
	

var main_init = func {
  print("initting!");
  setprop("sim/time/elapsed-at-init-sec", getprop("sim/time/elapsed-sec"));

  setprop("/consumables/fuel/tank[11]/jettisoned", FALSE);
  setprop("/consumables/fuel/tank[12]/jettisoned", FALSE);
  setprop("/consumables/fuel/tank[13]/jettisoned", FALSE);

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
  setlistener("/fdm/jsbsim/systems/armament/release", missile_release_listener);
  setlistener("fdm/jsbsim/systems/armament/heavy-release", heavy_release_listener);

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