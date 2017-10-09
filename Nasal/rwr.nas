# RWR
# seek to accurately emulate the RWR and allow it to be flexible/expandable.

# settings
var MAX_PITCH = 20;

var sensor_info = {};
var sensor_save = {};

var rcs_loop = func() {
	var myCoord = geo.aircraft_position();
	sensor_save = [0,0,0,0];
	foreach (var mp; props.globals.getNode("/ai/models").getChildren("multiplayer")) {
		var model = mp.getNode("model-shorter");
		if ( model != nil ) {
			#print('boom');
			model = model.getValue();
			var loc = geo.Coord.new().set_latlon(mp.getNode("position/latitude-deg").getValue(),mp.getNode("position/longitude-deg").getValue(),mp.getNode("position/altitude-ft").getValue() * FT2M);
			sensor_info = rwr_detect(myCoord, loc, mp.getNode("orientation/true-heading-deg").getValue(), mp.getNode("orientation/pitch-deg").getValue(), mp.getNode("orientation/roll-deg").getValue(), model);
			if ( sensor_info != nil ) {
				if ( sensor_save[sensor_info[0]] < sensor_info[1] ) {
					sensor_save[sensor_info[0]] = sensor_info[1];
				}
			}
		}
	}
	for ( var i = 0; i < 4; i = i + 1 ) {
		sensor_array[i].set_strength(sensor_save[i]);
	}
	settimer(func(){rcs_loop();},0.4);
}

var rwr_detect = func(myCoord,echoCoord,echoHeading,echoPitch,echoRoll,echoModel){

	# get the datum

	if (contains(rwr_database, echoModel)) {
		var radiation_datum = rwr_database[echoModel];
	} else {
		var radiation_datum = rwr_database["default"];
	}

    # is it close enough

    var distance_to_source = myCoord.direct_distance_to(echoCoord); # in meters
    if (distance_to_source > radiation_datum.distance) {
    	return nil;
    } else {
    	if ( distance_to_source < radiation_datum.distance / 4 ) {
    		var sig_strength = 2;
    	} else {
    		var sig_strength = 1;
    	}
    }


    # is it behind terrain

	if ( radar_logic.isNotBehindTerrain(echoCoord) == 0 ) {
		return nil;
	}

    var vectorToEcho   = vector.Math.eulerToCartesian2(myCoord.course_to(echoCoord), vector.Math.getPitch(myCoord,echoCoord));

    # first calculate relative pitch angle to see if the rwr can see the radiation source

    var vectorSide = vector.Math.eulerToCartesian3Y(getprop("/orientation/heading-deg"), getprop("/orientation/pitch-deg"), getprop("/orientation/roll-deg"));
    var vectorTop = vector.Math.eulerToCartesian3Z(getprop("/orientation/heading-deg"), getprop("/orientation/pitch-deg"), getprop("/orientation/roll-deg"));
    var view2Dpitch = vector.Math.projVectorOnPlane(vectorTop,vectorSide);
    var relative_pitch = math.abs(vector.Math.angleBetweenVectors(vectorToEcho,view2Dpitch)-90);

    if ( relative_pitch > MAX_PITCH ) {
    	return nil;
    }
    
    # check if we are in the radar scope of the radiation source

	var vectorEchoNose = vector.Math.eulerToCartesian3X(echoHeading, echoPitch, echoRoll);
	var vectorEchoTop  = vector.Math.eulerToCartesian3Z(echoHeading, echoPitch, echoRoll);
	var view2D         = vector.Math.projVectorOnPlane(vectorEchoTop,vectorToEcho);
	var angleToNose    = math.abs(geo.normdeg180(vector.Math.angleBetweenVectors(vectorEchoNose, view2D)+180)); #bearing

	if ( angleToNose > radiation_datum.bearing ) {
    	return nil;
    }

    var angleToBelly   = math.abs(geo.normdeg180(vector.Math.angleBetweenVectors(vectorEchoTop, vectorToEcho))-90); #pitch

    if ( angleToBelly > radiation_datum.pitch ) {
    	return nil;
    }

    # it passed, so calculate angle to radiation source

    var vectorNose = vector.Math.eulerToCartesian3X(getprop("/orientation/heading-deg"), getprop("/orientation/pitch-deg"), getprop("/orientation/roll-deg"));
	var view2Droll = vector.Math.projVectorOnPlane(vectorNose,vectorSide);
    var relative_bearing = vector.Math.angleBetweenVectors(vectorToEcho,view2Droll)-90;

    #print("relative_bearing: " ~ relative_bearing);

    if ( relative_bearing > -112.5 and relative_bearing < 22.5 ) { 
   		#front left sensor - 0
   		return [0,sig_strength];
    } elsif ( relative_bearing < 112.5 and relative_bearing > -22.5 ) {
    	#front right sensor - 1
    	return [1,sig_strength];
    } elsif ( relative_bearing > 112.5 or relative_bearing < 157.5 ) {
    	#rear right sensor - 3
    	return [3,sig_strength];
    } else {
    	#rear left sensor - 2
    	return [2,sig_strength];
    }
}

