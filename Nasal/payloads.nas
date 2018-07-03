#
# Code largely copied from Nikolai V. Chr.'s most excellent Viggen.
#
### Pylon mapping:
#pylons go 1,3,4,2 left to right IRL
#pylons go 0,1,3,4 left to right internally

# internal	| in-sim	| usage			| name		| actual/virtual
#--------------------------------------------------------------------
# 0			| 1			| weapons/tank	| outb left	| actual
# 1			| 3			| weapons		| inbd left | actual
# 2			| 5			| tank/h.weaps	| center    | actual
# 3			| 4			| weapons		| inbd rght	| actual
# 4			| 2			| weapons/tank	| outd rght	| actual
# 5			| - 		| cm/jato		| rear left	| actual
# 6			| - 		| cm/jato		| rear rght	| actual
# 7			| -			| r-60#2		| link2 #1	| virtual
# 8			| -			| r-60#2		| link2 #3	| virtual

var UPDATE_PERIOD = 0.1;

var FALSE = 0;
var TRUE = 1;

var MISSILE_STANDBY = -1;
var MISSILE_SEARCH = 0;
var MISSILE_LOCK = 1;
var MISSILE_FLYING = 2;
var ir_sar_switch = "/controls/armament/panel/ir-sar-switch";
var ag_panel_switch = "/controls/armament/panel/air-gnd-switch";
var flareCount = 0;
var flareStart = 0;

############### Main loop ###############

input = {
  replay:           "sim/replay/replay-state",
  elapsed:          "sim/time/elapsed-sec",
  impact:			"/ai/models/model-impact",
};

var pos_arm = {
	new: func(name, brevity, weight, type, hit_max_distance = 65, ammo_count = 0,guidance_func = nil) {
		var m = {parents:[pos_arm]};
		m.name = name;
		m.brevity = brevity;
		m.weight = weight;
		m.type = type;
		m.type_norm = 1;
		if ( type == "radar" ) {
			m.type_norm = 2;
		} else {
			m.type_norm = 0;
		}
		m.ammo_count = ammo_count;
		m.hit_max_distance = hit_max_distance;
		m.guidance_func = guidance_func;
		return m;
	}
};

var payloads = {
	#payload format is:
	#name: pos_arm.new(name, brevity code, weight, type/guidance, hit message max distance (not used for guided missiles), ammo count (optional), guidance function (optional)
	#bomb names can NOT have spaces in them.
	#type/guidance options: none (dnu),radar, ir, beam, bomb, rocket, tank, antirad, heavy
	#regarding hit distance, the GSh-23 is coded as 35m seperately in this file
	"none":					pos_arm.new("none","none",0,"none"),
	# ir missiles
	"R-60":					pos_arm.new("R-60","R-60",96,"ir"),
	"R-60x2":				pos_arm.new("R-60","R-60",96,"ir",,2),
	"R-27T1":				pos_arm.new("R-27T1","R-27T1",550,"ir",,,arm_locking.r27t1_guidance),
	# radar missiles
	"R-27R1":				pos_arm.new("R-27R1","R-27R1",560,"radar"),
	# bombs
	"FAB-100":				pos_arm.new("FAB-100","FAB-100",220,"bomb",250),
	"FAB-250":				pos_arm.new("FAB-250","FAB-250",551,"bomb",250),
	"FAB-500":				pos_arm.new("FAB-500","FAB-500",1146,"bomb",250),
	# heavy
	"RN-14T":				pos_arm.new("RN-14T","RN-14T",856,"heavy",500),
	"RN-18T":				pos_arm.new("RN-18T","RN-18T",1150,"heavy",500),
	"RN-24":				pos_arm.new("RN-24","RN-24",860,"heavy",1000),
	"RN-28":				pos_arm.new("RN-28","RN-28",1200,"heavy",1000),
	# anti-radiation
	"Kh-25":				pos_arm.new("Kh-25","Kh-25",695,"antirad"),
	# beam
	"Kh-66":				pos_arm.new("Kh-66","Kh-66",632,"beam"),
	# rockets
	"UB-16":				pos_arm.new("UB-16","UB-16",141,"rocket",,16),
	"UB-32":				pos_arm.new("UB-32","UB-32",582,"rocket",,32),
	"S-21":					pos_arm.new("S-21","S-21",341,"heavyrocket",60), # search for с-21 ракет (cyrillic)
	"S-24":					pos_arm.new("S-24","S-24",518,"heavyrocket",60),
	"PTB-490 Droptank":		pos_arm.new("PTB-490 Droptank","PTB-490 Droptank",180,"tank"),
	"PTB-800 Droptank":		pos_arm.new("PTB-800 Droptank","PTB-800 Droptank",230,"tank"),
	"Smokepod":				pos_arm.new("smokepod","smokepod",157,"tank")
};

