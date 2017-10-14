# RWR
# seek to accurately emulate the RWR and allow it to be flexible/expandable.

# settings
var MAX_PITCH = 20;

var radiation_sources = {};

var my_heading = props.globals.getNode("/orientation/heading-deg");
var my_pitch = props.globals.getNode("/orientation/pitch-deg");
var my_roll = props.globals.getNode("/orientation/roll-deg");
 
var rcs_loop = func() {
	foreach (var mp; props.globals.getNode("/ai/models").getChildren("multiplayer")) {
		var cs = mp.getNode("callsign").getValue();
		var match = 0;
		foreach ( var source; keys(radiation_sources)) {
			if ( source == cs ) {
				radiation_sources[cs].update();
				match = 1
			} 
		}
		if ( match == 0 ) {
			radiation_sources[cs] = radiation_source.new(mp);
			radiation_sources[cs].update();
		}
	}
	settimer(func(){rcs_loop();},0.3);
}


# rwr strengths:
# 0 - off - light is off
# 1 - detected but far - blink slowly
# 2 - close/aiming - solid on
# 3 - missile fired - blink quickly
var rwr_sensor = {
	new: func( light_enable_prop, signal_strength_prop, lbound, hbound ) {
		var m = {parents:[rwr_sensor]};
		m.light_enable_prop = light_enable_prop;
		m.signal_strength_prop = signal_strength_prop;
		m.signal_strength = 0;
		m.light_enable = 0;
		m.blink_rate = 0;
		m.blink_rate_low = 1.5;
		m.blink_rate_high = 0.1;
		m.serviceable = 1;
		m.update_rate = 0.6;
		m.lbound = lbound;
		m.hbound = hbound;
		m.missile_override = 0;
		m.sources = {};
		return m;
	},
	update: func() {
		var temp_str = 0;
		#print("in update func for " ~ me.light_enable_prop);
		if ( size(radiation_sources) > 0 ) {
			foreach(var source; keys(radiation_sources)) {
				forindex(var i; me.lbound){
					if ( radiation_sources[source].bearing > me.lbound[i] and radiation_sources[source].bearing < me.hbound[i] ) {
						#print("source found");
						#print("launch state: " ~ radiation_sources[source].msl_lnch);
						#print("launch time:  " ~ radiation_sources[source].msl_time);
						if ( radiation_sources[source].msl_lnch == 1 ) {
								#print("time since launch: " ~ systime() - radiation_sources[source].msl_time);
								if ( systime() - radiation_sources[source].msl_time < 10 ) {
									#print("setting override");
									temp_str = 3;
									me.missile_override = 1;
								} else {
									#print("missile launch is over");
									radiation_sources[source].missile_launch_complete();
									me.missile_override = 0;
								}
						} elsif ( radiation_sources[source].sig_str > temp_str ) {
							#print("setting strength normally");
							me.missile_override = 0;
							temp_str = radiation_sources[source].sig_str;
						}
					}
				}
			}
		}
		#print("strength: " ~ temp_str);
		me.set_strength(temp_str);
		settimer(func(){me.update();},me.update_rate);
	},

	set_strength: func(strength) {
		if ( me.missile_override == 1 ) {
			strength = 3;
		}
		if ( strength != me.signal_strength) {
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
			me._update_props();
		}
	},
	_blink: func() {
		if ( me.blink_rate != 0 ) {
			me.light_enable = me.light_enable * -1 + 1; #flip the light_enable
			settimer(func(){me._blink();},me.blink_rate);
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
						#print("author: |" ~ author ~ "|");
						if ( author != nil ) {
							foreach ( var source; keys(radiation_sources)) {
								if ( source == author ) {
									radiation_sources[author].missile_launch();
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
    "F-14B":					rwr_datum.new(65,65,200 * NM2M),
    "F-15C":                    rwr_datum.new(65,65,150 * NM2M),
    "F-15D":                    rwr_datum.new(65,65,150 * NM2M),
    "JA37-Viggen":              rwr_datum.new(70,70,150 * NM2M),
    "AJ37-Viggen":              rwr_datum.new(70,70,150 * NM2M),
    "AJS37-Viggen":             rwr_datum.new(70,70,150 * NM2M),
    "JA37Di-Viggen":            rwr_datum.new(70,70,150 * NM2M),
    "m2000-5":                  rwr_datum.new(70,70,200 * NM2M),
    "m2000-5B":                 rwr_datum.new(70,70,200 * NM2M),
    "707":                      rwr_datum.new(180,90,75 * NM2M),
    "707-TT":                   rwr_datum.new(180,90,75 * NM2M),
    "EC-137D":                  rwr_datum.new(180,90,400 * NM2M),
    "B-1B":                     rwr_datum.new(90,90,25 * NM2M),
    "Blackbird-SR71A":          rwr_datum.new(0,0,0),
    "Blackbird-SR71B":          rwr_datum.new(0,0,0),
    "Blackbird-SR71A-BigTail":  rwr_datum.new(0,0,0),
    "ch53e":                    rwr_datum.new(0,0,0),
    "MiG-21bis":                rwr_datum.new(35,35,75 * NM2M),
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

var radiation_source = {
	# source is props.globals.getNode pointing to the base mp prop
	new: func(source) {
		var m = {parents:[radiation_source]};
		#print("creating new source");
		m.source =      source;
		m.callsign =    source.getNode("callsign");
        m.valid =       source.getNode("valid");
        m.lat =         source.getNode("position/latitude-deg");
        m.lon =         source.getNode("position/longitude-deg");
        m.alt =         source.getNode("position/altitude-ft");
		m.heading =     source.getNode("orientation/true-heading-deg");
		m.pitch =       source.getNode("orientation/pitch-deg");
		m.roll =        source.getNode("orientation/roll-deg");
		m.sig_str =     0;
		m.bearing =     0;
		m.distance =    0;
		m.msl_lnch =    0;
		m.msl_time =    0;
		m.geo =         geo.Coord.new().set_latlon(m.lat.getValue(),m.lon.getValue(),m.alt.getValue() * FT2M);
		m.model =       remove_suffix(remove_suffix(split(".", split("/", source.getNode("sim/model/path").getValue())[-1])[0], "-model"), "-anim");
		
		if (contains(rwr_database, m.model)) {
			m.rad_data = rwr_database[m.model];
		} else {
			m.rad_data = rwr_database["default"];
		}
		
		m.vectorToEcho =  {};
		m.vectorSide =    {};
		m.vectorEchoTop = {};
		
		return m;
	},
	update: func() {
		if ( me.valid.getValue() == 1 ) {
			var myCoord = geo.aircraft_position();
			me.geo.set_latlon(me.lat.getValue(),me.lon.getValue(),me.alt.getValue() * FT2M);
			
			# only precalc vectors that are used more than once
			me.vectorToEcho   = vector.Math.eulerToCartesian2(myCoord.course_to(me.geo), vector.Math.getPitch(myCoord,me.geo));
			me.vectorSide = vector.Math.eulerToCartesian3Y(my_heading.getValue(), my_pitch.getValue(), my_roll.getValue());
			me.vectorEchoTop = vector.Math.eulerToCartesian3Z(me.heading.getValue(), me.pitch.getValue(), me.roll.getValue());

			me.check_distance(myCoord);
			if ( me.sig_str != 0 ) {
			#	print("passed distance");
				me.check_terrain();
			}
			if ( me.sig_str != 0 ) {
			#	print("passed terrain");
				me.check_rel_pitch(myCoord);
			}
			if ( me.sig_str != 0 ) {
			#	print("passed pitch");
				me.check_emit();
			}
			if ( me.sig_str != 0 ) {
				#print("passed emit");
				me.get_bearing(myCoord);
			}
			
			#print("sig_str for " ~ me.callsign.getValue() ~ " is " ~ me.sig_str);
		}
	},
	
	check_distance: func(myCoord) {
		me.distance = myCoord.direct_distance_to(me.geo);
		if ( me.distance > me.rad_data.distance ) {
			me.sig_str = 0;
		} else {
			if ( me.distance < me.rad_data.distance / 4 ) {
				me.sig_str = 2;
			} else {
				me.sig_str = 1;
			}
		}
	},
	
	check_terrain: func() {
		if ( radar_logic.isNotBehindTerrain(me.geo) == 0 ) {
			me.sig_str = 0;
		}
	},
	
	check_rel_pitch: func() {
		# thank you Leto :)
	    #var vectorToBall = vector.Math.eulerToCartesian2(myCoord.course_to(me.geo), vector.Math.getPitch(myCoord,me.geo));
		#var vectorMyTop  = vector.Math.eulerToCartesian3Z(my_heading.getValue(), my_pitch.getValue(), my_roll.getValue());
		#var view2D         = vector.Math.projVectorOnPlane(vectorMyTop,vectorToBall);
		#me.rel_pitch = vector.Math.angleBetweenVectors(vectorToBall, view2D);
	    
	    # the following line is a condensed version of the above commented out code

	    me.rel_pitch = vector.Math.angleBetweenVectors(me.vectorToEcho, vector.Math.projVectorOnPlane(vector.Math.eulerToCartesian3Z(my_heading.getValue(), my_pitch.getValue(), my_roll.getValue()),me.vectorToEcho));
	    
	    #print("rel_pitch = " ~ me.rel_pitch);

	    if ( me.rel_pitch > MAX_PITCH ) {
	    	me.sig_str = 0;
	    }
	},
	
	check_emit: func() {
		#var vectorEchoNose = vector.Math.eulerToCartesian3X(echoHeading, echoPitch, echoRoll);
		#var vectorEchoTop  = vector.Math.eulerToCartesian3Z(echoHeading, echoPitch, echoRoll);
		#var view2D         = vector.Math.projVectorOnPlane(me.vectorEchoTop,me.vectorToEcho);
		#var angleToNose    = math.abs(geo.normdeg180(vector.Math.angleBetweenVectors(vectorEchoNose, view2D)+180));
		
		#the following line is a condensed version of the above commented out code
		var angle = math.abs(geo.normdeg180(vector.Math.angleBetweenVectors(vector.Math.eulerToCartesian3X(me.heading.getValue(), me.pitch.getValue(), me.roll.getValue()), vector.Math.projVectorOnPlane(me.vectorEchoTop,me.vectorToEcho))+180));
		#print("bearing from target: " ~ angle);

		if ( angle > me.rad_data.bearing ) { # bearing
	    	me.sig_str = 0;
	    	return;
	    }
	
	    angle = math.abs(geo.normdeg180(vector.Math.angleBetweenVectors(me.vectorEchoTop, me.vectorToEcho))-90); #pitch
	
	    #print("pitch from target: " ~ angle);

	    if ( angle > me.rad_data.pitch ) {
	    	me.sig_str = 0;
	    }
	},
	
	get_bearing: func() {
		#roll adjusted bearing
		
		var view2D = vector.Math.projVectorOnPlane(vector.Math.eulerToCartesian3Z(my_heading.getValue(), my_pitch.getValue(), my_roll.getValue()),me.vectorToEcho);
		me.bearing = vector.Math.angleBetweenVectors(vector.Math.eulerToCartesian3X(my_heading.getValue(), my_pitch.getValue(), my_roll.getValue()), view2D);

		#find left/right
		var leftright = vector.Math.angleBetweenVectors(me.vectorSide, view2D);

		if (leftright > 90 ){
			me.bearing = me.bearing * -1;
		}

	    #condensed from the above commented out code
	    #me.bearing = vector.Math.angleBetweenVectors(me.vectorToEcho,vector.Math.projVectorOnPlane(vector.Math.eulerToCartesian3X(my_heading.getValue(), my_pitch.getValue(), my_roll.getValue()),me.vectorSide))-90;
	    #print("final bearing: " ~ me.bearing);
	},

	missile_launch: func() {
		me.msl_lnch = 1;
		me.msl_time = systime();
	},
	missile_launch_complete: func() {
		me.msl_lnch = 0;
	},
};
	
		

var remove_suffix = func(s, x) {
    var len = size(x);
    if (substr(s, -len) == x)
        return substr(s, 0, size(s) - len);
    return s;
}

# set up sensors

var sensor_array = {};

sensor_array[0] = rwr_sensor.new("/instrumentation/rwr/forward-left/light-enable","/instrumentation/rwr/forward-left/signal-strength",[-112.5],[22.5]);
sensor_array[0].update();
sensor_array[1] = rwr_sensor.new("/instrumentation/rwr/forward-right/light-enable","/instrumentation/rwr/forward-right/signal-strength",[-22.5],[112.5]);
sensor_array[1].update();
sensor_array[2] = rwr_sensor.new("/instrumentation/rwr/rear-left/light-enable","/instrumentation/rwr/rear-left/signal-strength",[-180,157.5],[-67.5,180]);
sensor_array[2].update();
sensor_array[3] = rwr_sensor.new("/instrumentation/rwr/rear-right/light-enable","/instrumentation/rwr/rear-right/signal-strength",[67.5,-180],[180,-157.5]);
sensor_array[3].update();


setlistener("/sim/multiplay/chat-history", incoming_listener, 0, 0);
rcs_loop();