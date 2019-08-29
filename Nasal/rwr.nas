
var my_heading = props.globals.getNode("/orientation/heading-deg");
var my_pitch = props.globals.getNode("/orientation/pitch-deg");
var my_roll = props.globals.getNode("/orientation/roll-deg");

# loop through all contacts
# get radar strenght into sensor
# we dont really care about the contacts, just the sensor strength

var rwr_sensor = {
    min_bearing: 0,
    max_bearing: 0,
    max_pitch: 0,
    strength: 0,
    missile: 0,
    prop: "",
};

# min bearing is least wrt going clockwise
# max bearing is greatest wrt going clockwise
var sensors = [];
append(sensors,{parents:[rwr_sensor], min_bearing: -112.5, max_bearing: 22.5,  max_pitch: 45, prop: "/instrumentation/rwr/forward-left/light-enable"});
append(sensors,{parents:[rwr_sensor], min_bearing: -22.5,  max_bearing: 112.5, max_pitch: 45, prop: "/instrumentation/rwr/forward-right/light-enable"});
append(sensors,{parents:[rwr_sensor], min_bearing:  157.5, max_bearing: -67.5, max_pitch: 45, prop: "/instrumentation/rwr/rear-left/light-enable"});
append(sensors,{parents:[rwr_sensor], min_bearing:  67.5, max_bearing: -157.5, max_pitch: 45, prop: "/instrumentation/rwr/rear-right/light-enable"});

var sensor_update = func() {
    foreach (var sensor; sensors) {
        sensor.strength = 0;
    }
    var myCoord = geo.aircraft_position();
    
    foreach (var cx; mp_db.cx_master_list) {
        # first the easy stuff
        #print("for " ~ cx.get_Callsign());
        # check if the contacts radar is active
        if (!cx.isRadarActive()) {
            continue;
        }
        # check if we should be lit up
        var distance = myCoord.direct_distance_to(cx.get_Coord());
        var expanded = expand_string(cx.rwr_pattern, distance / 15);
        if (cx._rwr_index >= size(expanded)) {
            cx._rwr_index = 0;
        } else {
            cx._rwr_index = cx._rwr_index + 1;
        }
        if (substr(expanded, cx._rwr_index, 1) == "n") {
            continue;
        }
        #check if hidden by terrain
        if (!radar_logic.RadarLogic.isNotBehindTerrain(cx.get_Coord())) {
            continue;
        }
        #print("terrain passed");
        
        #print('radar activee passed with ' ~ cx.isRadarActive());
        
        # set up some needed variables
        var vectorToEcho    = vector.Math.eulerToCartesian2(myCoord.course_to(cx.get_Coord()), vector.Math.getPitch(myCoord,cx.get_Coord()));
        var vectorSide      = vector.Math.eulerToCartesian3Y(my_heading.getValue(), my_pitch.getValue(), my_roll.getValue());
        var vectorEchoTop   = vector.Math.eulerToCartesian3Z(cx.get_heading(), cx.get_Pitch(), cx.get_Roll());
        var rel_pitch       = math.abs(vector.Math.angleBetweenVectors(vectorToEcho, vector.Math.projVectorOnPlane(vector.Math.eulerToCartesian3Z(my_heading.getValue(), my_pitch.getValue(), my_roll.getValue()),vectorToEcho)));
        var bearing         = get_bearing(vectorToEcho,vectorSide);
        
        var sensor_id = [];
        
        # get which sensors this would potentially be affecting.
        # we are checking both pitch, and bearing
        #print('bearing ' ~ bearing);
        #print('rel_pitch ' ~ rel_pitch);
        for (var i = 0; i < size(sensors); i = i + 1) {
            if (sensors[i].max_pitch < rel_pitch) {
                continue;
            }
            if (sensors[i].min_bearing < sensors[i].max_bearing and bearing > sensors[i].min_bearing and bearing < sensors[i].max_bearing) {
                append(sensor_id,i);
                #print('appendo 1');
            } elsif (sensors[i].min_bearing > sensors[i].max_bearing and (bearing > sensors[i].min_bearing or bearing < sensors[i].max_bearing)) {
                append(sensor_id,i);
                #print('appendo 2');
            }
        }
        if (size(sensor_id) == 0) {
            continue;
        }
        #print('valid sensors');
        
        # check that we are in the tgt radar cone
        bearing = math.abs(geo.normdeg180(vector.Math.angleBetweenVectors(vector.Math.eulerToCartesian3X(cx.get_heading(), cx.get_Pitch(), cx.get_Roll()), vector.Math.projVectorOnPlane(vectorEchoTop,vectorToEcho))+180));
        
        if (bearing > cx.info.rwr_bearing) {
            continue;
        }

        bearing = math.abs(geo.normdeg180(vector.Math.angleBetweenVectors(vectorEchoTop, vectorToEcho))-90); #pitch
        if (bearing > cx.info.rwr_pitch) {
            continue;
        }

        #print('in radar cone pitch');
        
        # and finally, compute actual received signal strength from distance
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
        #print('sig_str ' ~ sig_str);
        foreach (var id; sensor_id){
            sensors[id].strength = sig_str;
        }
    }
}