var update_loop = func {

	if(input.replay.getValue() == TRUE) {
		# replay is active, skip rest of loop.
		settimer(update_loop, UPDATE_PERIOD);
	}

	# pylon payloads
	for(var i=0; i<=6; i=i+1) {
		var selected = getprop("payload/weight["~ (i) ~"]/selected");
		if ( selected != nil ) {
			#print("selected"~selected);
			#print("nombre"~payloads[selected].name);
			if(payloads[selected].name != "none" and getprop("payload/weight["~ (i) ~"]/weight-lb") == 0) {
				#print("updating station " ~ i);
				setprop("controls/armament/station["~(i)~"]/released", FALSE);
				#print("type: " ~ payloads[selected].type);
				if (payloads[selected].type == "ir" or
						payloads[selected].type == "radar" or
						payloads[selected].type == "antirad" or
						payloads[selected].type == "beam") {
					if(armament.AIM.active[i] != nil and armament.AIM.active[i].type != payloads[selected].name) {
						#print("deleting "~i~" due to type != selected");
						armament.AIM.active[i].del();
					}
					#print(payloads[selected].name);
					if(selected == "R-60x2") {
						#print("R-60x2 detected");
						if(i == 0){
							#print('setting pylon 1');
							setprop("payload/virtual/weight[7]/selected","R-60");
							setprop("payload/virtual/weight[7]/weight-lb",0);
						} elsif(i == 4){
							#print('setting pylon 3');
							setprop("payload/virtual/weight[8]/selected","R-60");
							setprop("payload/virtual/weight[8]/weight-lb",0);
						}
					}
					#print('setting up pylon ' ~ i ~ ' as ' ~ payloads[selected].name);
					if(armament.AIM.new(i, payloads[selected].name, payloads[selected].brevity, payloads[selected].guidance_func) == -1 and armament.AIM.active[i].status == MISSILE_FLYING) {
						setprop("controls/armament/station["~(i+1)~"]/released", TRUE);
						setprop("payload/weight["~ (i) ~"]/selected", "none");
					}
				}
				if ( payloads[selected].type == "bomb" ) {
					setprop("payload/released/"~payloads[selected].name~"["~i~"]",0);
				}
				if ( payloads[selected].type == "rocket" ) {
					if ( i == 0 ) {
						setprop("/ai/submodels/submodel[22]/count",payloads[selected].ammo_count);
					} elsif ( i == 1 ) {
						setprop("/ai/submodels/submodel[23]/count",payloads[selected].ammo_count);
					} elsif ( i == 3 ) {
						setprop("/ai/submodels/submodel[24]/count",payloads[selected].ammo_count);
					} elsif ( i == 4 ) {
						setprop("/ai/submodels/submodel[25]/count",payloads[selected].ammo_count);
					}
				} else {
					if ( i == 0 ) {
						setprop("/ai/submodels/submodel[22]/count",0);
					} elsif ( i == 1 ) {
						setprop("/ai/submodels/submodel[23]/count",0);
					} elsif ( i == 3 ) {
						setprop("/ai/submodels/submodel[24]/count",0);
					} elsif ( i == 4 ) {
						setprop("/ai/submodels/submodel[25]/count",0);
					}
				}
			} elsif (payloads[selected].name == "none") {
				if ( armament.AIM.active[i] != nil ) {
					#print("deleting "~i~" due to pylon being none.");
					armament.AIM.active[i].del();
					if ( i == 0 ) {
						setprop("payload/virtual/weight[7]/selected","none");
					} elsif (i == 4 ) {
						setprop("payload/virtual/weight[8]/selected","none");
					}
				}

				if ( i == 0 ) {
					setprop("/ai/submodels/submodel[22]/count",0);
				} elsif ( i == 1 ) {
					setprop("/ai/submodels/submodel[23]/count",0);
				} elsif ( i == 3 ) {
					setprop("/ai/submodels/submodel[24]/count",0);
				} elsif ( i == 4 ) {
					setprop("/ai/submodels/submodel[25]/count",0);
				}

				setprop("payload/released/"~payloads[selected].name~"["~i~"]",0);
			}
		}
	}

	for(var i=7; i<=10; i=i+1) {
		var selected = getprop("payload/virtual/weight["~ (i) ~"]/selected");
		if ( selected != nil ) {
			if(payloads[selected].name != "none" and getprop("payload/virtual/weight["~ (i) ~"]/weight-lb") == 0) {
				#print("updating station " ~ i);
				setprop("controls/armament/station["~(i)~"]/released", FALSE);
				if (payloads[selected].type == "ir" or
						payloads[selected].type == "radar" or
						payloads[selected].type == "antirad" or
						payloads[selected].type == "beam") {
					if(armament.AIM.active[i] != nil and armament.AIM.active[i].type != payloads[selected].name) {
						#print("deleting "~i~" due to type != selected");
						armament.AIM.active[i].del();
					}
					#print('setting up pylon ' ~ i ~ ' as ' ~ payloads[selected].name);
					if(armament.AIM.new(i, payloads[selected].name, payloads[selected].brevity, payloads[selected].guidance_func) == -1 and armament.AIM.active[i].status == MISSILE_FLYING) {
						setprop("controls/armament/station["~(i+1)~"]/released", TRUE);
						setprop("payload/virtual/weight["~ (i) ~"]/selected", "none");
						setprop("payload/virtual/weight["~ (i) ~"]/weight-lb", 0);
					}
					if(armament.AIM.active[i] != nil) {
						if(i == 7 and selected == "R-60") {
							#print("r-60 at station 7");
							setprop("payload/virtual/weight[7]/weight-lb",payloads["R-60"].weight);
						}
						if(i == 8 and selected == "R-60") {
							#print("r-60 at station 8");
							setprop("payload/virtual/weight[8]/weight-lb",payloads["R-60"].weight);
						}
					}
				}
				if ( payloads[selected].type == "bomb" ) {
					setprop("payload/released/"~payloads[selected].name~"["~i~"]",0);
				}
			} elsif (payloads[selected].name == "R-60") {
				selected0 = getprop("payload/weight[0]/selected");
				selected1 = getprop("payload/weight[4]/selected");
				if ( i == 7 and selected0 != nil and ( selected0 != "R-60x2" ) ) {
					if ( getprop("payload/virtual/weight["~ (i) ~"]/weight-lb") != 0 ) {
						setprop("payload/virtual/weight["~ (i) ~"]/weight-lb", 0);
						setprop("payload/virtual/weight["~ (i) ~"]/selected", "none");
					}
					if ( armament.AIM.active[i] != nil ) {
						#print("deleting "~i~" due to pylon being none.");
						armament.AIM.active[i].del();
						setprop("payload/virtual/weight["~ (i) ~"]/weight-lb", 0);
						setprop("payload/virtual/weight["~ (i) ~"]/selected", "none");
					}
					setprop("payload/released/"~payloads[selected].name~"["~i~"]",0);
				} elsif ( i == 8 and selected1 != nil and ( selected1 != "R-60x2" ) )  {
					if ( getprop("payload/virtual/weight["~ (i) ~"]/weight-lb") != 0 ) {
						setprop("payload/virtual/weight["~ (i) ~"]/weight-lb", 0);
						setprop("payload/virtual/weight["~ (i) ~"]/selected", "none");
					}
					if ( armament.AIM.active[i] != nil ) {
						#print("deleting "~i~" due to pylon being none.");
						armament.AIM.active[i].del();
						setprop("payload/virtual/weight["~ (i) ~"]/weight-lb", 0);
						setprop("payload/virtual/weight["~ (i) ~"]/selected", "none");
					}
					setprop("payload/released/"~payloads[selected].name~"["~i~"]",0);
				}
			} elsif (payloads[selected].name == "none") {
				if ( getprop("payload/virtual/weight["~ (i) ~"]/weight-lb") != 0 ) {
					setprop("payload/virtual/weight["~ (i) ~"]/weight-lb", 0);
				}
				if ( armament.AIM.active[i] != nil ) {
					#print("deleting "~i~" due to pylon being none.");
					armament.AIM.active[i].del();
					setprop("payload/virtual/weight["~ (i) ~"]/weight-lb", 0);
				}
				setprop("payload/released/"~payloads[selected].name~"["~i~"]",0);
			}
		}
	}


	############ MISSILE ARMING LOGIC ################
	var armSelect = pylon_select();
	for ( i = 0; i <= 10; i += 1 ) {
		#print("in arming logic");
		if (i < 7) {
			var payloadName = getprop("/payload/weight[" ~ i ~ "]/selected");
		} else {
			var payloadName = getprop("/payload/virtual/weight[" ~ i ~ "]/selected");
		}
		if ( armament.AIM.active[i] != nil ) {
			if ( armSelect[0] != i and armSelect[1] != i and armament.AIM.active[i].status != MISSILE_FLYING ) {
				#print("setting pylon " ~ i ~ " to standby");
				armament.AIM.active[i].stop();
			} elsif ( armament.AIM.active[i].status != MISSILE_STANDBY and armament.AIM.active[i] != MISSILE_FLYING and payloadName == "none" ) {
				#print("setting pylon " ~ i ~ " to standby");
				armament.AIM.active[i].stop();
			} elsif ( (armSelect[0] == i or armSelect[1] == i ) and armament.AIM.active[i].status == MISSILE_STANDBY ) {
				#print("missile " ~i~ " should be searching.");
				armament.AIM.active[i].start();
			}
		}
	}

	############ JSBSIM SET MASS ##############
	var selected = nil;
	for(var i=0; i<=10; i=i+1) { # set JSBSim mass
		if (i < 7) {
			var virtual = "/";
		} else {
			var virtual = "/virtual/";
		}
		selected = getprop("payload"~virtual~"weight["~i~"]/selected");

		if (getprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~ (i) ~"]") != nil and getprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~ (i) ~"]") != payloads[selected].weight) {
			#print("setting weight of " ~ payloads[selected].weight ~ " on pylon " ~ i);
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

	settimer(update_loop, UPDATE_PERIOD);
}