# rwr strengths:
# 0 - off - light is off
# 1 - detected but far - blink slowly
# 2 - close/aiming - solid on
# 3 - missile fired - blink quickly
var rwr_sensor = {
	new: func(	light_enable_prop, 
				signal_strength_prop, 
				signal_strength = 0, 
				light_enable = 0, 
				blink_rate = 0, 
				blink_rate_low=1.5, 
				blink_rate_high = 0.25, 
				serviceable = 1, 
				missile_override = 0,
				missile_detect_time = 0) {
		var m = {parents:[rwr_sensor]};
		m.light_enable_prop = light_enable_prop;
		m.signal_strength_prop = signal_strength_prop;
		m.signal_strength = signal_strength;
		m.light_enable = light_enable;
		m.blink_rate = blink_rate;
		m.blink_rate_low = blink_rate_low;
		m.blink_rate_high = blink_rate_high;
		m.serviceable = serviceable;
		m.missile_override = missile_override;
		m.missile_detect_time = missile_detect_time;
		return m;
	},
	set_strength: func(strength) {
		if ( me.missile_override == 1 and me.signal_strength != 3 ) {
			me.blink_rate = me.blink_rate_high;
			me._blink();
		} elsif ( strength != me.signal_strength) {
			me.signal_strength = strength;

			if ( me.signal_strength == 0 ) {
				me.light_enable = 0;
				me.blink_rate = 0;
			} elsif ( me.signal_strength == 1 ) {
				me.blink_rate = me.blink_rate_low;
				me._blink();
			} elsif ( me.signal_strength == 2 ) {
				me.light_enable = 1;
				me.blink_rate = 0;
			} elsif ( me.signal_strength == 3 ) {
				me.blink_rate = me.blink_rate_high;
				me._blink();
			}
		}
	},
	missile_detected: func() {
		if ( me.missile_override == 0 ) {
			me.missile_override == 1;
			me.set_strength(3);
			me.missile_detect_time = systime();
			me._missile_detect_off();
		}
	},
	_missile_detect_off: func() {
		if ( me.missile_override == 1 and systime() - me.missile_detect_time > 10 ) {
			me.missile_override = 0;
		} elsif ( me.missile_override == 1 ) {
			settimer(func(){me._missile_detect_off();},3);
		}
	},
	_blink: func() {
		if ( me.blink_rate != 0 ) {
			me.light_enable = me.light_enable * -1 + 1; #flip the light_enable
			settimer(func(){me.blink();},me.blink_rate);
		}
		me._update_props();
	},
	_update_props: func() {
		props.globals.getNode(me.light_enable_prop).setValue(me.light_enable);
		props.globals.getNode(me.signal_strength_prop).setValue(me.signal_strength);
	},
};

