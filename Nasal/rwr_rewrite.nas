
var rwr_database = {
    "default":                  rwr_datum.new(360,90,50 * NM2M),
    "F-14B":					rwr_datum.new(65,65,200 * NM2M),
    "F-15C":                    rwr_datum.new(65,65,150 * NM2M),
    "F-15D":                    rwr_datum.new(65,65,150 * NM2M),
    "F-16":						rwr_datum.new(60,60,100 * NM2M),
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
    "buk-m2":                   rwr_datum.new(360,90,75 * NM2M),
    "truck":                    rwr_datum.new(0,0,0),
    "missile_frigate":          rwr_datum.new(180,90,120 * NM2M),
    "frigate":                  rwr_datum.new(180,90,120 * NM2M),
    "tower":                    rwr_datum.new(0,0,0),
};

var my_heading = props.globals.getNode("/orientation/heading-deg");
var my_pitch = props.globals.getNode("/orientation/pitch-deg");
var my_roll = props.globals.getNode("/orientation/roll-deg");

# loop through all contacts
# get radar strenght into sensor
# we dont really care about the contacts, just the sensor strenght

var rwr_sensor = {
    min_bearing: 0,
    max_bearing: 0,
    max_pitch: 0,
    strength: 0,
    missile: 0,
    count:0,
    prop: "",
};

# min bearing is least wrt going clockwise
# max bearing is greatest wrt going clockwise
append(sensors,{parents:[rwr_sensor], min_bearing: -112.5, max_bearing: 22.5,  max_pitch: 20, prop: "/instrumentation/rwr/forward-left/light-enable"});
append(sensors,{parents:[rwr_sensor], min_bearing: -22.5,  max_bearing: 112.5, max_pitch: 20, prop: "/instrumentation/rwr/forward-right/light-enable"});
append(sensors,{parents:[rwr_sensor], min_bearing:  157.5, max_bearing: -67.5, max_pitch: 20, prop: "/instrumentation/rwr/rear-left/light-enable"});
append(sensors,{parents:[rwr_sensor], min_bearing:  67.5, max_bearing: -157.5, max_pitch: 20, prop: "/instrumentation/rwr/rear-right/light-enable"});

var sensor_update = func() {
    foreach (var sensor; sensors) {
        sensor.strength = 0;
    }
	var myCoord = geo.aircraft_position();
	
    foreach (var cx; armament_locking.cx_master_list) {
        # first the easy stuff
        
        #check if hidden by terrain
        if (!radar_logic.isNotBehindTerrain(cx.get_Coord())) {
            continue;
        }
        
        # check if the contacts radar is active
        if (!cx.isRadarActive()) {
            continue;
        }
        
		# set up some needed variables
		var vectorToEcho    = vector.Math.eulerToCartesian2(myCoord.course_to(cx.get_Coord()), vector.Math.getPitch(myCoord,cx.get_Coord()));
		var vectorSide      = vector.Math.eulerToCartesian3Y(my_heading.getValue(), my_pitch.getValue(), my_roll.getValue());
		var vectorEchoTop   = vector.Math.eulerToCartesian3Z(cx.get_heading(), cx.get_Pitch(), cx.get_Roll());
		var rel_pitch       = math.abs(vector.Math.angleBetweenVectors(vectorToEcho, vector.Math.projVectorOnPlane(vector.Math.eulerToCartesian3Z(my_heading.getValue(), my_pitch.getValue(), my_roll.getValue()),vectorToEcho)));
        var bearing         = get_bearing(vectorToEcho,vectorSide);
        
        var sensor_id = [];
        
        # get which sensors this would potentially be affecting.
        # we are checking both pitch, and bearing
        for (var i = 0; i < size(sensors); i = i + 1) {
            if (sensors[i].max_pitch > rel_pitch) {
                continue;
            }
            if (sensors[i].min_bearing < sensors[i].max_bearing and bearing > sensors[i].min_bearing and bearing < sensors[i].max_bearing) {
                append(sensor_id,i);
            } elsif (sensors[i].min_bearing > sensors[i].max_bearing and (bearing > sensors[i].min_bearing or bearing < sensors[i].max_bearing)) {
                append(sensor_id,i);
            }
        }
        if (size(sensor_id) == 0) {
            continue;
        }
        
        # get the tgt radar information
        if (contains(rwr_database,cx.get_model())) {
            var emit = rwr_database[cx.get_model()];
        } else {
            var emit = rwr_database["default"];
        }
        
        # check that we are in the tgt radar cone
        bearing = math.abs(geo.normdeg180(vector.Math.angleBetweenVectors(vector.Math.eulerToCartesian3X(cx.get_heading(), cx.get_Pitch(), cx.get_Roll()), vector.Math.projVectorOnPlane(vectorEchoTop,vectorToEcho))+180));
        
        if (bearing > emit.bearing) {
            continue;
        }
        
        bearing = math.abs(geo.normdeg180(vector.Math.angleBetweenVectors(vectorEchoTop, vectorToEcho))-90); #pitch
        if (bearing > emit.pitch) {
            continue;
        }
        
        # and finally, compute actual received signal strength from distance
        var distance = myCoord.direct_distance_to(cx.get_Coord());
        var sig_str = 0;
        if (distance > emit.distance) {
            continue;
        } else {
            if (distance < emit.distance / 4) {
                sig_str = 2;
            } else {
                sig_str = 1;
            }
        }
        
        for (var i = 0; i < size(sensor_id); i = i + 1){
            sensors[i].strength = sig_str;
        }
    }
}