########### listener for handling unjamming #########

var charge_used = [0,0,0];

var unjam = func(button) {
	#print("inside unjam");
	#print("button: " ~ button);
	#print("button value: " ~ charge_used[button]);
	if ( charge_used[button] == 0 ) {
		charge_used[button] = 1;
		setprop("/fdm/jsbsim/systems/armament/GSh-23-jammed",0);
	}
}

setlistener("controls/armament/panel/reload[0]", func { unjam(0); } );
setlistener("controls/armament/panel/reload[1]", func { unjam(1); } );
setlistener("controls/armament/panel/reload[2]", func { unjam(2); } );

###########  trigger propogation  ###########

var missile_firing_order = [[1,3,0,4],[3,1,0,4],[0,4,1,3],[4,1,3,0]];

var trigger_propogation = func() {
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
	#pylons go 3,1,2,4 left to right IRL
	#pylons go 0,1,3,4 left to right internally

	# missile preference is set by the IR/SAR switch
	# missile order is determined by the armament selector knob
	# 1: order is 1,2,3,4
	# 2: order is 2,1,3,4
	# 3: order is 3,4,1,2
	# 4: order is 4,1,2,3
	# if pylon is unpowered, skip it
	# if pylon is powered but fails, don't skip it
	
	if ( getprop("/fdm/jsbsim/systems/armament/release") != 1 ) {
		setprop("/controls/armament/rocket-trigger",0);
	} else {
	
		var knobpos = getprop("controls/armament/panel/pylon-knob");
		if ( knobpos == 0 ) {
			setprop("/controls/armament/rocket-setting",16);
			setprop("/controls/armament/rocket-trigger",1);
			bomb_release(1,"bomb");
			bomb_release(3,"bomb");
		} elsif ( knobpos == 1 ) {
			setprop("/controls/armament/rocket-setting",8);
			setprop("/controls/armament/rocket-trigger",1);
			bomb_release(0,"bomb");
			bomb_release(4,"bomb");
		} elsif ( knobpos == 2 ) {
			setprop("/controls/armament/rocket-setting",4);
			setprop("/controls/armament/rocket-trigger",1);
			bomb_release(0,"bomb");
			bomb_release(1,"bomb");
			bomb_release(2,"bomb");
			bomb_release(3,"bomb");
			return [0,3,knobpos];
		} elsif ( knobpos == 3 ) {
			bomb_release(1,"heavyrocket");
			settimer(func{
				bomb_release(3,"heavyrocket");
			},0.1);
		} elsif ( knobpos == 4 ) {
			bomb_release(0,"heavyrocket");
			settimer(func{
				bomb_release(4,"heavyrocket");
			},0.1);
		} elsif ( knobpos == 5 ) {
			var ret1 = getprop("payload/virtual/weight[7]/selected") == "R-60" ? 7 : 0;
			var ret2 = getprop("payload/virtual/weight[8]/selected") == "R-60" ? 8 : 4;		
			missile_release(ret1);
			settimer(func{
				missile_release(ret2);
			},0.1);
		} elsif ( knobpos == 6 ) {
			missile_release(1);
			settimer(func{
				missile_release(3);
			},0.1);
		} elsif ( knobpos >= 7 ) {
			# missile_firing_order
			var pylon_check = -1;
			var pylon_select = -1;
			var selected_type = 1; # 0 is IR, 2 is RGM
			var virtual = "";
			for(var i = 0; i <= 3; i = i + 1){
				# get missile pylon
				pylon_check = missile_firing_order[knobpos - 7][i];
				
				# check that the pylon is powered
				if ( getprop("/fdm/jsbsim/electric/output/pwr-to-pylons",pylon_check) < 32 ) { continue; }
				
				#propogate out for our R-60's
				if( pylon_check == 0 and getprop("payload/virtual/weight[7]/selected") == "R-60" ) { pylon_check = 7; }
				if( pylon_check == 4 and getprop("payload/virtual/weight[8]/selected") == "R-60" ) { pylon_check = 8; }	
				
				virtual = pylon_check < 7 ? "/" : "/virtual/";
				
				if ( selected_type == 1 or 
					 (selected_type != getprop(ir_sar_switch) and 
					 payloads[getprop("payload" ~ virtual ~ "weight["~pylon_check~"]/selected")].type_norm == getprop(ir_sar_switch)) ) {
					 	pylon_select = pylon_check;
					 	break;
				} elsif ( selected_type == 1 and payloads[getprop("payload" ~ virtual ~ "weight["~pylon_check~"]/selected")].type_norm != 1 ) {
					pylon_select = pylon_check;
					selected_type = payloads[getprop("payload" ~ virtual ~ "weight["~pylon_check~"]/selected")].type_norm;
				}
			}
			missile_release(pylon_select);
		}
	}
}