var incoming_listener = func {
	var history = getprop("/sim/multiplay/chat-history");
	var hist_vector = split("\n", history);
	if (size(hist_vector) > 0) {
		var last = hist_vector[size(hist_vector)-1];
		var last_vector = split(":", last);
		var author = last_vector[0];
		var callsign = getprop("sim/multiplay/callsign");
		if (size(last_vector) > 1 and author != callsign) {
			# not myself
			#print("not me");
			var m2000 = 0;
			if (find(" at " ~ callsign ~ ". Release ", last_vector[1]) != -1) {
			# a m2000 is firing at us
				m2000 = 1;
			}
			if (last_vector[1] == " FOX2 at" or last_vector[1] == " Fox 1 at" or last_vector[1] == " Fox 2 at" or last_vector[1] == " Fox 3 at"
					or last_vector[1] == " Greyhound at" or last_vector[1] == " Bombs away at" or last_vector[1] == " Bruiser at" or last_vector[1] == " Rifle at" or last_vector[1] == " Bird away at"
					or last_vector[1] == " aim7 at" or last_vector[1] == " aim9 at"
					or last_vector[1] == " aim120 at"
					or m2000 == 1) {
				# air2air being fired
				if (size(last_vector) > 2 or m2000 == 1) {
					#print("Missile launch detected at"~last_vector[2]~" from "~author);
					if (m2000 == 1 or last_vector[2] == " "~callsign) {
						# its being fired at me
						#print("Incoming!");
						var enemy = damage.getCallsign(author);
						if (enemy != nil) {
							#print("enemy identified");
							foreach (var mp; props.globals.getNode("/ai/models").getChildren("multiplayer")) {
								if ( mp.getNode("callsign").getValue == enemy and mp.getNode("valid").getValue == 1 ) {

									var myCoord = geo.aircraft_pos();
									var echoCoord = geo.Coord.new().set_latlon(mp.getNode("position/latitude-deg").getValue(),mp.getNode("position/longitude-deg").getValue(),mp.getNode("position/altitude-ft").getValue() * FT2M);

									#var vectorToEcho   = vector.Math.eulerToCartesian2(myCoord.course_to(echoCoord), vector.Math.getPitch(myCoord,echoCoord));
								    #var vectorSide = vector.Math.eulerToCartesian3Y(getprop("/orientation/heading-deg"), getprop("/orientation/pitch-deg"), getprop("/orientation/roll-deg"));
									#var vectorNose = vector.Math.eulerToCartesian3X(getprop("/orientation/heading-deg"), getprop("/orientation/pitch-deg"), getprop("/orientation/roll-deg"));
									#var view2Droll = vector.Math.projVectorOnPlane(vectorNose,vectorSide);
									#var relative_bearing = vector.Math.angleBetweenVectors(vectorToEcho,view2Droll)-90;

									#the following line is a condensation of the above commented out code

									var relative_bearing = vector.Math.angleBetweenVectors(vector.Math.eulerToCartesian2(myCoord.course_to(echoCoord), vector.Math.getPitch(myCoord,echoCoord)),vector.Math.projVectorOnPlane(vector.Math.eulerToCartesian3X(getprop("/orientation/heading-deg"), getprop("/orientation/pitch-deg"), getprop("/orientation/roll-deg")),vector.Math.eulerToCartesian3Y(getprop("/orientation/heading-deg"), getprop("/orientation/pitch-deg"), getprop("/orientation/roll-deg"))))-90;
									if ( relative_bearing > -112.5 and relative_bearing < 22.5 ) { 
										#front left sensor - 0
										sensor_array[0].missile_detected();
									} elsif ( relative_bearing < 112.5 and relative_bearing > -22.5 ) {
										#front right sensor - 1
										sensor_array[1].missile_detected();
									} elsif ( relative_bearing > 112.5 or relative_bearing < 157.5 ) {
										#rear right sensor - 3
										sensor_array[3].missile_detected();
									} else {
										#rear left sensor - 2
										sensor_array[2].missile_detected();
									}
								}
							}
						}
					}
				}
			}
		}
	}
}
 