var blinktime = systime();
var fasttime = systime();
var faststate = 0;
var blinkstate = 0;
var sensor_readout = func() {
    if (systime() - blinktime > 1) {
        blinktime = systime();
        blinkstate = (blinkstate - 1) * -1;
    }
    if (systime() - fasttime > 0.2) {
        fasttime = systime();
        faststate = (faststate - 1) * -1;
    }
    foreach (var sensor; sensors) {
        if (sensor.missile == 1) {
            if (sensor.count > 10) {
                sensor.missile = 0;
                sensor.count = 0;
            } else {
                setprop(sensor.prop,faststate);
                sensor.count = sensor.count + 1;
            }
        }
        if (sensor.missile == 0) {
            if (sensor.strength == 2) {
                setprop(sensor.prop,1);
            } elsif (sensor.strength == 1) {
                setprop(sensor.prop,blinkstate);
            } else {
                setprop(sensor.prop,0);
            }
        }
    }
}

var get_bearing = func(vectorToEcho, vectorSide) {
	#roll adjusted bearing
	
	var view2D = vector.Math.projVectorOnPlane(vector.Math.eulerToCartesian3Z(my_heading.getValue(), my_pitch.getValue(), my_roll.getValue()),vectorToEcho);
    bearing = vector.Math.angleBetweenVectors(vector.Math.eulerToCartesian3X(my_heading.getValue(), my_pitch.getValue(), my_roll.getValue()), view2D);

	#find left/right
	var leftright = vector.Math.angleBetweenVectors(vectorSide, view2D);

	if (leftright > 90 ){
		bearing = bearing * -1;
	}
	
	return bearing;
}

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
							foreach ( var cx; armament_locking.cx_master_list) {
								if ( cx.get_Callsign() == author ) {
						    		var vectorToEcho    = vector.Math.eulerToCartesian2(myCoord.course_to(cx.get_Coord()), vector.Math.getPitch(myCoord,cx.get_Coord()));
                                    var vectorSide      = vector.Math.eulerToCartesian3Y(my_heading.getValue(), my_pitch.getValue(), my_roll.getValue());
                                    var rel_pitch       = math.abs(vector.Math.angleBetweenVectors(vectorToEcho, vector.Math.projVectorOnPlane(vector.Math.eulerToCartesian3Z(my_heading.getValue(), my_pitch.getValue(), my_roll.getValue()),vectorToEcho)));
								    var bearing = get_bearing(vectorToEcho, vectorToSide);
								    
								    for (var i = 0; i < size(sensors); i = i + 1) {
                                        if (sensors[i].max_pitch > rel_pitch) {
                                            continue;
                                        }
                                        if (sensors[i].min_bearing < sensors[i].max_bearing and bearing > sensors[i].min_bearing and bearing < sensors[i].max_bearing) {
                                            sensors[i].missile = 1;
                                            sensors[i].count = 0;
                                        } elsif (sensors[i].min_bearing > sensors[i].max_bearing and (bearing > sensors[i].min_bearing or bearing < sensors[i].max_bearing)) {
                                            sensors[i].missile = 1;
                                            sensors[i].count = 0;
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
}

var readout_timer = maketimer(0.5,func(){sensor_readout();});
var update_timer = maketimer(0.1,func(){sensor_update();});

var init = setlistener("/sim/signals/fdm-initialized", func() {
    readout_timer.start();
    update_timer.start();
    setlistener("/sim/multiplay/chat-history", incoming_listener, 0, 0);
});