var heavy_release_listener = func {
	bomb_release(2,"heavy");
}

var missile_release = func(pylon) {
	if (pylon < 7) {
		var virtual = "/";
	} else {
		var virtual = "/virtual/";
	}
	var selected = getprop("payload"~virtual~"weight["~(pylon)~"]/selected");
	if(selected != "none") {
		# check power
		if ( getprop("/fdm/jsbsim/electric/output/pwr-to-pylons",pylon < 32 ) {	return;	}
		# check temprature, will begin failing at 5*C and guaranteed failure at -5*c
		if ( interp( getprop("/fdm/jsbsim/systems/armament/pylon-heating/pylon-temp",pylon), -5,0,5,1) < rand() ) { return;	}
		systems/armament/pylon-heating/pylon-temp[5]
		# trigger is pulled, a pylon is selected, the pylon has a missile that is locked on.
		if (armament.AIM.active[pylon] != nil and armament.AIM.active[pylon].status == 1 and radar_logic.selection != nil) {
			#missile locked, fire it.

			#print("firing missile: "~pylon);

			var callsign = armament.AIM.active[pylon].callsign;
			var brevity = armament.AIM.active[pylon].brevity;

			#if missile is R-27R1 or R-27T1, recalculate drop time

			if ( selected == "R-27R1" or selected == "R-27T1" ) {
				var prs_inhg = getprop("/environment/pressure-inhg");
				if ( prs_inhg > 25 ) {
					#print("pressure: " ~ math.clamp(interp(prs_inhg,33,0,25,1.5),0,4));
					#print("altitude: " ~ math.clamp(interp(radar_logic.selection.get_range(),0,0,15,1),0,1));
					armament.AIM.active[pylon].drop_time = math.clamp(interp(prs_inhg,33,0,25,1.5),0,4) * math.clamp(interp(radar_logic.selection.get_range(),0,0,15,1),0,1);
					#armament.AIM.active[pylon].drop_time = 3;
				} else {
					#print("pressure: " ~ math.clamp(interp(prs_inhg,25,1.5,5,4),0,4));
					#print("altitude: " ~ math.clamp(interp(radar_logic.selection.get_range(),0,0,15,1),0,1));
					armament.AIM.active[pylon].drop_time = math.clamp(interp(prs_inhg,25,1.5,5,4),0,4) * math.clamp(interp(radar_logic.selection.get_range(),0,0,15,1),0,1);
					#armament.AIM.active[pylon].drop_time = 3;
				}
				#print("range: " ~ radar_logic.selection.get_range());
				#print("drop time ~ " ~ math.clamp(interp(prs_inhg,33,0,25,1.5),0,4) * math.clamp(interp(radar_logic.selection.get_range(),0,0,15,1),0,1));
			}

			armament.AIM.active[pylon].release();

			setprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~pylon~"]",0);
			setprop("payload"~virtual~"weight["~(pylon)~"]/selected", "none");
			var phrase = brevity ~ " at: " ~ callsign;
			if (getprop("payload/armament/msg")) {
				defeatSpamFilter(phrase);
			} else {
				setprop("/sim/messages/atc", phrase);
			}
		} elsif ( armament.AIM.active[pylon] != nil and selected == "R-27T1" ) {
			var prs_inhg = getprop("/environment/pressure-inhg");
			if ( prs_inhg > 25 ) {
				#print("pressure: " ~ math.clamp(interp(prs_inhg,33,0,25,1.5),0,4));
				#print("altitude: " ~ math.clamp(interp(radar_logic.selection.get_range(),0,0,15,1),0,1));
				armament.AIM.active[pylon].drop_time = math.clamp(interp(prs_inhg,33,0,25,1.5),0,4);
			} else {
				#print("pressure: " ~ math.clamp(interp(prs_inhg,25,1.5,5,4),0,4));
				#print("altitude: " ~ math.clamp(interp(radar_logic.selection.get_range(),0,0,15,1),0,1));
				armament.AIM.active[pylon].drop_time = math.clamp(interp(prs_inhg,25,1.5,5,2),0,4);
			}
			var brevity = armament.AIM.active[pylon].brevity;

			armament.AIM.active[pylon].guidance = "gyro-pitch";
			armament.AIM.active[pylon].releaseAtNothing();

			setprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~pylon~"]",0);
			setprop("payload"~virtual~"weight["~(pylon)~"]/selected", "none");
			var phrase = brevity ~ " Maddog released";
			if (getprop("payload/armament/msg")) {
				defeatSpamFilter(phrase);
			} else {
				setprop("/sim/messages/atc", phrase);
			}

		} elsif ( armament.AIM.active[pylon] != nil and selected == "Kh-66" ) {
			armament.AIM.active[pylon].releaseAtNothing();

			var brevity = armament.AIM.active[pylon].brevity;

			setprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~pylon~"]",0);
			setprop("payload"~virtual~"weight["~(pylon)~"]/selected", "none");
			var phrase = brevity ~ " released:";
			if (getprop("payload/armament/msg")) {
				defeatSpamFilter(phrase);
			} else {
				setprop("/sim/messages/atc", phrase);
			}
		}
	}
}