var blinktime = systime();
#var fasttime = systime();
var faststate = 0;
var blinkstate = 0;
var sensor_readout = func() {
    if (systime() - blinktime > 1) {
        blinktime = systime();
        blinkstate = (blinkstate - 1) * -1;
    }
    faststate = (faststate - 1) * -1;
    foreach (var sensor; sensors) {
        if (sensor.missile > 0) {
            #print("missile launched in sensor_readout");
            if (systime() - sensor.missile > 8) { # the '8' is how long in seconds it should blink for
                #print("resetting missile launch");
                sensor.missile = 0;
            } else {
                setprop(sensor.prop,faststate);
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
                            foreach ( var cx; arm_locking.cx_master_list) {
                                if ( cx.get_Callsign() == author ) {
                                    var myCoord         = geo.aircraft_position();
                                    var vectorToEcho    = vector.Math.eulerToCartesian2(myCoord.course_to(cx.get_Coord()), vector.Math.getPitch(myCoord,cx.get_Coord()));
                                    var vectorSide      = vector.Math.eulerToCartesian3Y(my_heading.getValue(), my_pitch.getValue(), my_roll.getValue());
                                    var rel_pitch       = math.abs(vector.Math.angleBetweenVectors(vectorToEcho, vector.Math.projVectorOnPlane(vector.Math.eulerToCartesian3Z(my_heading.getValue(), my_pitch.getValue(), my_roll.getValue()),vectorToEcho)));
                                    var bearing         = get_bearing(vectorToEcho, vectorSide);
                                    
                                    for (var i = 0; i < size(sensors); i = i + 1) {
                                        if (sensors[i].max_pitch < rel_pitch) {
                                            continue;
                                        }
                                        if (sensors[i].min_bearing < sensors[i].max_bearing and bearing > sensors[i].min_bearing and bearing < sensors[i].max_bearing) {
                                            sensors[i].missile = systime();
                                            #print('set sensor ' ~ i);
                                        } elsif (sensors[i].min_bearing > sensors[i].max_bearing and (bearing > sensors[i].min_bearing or bearing < sensors[i].max_bearing)) {
                                            sensors[i].missile = systime();
                                            #print('set sensor ' ~ i);
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

var expand_string = func(str, amt) {
    var metadata = [];
    var count = 0;
    var cc = str_arr[0];
    var new_str = "";
    for (var i = 0; i < size(str); i = i + 1) {
        if ( cc == substr(str, i, 1) ) {
            count = count + 1;
        } else {
            append(metadata, [cc, count]);
            cc = substr(str, i, 1);
            count = 1;
        }
    }
    append(metadata, [cc, count]);
    foreach(var md; metadata) {
        count = int(md[1] * amt);
        for(var i = 0; i < count; i = i + 1) {
            new_str = new_str ~ md[0];
        }
    }
    return new_str;
}

var readout_timer = maketimer(0.1,func(){sensor_readout();});
var update_timer = maketimer(0.1,func(){sensor_update();});

var init = setlistener("/sim/signals/fdm-initialized", func() {
    readout_timer.start();
    update_timer.start();
    setlistener("/sim/multiplay/chat-history", incoming_listener, 0, 0);
});
