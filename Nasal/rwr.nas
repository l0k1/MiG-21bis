
var my_heading = props.globals.getNode("/orientation/heading-deg");
var my_pitch = props.globals.getNode("/orientation/pitch-deg");
var my_roll = props.globals.getNode("/orientation/roll-deg");
var my_callsign = props.globals.getNode("/sim/multiplay/callsign");

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
    
    foreach (var cx; mpdb.cx_master_list) {
        # first the easy stuff
        # check if the contacts radar is active
        #print("checking " ~ cx.get_Callsign());
        if (!cx.isRadarActive()) {
            continue;
        }
        if (cx.info.rwr_strength == 0) {
            continue;
        }
        #print("radar active and strength good");
        # check if we should be lit up
        var distance = myCoord.direct_distance_to(cx.get_Coord()) * M2NM;
        # adjust for distance
        # below 5% is constant on, above 85% we start to get iffy.
        #print(distance);
        if (distance > cx.info.rwr_strength) {
            continue;
        }
        #print("distance good");
        if (distance > cx.info.rwr_strength * 0.01 and cx.getLockHash() != left(md5(my_callsign.getValue()), 4)) {
            # check if we are in the scan pattern
            var expanded = expand_string(cx.info.rwr_pattern, distance / 15);
            #print(expanded);
            var interval = math.round((systime() - cx.info._rwr_last_update) / (size(cx.info.rwr_pattern) / cx.info.rwr_pattern_time));
            # get where our signal is at in the pattern.
            cx.info._rwr_index = math.periodic(0, size(expanded), cx.info._rwr_index + (interval == 0 ? 1 : interval) );
            cx.info._rwr_last_update = systime();
            #print(cx.info._rwr_index);
            if (substr(expanded, cx.info._rwr_index, 1) == "n") {
                continue;
            }
            #print("past the substr n");
            #print("past the far future");
        }

        # check max distance
        # chance of not receiving radio signal between 85% and max distance
        if ( distance > cx.info.rwr_strength * 0.85 and rand() < math.clamp((distance - (cx.info.rwr_strength * 0.85))/(cx.info.rwr_strength-(cx.info.rwr_strength * 0.85)),0,1) ) {
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
        
        var sensor_id = [];
        
        # check that we are in the tgt radar cone
        var bearing = math.abs(geo.normdeg180(vector.Math.angleBetweenVectors(vector.Math.eulerToCartesian3X(cx.get_heading(), cx.get_Pitch(), cx.get_Roll()), vector.Math.projVectorOnPlane(vectorEchoTop,vectorToEcho))+180));
        
        if (bearing > cx.info.rwr_bearing) {
            continue;
        }

        bearing = math.abs(geo.normdeg180(vector.Math.angleBetweenVectors(vectorEchoTop, vectorToEcho))-90); #pitch
        if (bearing > cx.info.rwr_pitch) {
            continue;
        }
        #print("pitch good");
                
        # get which sensors this would potentially be affecting.
        # we are checking both pitch, and bearing
        #print('bearing ' ~ bearing);
        #print('rel_pitch ' ~ rel_pitch);
        bearing = get_bearing(vectorToEcho,vectorSide);
        for (var i = 0; i < size(sensors); i = i + 1) {
            if (sensors[i].max_pitch < rel_pitch) {
                #print(rel_pitch);
                continue;
            }
            #print(bearing);
            if (sensors[i].min_bearing < sensors[i].max_bearing and bearing > sensors[i].min_bearing and bearing < sensors[i].max_bearing) {
                append(sensor_id,i);
                if (cx.node.getNode("multiplay/generic/string[4]") != nil) {
                    if (size(cx.node.getNode("multiplay/generic/string[4]")) == 3 and iff_power_node.getValue() > 110) {
                        resp_node.setValue(1);
                    }
                }
                #print('appendo 1');
            } elsif (sensors[i].min_bearing > sensors[i].max_bearing and (bearing > sensors[i].min_bearing or bearing < sensors[i].max_bearing)) {
                append(sensor_id,i);
                if (cx.node.getNode("multiplay/generic/string[4]") != nil) {
                    if (size(cx.node.getNode("multiplay/generic/string[4]")) == 3 and iff_power_node.getValue() > 110) {
                        resp_node.setValue(1);
                    }
                }
                #print('appendo 2');
            }
        }
        if (size(sensor_id) == 0) {
            continue;
        }
        #print('valid sensors');
        
        # and finally, let the sensor know we have a signal

        foreach (var id; sensor_id){
            #print("setting sensor " ~ id);
            sensors[id].strength = 1;
        }
    }
}

var sensor_readout = func() {
    foreach (var sensor; sensors) {
        if (sensor.missile > 0) {
            #print("missile launched in sensor_readout");
            if (systime() - sensor.missile > 8) { # the '8' is how long in seconds it should blink for
                #print("resetting missile launch");
                sensor.missile = 0;
            }
        } else {
            if (sensor.strength == 1) {
                setprop(sensor.prop,1);
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

var expand_string = func(str, amt) {
    var metadata = [];
    var count = 0;
    var cc = substr(str, 0, 1);
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
        count = int(md[1] * amt) == 0 ? 1 : int(md[1] * amt);
        for(var i = 0; i < count; i = i + 1) {
            new_str = new_str ~ md[0];
        }
    }
    return new_str;
}

# IFF IMTR light - placing here for some reason
iff_power_node = props.globals.getNode("/fdm/jsbsim/electric/output/srzo-iff");
imtr_node = props.globals.getNode("/instrumentation/iff/imtr-light");
resp_node = props.globals.getNode("/instrumentation/iff/resp-light");
decod_node = props.globals.getNode("/instrumentation/iff/decod-light");
var iff_imtr_light = func() {
    if (iff_power_node.getValue() > 110) {
        imtr_node.setValue(1);
    } else {
        imtr_node.setValue(0);
    }
}

var readout_timer = maketimer(0.1,func(){sensor_readout();});
var update_timer = maketimer(0.1,func(){sensor_update();});
var iff_timer = maketimer(0.5,func(){iff_imtr_light();});

var init = setlistener("/sim/signals/fdm-initialized", func() {
    readout_timer.start();
    update_timer.start();
    iff_timer.start();
});