var bomb_release = func(pylon,type="bomb") {
	if (pylon < 7) {
		var virtual = "/";
	} else {
		var virtual = "/virtual/";
	}
	var selected = getprop("payload"~virtual~"weight[" ~ ( pylon ) ~ "]/selected");
	if ( payloads[selected].type == type ) {
		#print("dropping bomb: " ~ payloads[selected].brevity ~ ": pylon " ~ pylon);
		#print("selected: " ~ selected ~ "| pylon: " ~ pylon);
		setprop("payload/released/"~selected~"["~pylon~"]",1);
		setprop("payload"~virtual~"weight[" ~ ( pylon ) ~ "]/selected", "none" );
		setprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~pylon~"]",0);
		var phrase = payloads[selected].brevity ~ " released.";
		if (getprop("payload/armament/msg")) {
			defeatSpamFilter(phrase);
		} else {
			setprop("/sim/messages/atc", phrase);
		}
		settimer(func{return_trigger(selected,pylon);},19)
	}
}

var return_trigger = func(selected, pylon) {
	setprop("payload/released/"~selected~"["~pylon~"]",0);
}
############ Impact messages #####################

var hit_count = 0;
var hit_callsign = "";
var hit_timer = 0;
var closest_distance = 200;

var hit_counter = {
	new: func(name, hit_count, hit_callsign, hit_timer, closest_distance, inc_terrain) {
		var m = {parents:[hit_counter]};
		m.name = name;
		m.hit_count = hit_count;
		m.hit_callsign = hit_callsign;
		m.hit_timer = hit_timer;
		m.closest_distance = closest_distance;
		m.inc_terrain = inc_terrain;
		return m;
	}
};