var rwr_datum = {
	new: func(bearing, pitch, distance) {
		var m = {parents:[rwr_datum]};
		m.bearing = bearing;
		m.pitch = pitch;
		m.distance = distance;
		return m;
	}
};


var rwr_database = {
    "default":                  rwr_datum.new(360,90,50 * NM2M),
    "F-14B":					rwr_datum.new(60,60,200 * NM2M),
    "F-15C":                    rwr_datum.new(60,60,150 * NM2M),
    "F-15D":                    rwr_datum.new(60,60,150 * NM2M),
    "JA37-Viggen":              rwr_datum.new(65,65,150 * NM2M),
    "AJ37-Viggen":              rwr_datum.new(65,65,150 * NM2M),
    "AJS37-Viggen":             rwr_datum.new(65,65,150 * NM2M),
    "JA37Di-Viggen":            rwr_datum.new(65,65,150 * NM2M),
    "m2000-5":                  rwr_datum.new(65,65,200 * NM2M),
    "m2000-5B":                 rwr_datum.new(65,65,200 * NM2M),
    "707":                      rwr_datum.new(180,90,75 * NM2M),
    "707-TT":                   rwr_datum.new(180,90,75 * NM2M),
    "EC-137D":                  rwr_datum.new(180,90,400 * NM2M),
    "B-1B":                     rwr_datum.new(90,90,25 * NM2M),
    "Blackbird-SR71A":          rwr_datum.new(0,0,0),
    "Blackbird-SR71B":          rwr_datum.new(0,0,0),
    "Blackbird-SR71A-BigTail":  rwr_datum.new(0,0,0),
    "ch53e":                    rwr_datum.new(0,0,0),
    "MiG-21bis":                rwr_datum.new(180,90,75 * NM2M),
    "MQ-9":                     rwr_datum.new(0,0,0),
    "KC-137R":                  rwr_datum.new(0,0,0),
    "KC-137R-RT":               rwr_datum.new(0,0,0),
    "A-10":                     rwr_datum.new(0,0,0),
    "KC-10A":                   rwr_datum.new(0,0,0),
    "Typhoon":                  rwr_datum.new(70,70,200 * NM2M),
    "C-137R":                   rwr_datum.new(0,0,0),
    "RC-137R":                  rwr_datum.new(180,90,400 * NM2M),
    "EC-137R":                  rwr_datum.new(180,90,400 * NM2M),
    "c130":                     rwr_datum.new(0,0,0),
    "SH-60J":                   rwr_datum.new(0,0,0),
    "UH-60J":                   rwr_datum.new(0,0,0),
    "uh1":                      rwr_datum.new(0,0,0),
    "212-TwinHuey":             rwr_datum.new(0,0,0),
    "412-Griffin":              rwr_datum.new(0,0,0),
    "QF-4E":                    rwr_datum.new(70,70,100 * NM2M),
    "depot":                    rwr_datum.new(0,0,0),
    "buk-m2":                   rwr_datum.new(180,90,75 * NM2M),
    "truck":                    rwr_datum.new(0,0,0),
    "missile_frigate":          rwr_datum.new(180,90,120 * NM2M),
    "frigate":                  rwr_datum.new(180,90,120 * NM2M),
    "tower":                    rwr_datum.new(0,0,0),
};

# set up sensors

var sensor_array = {};

sensor_array[0]  = rwr_sensor.new("/instrumentation/rwr/forward-left/light-enable","/instrumentation/rwr/forward-left/signal-strength");
sensor_array[1] = rwr_sensor.new("/instrumentation/rwr/forward-right/light-enable","/instrumentation/rwr/forward-right/signal-strength");
sensor_array[2]  = rwr_sensor.new("/instrumentation/rwr/rear-left/light-enable","/instrumentation/rwr/rear-left/signal-strength");
sensor_array[3]  = rwr_sensor.new("/instrumentation/rwr/rear-right/light-enable","/instrumentation/rwr/rear-right/signal-strength");


setlistener("/sim/multiplay/chat-history", incoming_listener, 0, 0);
rcs_loop();