var cr_typeord = {
	"GSh-23"	:	hit_counter.new("GSh-23",0,"",0,200,FALSE),
	"S-5"		:	hit_counter.new("S-5",0,"",0,200,TRUE),
};

var inside_callsign = "";
var distance = 0;
var typeOrdName = "";

var impact_listener = func {
  var ballistic = props.globals.getNode(input.impact.getValue(), 0);
	inside_callsign = "";
	#print("inside listener");
  if (ballistic != nil and ballistic.getNode("name") != nil and ballistic.getNode("impact/type") != nil) {
      #print("woo");
		var typeNode = ballistic.getNode("impact/type");
		typeOrdName = ballistic.getNode("name").getValue();
		#var lat = ballistic.getNode("impact/latitude-deg").getValue();
		#var lon = ballistic.getNode("impact/longitude-deg").getValue();
		#var impactPos = geo.Coord.new().set_latlon(ballistic.getNode("impact/latitude-deg").getValue(), ballistic.getNode("impact/longitude-deg").getValue());
		#if (typeOrd == "GSh-23" and typeNode.getValue() != "terrain") {
		if ( cr_typeord[typeOrdName] != nil and (cr_typeord[typeOrdName].inc_terrain == TRUE or ballistic.getNode("impact/type").getValue() != "terrain") ) {
      #print("its a gun hit");
      var typeOrd = cr_typeord[typeOrdName];
			typeOrd.closest_distance = 35;
			foreach(var mp; props.globals.getNode("/ai/models").getChildren("multiplayer")){
				#print("Submodel impact - hit: " ~ typeNode.getValue());
				#var mlat = mp.getNode("position/latitude-deg").getValue();
				#var mlon = mp.getNode("position/longitude-deg").getValue();
				#var malt = mp.getNode("position/altitude-ft").getValue() * FT2M;
				#var selectionPos = geo.Coord.new().set_latlon(mlat, mlon, malt);
				# distance from ballistic impact point to mp point
				distance = geo.Coord.new().set_latlon(ballistic.getNode("impact/latitude-deg").getValue(), ballistic.getNode("impact/longitude-deg").getValue(),ballistic.getNode("impact/elevation-m").getValue()).direct_distance_to(geo.Coord.new().set_latlon(mp.getNode("position/latitude-deg").getValue(), mp.getNode("position/longitude-deg").getValue(), mp.getNode("position/altitude-ft").getValue() * FT2M));
				#print("callsign " ~ mp.getNode("callsign").getValue() ~ " distance = " ~ distance);
				if (distance < typeOrd.closest_distance) {
					typeOrd.closest_distance = distance;
					inside_callsign = mp.getNode("callsign").getValue();
				}
			}

			if ( inside_callsign != "" ) {
				#we have a successful hit
				if ( inside_callsign == typeOrd.hit_callsign ) {
					typeOrd.hit_count = typeOrd.hit_count + 1;
					#print("hit_count: " ~ hit_count);
				} else {
					typeOrd.hit_callsign = inside_callsign;
					typeOrd.hit_count = 1;
				}
				if ( typeOrd.hit_timer == 0 ) {
					typeOrd.hit_timer = 1;
					settimer(func{hitmessage(typeOrd);},1);
				}
			}
		}elsif (payloads[typeOrdName] != nil and ( payloads[typeOrdName].type == "bomb" or payloads[typeOrdName].type == "heavy" or payloads[typeOrdName].type == "heavyrocket" ))  {
      print("a bomb dropped");
      foreach(var mp; props.globals.getNode("/ai/models").getChildren("multiplayer")){
				#var mlat = mp.getNode("position/latitude-deg").getValue();
				#var mlon = mp.getNode("position/longitude-deg").getValue();
				#var malt = mp.getNode("position/altitude-ft").getValue() * FT2M;
				#var selectionPos = geo.Coord.new().set_latlon(mlat, mlon, malt);
				# distance from ballistic impact point to mp point
				distance = geo.Coord.new().set_latlon(ballistic.getNode("impact/latitude-deg").getValue(), ballistic.getNode("impact/longitude-deg").getValue(),ballistic.getNode("impact/elevation-m").getValue()).direct_distance_to(geo.Coord.new().set_latlon(mp.getNode("position/latitude-deg").getValue(), mp.getNode("position/longitude-deg").getValue(), mp.getNode("position/altitude-ft").getValue() * FT2M));
				if (distance < payloads[typeOrdName].hit_max_distance) {
					defeatSpamFilter(sprintf( typeOrdName~" exploded: %01.1f", distance) ~ " meters from: " ~ mp.getNode("callsign").getValue());
				}
			}
		}
	}
}

var hitmessage = func(typeOrd) {
	#print("inside hitmessage");
	if (typeOrd.name == "S-5" ) {
		var ordname = "S-5 rocket";
	} else {
		var ordname = typeOrd.name;
	}
	message = ordname ~ " hit: " ~ typeOrd.hit_callsign ~ ": " ~ typeOrd.hit_count ~ " hits";
	defeatSpamFilter(message);
	typeOrd.hit_callsign = "";
	typeOrd.hit_timer = 0;
	typeOrd.hit_count = 0;
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

var main_init = func {
  setprop("sim/time/elapsed-at-init-sec", getprop("sim/time/elapsed-sec"));

  setprop("/consumables/fuel/tank[11]/jettisoned", FALSE);
  setprop("/consumables/fuel/tank[12]/jettisoned", FALSE);
  setprop("/consumables/fuel/tank[13]/jettisoned", FALSE);

  # Load exterior at startup to avoid stale sim at first external view selection. ( taken from TU-154B )
  # print("Loading exterior, wait...");
  # return to cabin to next cycle
  settimer( load_interior, 0 );
  setprop("/sim/current-view/view-number", 1);
  setprop("/sim/gui/tooltips-enabled", TRUE);

  # setup property nodes for the loop
  foreach(var name; keys(input)) {
      input[name] = props.globals.getNode(input[name], 1);
  }

  screen.log.write("Welcome to MiG-21bis!", 1.0, 0.2, 0.2);
  setlistener("/fdm/jsbsim/systems/armament/release", trigger_propogation);
  setlistener("/fdm/jsbsim/systems/armament/heavy-release", heavy_release_listener);

  # setup impact listener
  setlistener("/ai/models/model-impact", impact_listener, 0, 0);

  # start the main loop
	settimer(func { update_loop() }, 0.1);
}

var load_interior = func{
    setprop("/sim/current-view/view-number", 0);
    #print("..Done!");
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
  var myCallsign = getprop("sim/multiplay/callsign");
  if (myCallsign != nil and find(myCallsign, str) != -1) {
      str = myCallsign~": "~str;
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

var interp = func(x,x0,y0,x1,y1) {
	return y0 + ( x - x0 ) * ((y1 - y0) / (x1 - x0))
}

spamLoop();
