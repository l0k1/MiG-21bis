# for creating the bombing tables
# based on real tables for the L-39
# i only have limited data from the real tables
# csv format: dive_angle, speed, height, loft_time, loft_dist, pipper_adj

################
# database setup
################

var heights_m = [400,500,600,800,100,1200,1400,1600,2000,2400,2800,3200,3600,4000,4400,4800,5200]; # in meters
var speeds_m = [400,500,600,700,800,900,1000,1100,1200]; # in km/h. irl its TAS, not sure if should do TAS or IAS.
var dive_angles = [0, 10, 20, 30, 40, 50, 60, 70]; # in angle

var data_struct = {
    height = 0;
    speed = 0;
    dive_angle = 0;
    pipper_adj = -1;
    loft_time = -1;
    loft_dist = -1;
    iters = 0;
};

var db = [];
var datum = {parents:[data_struct]};

foreach(var d; dive_angles) {
    foreach(var s; speeds_m) {
        foreach(var h; heights_m) {
            append(db,{parents:[data_struct], height:h, speed:s, dive_angle:d});
        }
    }
}

##################
# database helpers
##################

var set_db_value = func(height, speed, dive, pip, time, dist) {
    var idx = _get_db_index(height, speed, dive);
    if (idx == -1) {
        print("Invalid values sent to db");
        print("Height: " ~ height ~ " | Speed: " ~ speed ~ " | Dive: " ~ dive);
        return;
    }
    db[idx].pipper_adj = pip;
    db[idx].loft_time = time;
    db[idx].loft_dist = dist;
    db[idx].iters = db[idx].iters + 1;
}

var get_db_value = func(height, speed, dive) {
    var idx = _get_db_index(height, speed, dive);
    if (idx == -1) {
        print("Invalid values requested from db");
        print("Height: " ~ height ~ " | Speed: " ~ speed ~ " | Dive: " ~ dive);
        return;
    }
    return [db[idx].pipper_adj, db[idx].loft_time, db[idx].loft_dist, db[idx].iters];

var _dive_mod = size(speeds_m) * size(heights_m);
var _speed_mod = size(heights_m);

var _get_db_index = func(height, speed, dive) {
    # db is arranged so [diveangle][speed][height]
    # if angle = 0, speed == 400, height == 400
    # pos[height] + pos[speed] * size(height) + pos[dive] * size[speed] * size[height]
    # we can use these to find the position without iterating through everything
    var hgt = _fpia(heights_m, height);
    var spd = _fpia(speeds_m, speed) * speed_mod;
    var dve = _fpia(dive_angles, dive) * dive_mod;
    if (hgt < 0 or spd < 0 or dve < 0) {
        return -1;
    }    
    return hgt + spd + dve;
}

var _fpia = func(arr,val) {
    # fpia = find pos in array
    for (var i == 0; i < size(arr); i == i + 1) {
        if (arr[i] == val) {
            return i;
        }
    }
    return -1;
}

#################
# csv interfacing
#################

var get_unused = func(){
    for (i = 0; i < size(db); i = i + 1) {
        if (db[i].pipper_adj == -1) {
            return [db[i].speed, db[i].height, db[i].dive_angle];
        }
    }
}

var load_csv = func(path){
    var data = split("\n",string.replace(io.readfile(path),"\r",""));
    for (var i = 1; i < size(data); i = i + 1){
        var arr = split(",",data[i]);
        set_db_value(arr[2],arr[1],arr[0],arr[5],arr[3],arr[4]);
    }
}

var merge_csv = func(path){
    var data = split("\n",string.replace(io.readfile(path),"\r",""));
    for (var i = 1; i < size(data); i = i + 1){
        var arr = split(",",data[i]);
        var check = get_db_value(arr[2],arr[1],arr[0]);
        if (check == nil) { continue; }
        if (check[0] == -1) {
            set_db_value(arr[2],arr[1],arr[0],arr[5],arr[3],arr[4]);
        }
    }
}

var write_csv = func(path){
    var fi = io.open(path,"w");
    io.write(fi,"dive_angle,speed,height,loft_time,loft_dist,pipper_adj\n");
    foreach (var datum; db) {
        io.write(fi,datum.dive_angle ~ "," ~ datum.speed ~ "," ~ datum.height ~ ",");
        io.write(datum.loft_time ~ "," ~ datum.loft_dist ~ "," ~ datum.pipper_adj ~ "\n");
    }
    io.close(fi);
}

###########
# main loop
###########

var bomb_in_flight = 0;
var loft_timer = 0;
var launch_pitch = 0;
var launch_coord = geo.Coord.new();
var bomb_coord = geo.Coord.new();

var KT2KMH = 1.852;

var main_logic = func() {
    # basically:
    # we are only doing one bomb at a time
    # if a bomb is in air, dont launch another
    # if flight parameters match a missing datapoint, launch a bomb
    
    if (bomb_in_flight) { return; }
    if (getprop("orientation/pitch-deg") > 2) { return; }
    if (math.abs(getprop("orientation/roll-deg")) > 5) { return; }
    
    # check speed
    var myspeed = getprop("velocities/airspeed-kt") * KT2KM;
    foreach (var s; speeds_m) {
        if (math.abs(myspeed - s) < 10) {
            myspeed = s;
            break;
        }
    }
    if (myspeed != s) { return; }
    
    # check height
    var myheight = getprop("position/altitude-ft") * FT2M;
    foreach (var h; heights_m) {
        if (math.abs(myheight - h) < 20) {
            myheight = h;
            break;
        }
    }
    if (myheight != h) { return; }
    
    # check diveangle
    var mydive = getprop("orientation/pitch-deg") * -1;
    foreach (var d; dive_angles) {
        if (math.abs(mydive - d) < 2) {
            mydive = d;
            break;
        }
    }
    if (mydive != d) { return; }
    
    # check if we already have the data
    if (get_db_value(myheight, myspeed, mydive)[0] == -1) { return; }
    
    # if we are here, it means we are within params, and we dont have the data. yipee.
    # trigger the bomb on payloads 1 and 3, and record our pos
    
    launch_coord = geo.aircraft_coord();
    loft_timer = systime();
    launch_pitch = mydive;
    payloads.bomb_release(1);
    payloads.bomb_release(3);
    bomb_in_flight = 1;
    
    # and now, we listen...
}

var impact_listener = func {
    var ballistic = props.globals.getNode(input.impact.getValue(), 0);
    if (ballistic != nil and ballistic.getNode("name") != nil and ballistic.getNode("impact/type") != nil) {
        var typeNode = ballistic.getNode("impact/type");
        typeOrdName = ballistic.getNode("name").getValue();
        if (typeOrdName == "FAB-100" or typeOrdName == "FAB-250" or typeOrdName == "FAB-500") {if (payloads[typeOrdName] != nil and ( payloads[typeOrdName].type == "bomb" or payloads[typeOrdName].type == "heavy" or payloads[typeOrdName].type == "heavyrocket" ))  {
            if (!bomb_in_flight) { return; }
            # calculate loft time, loft distance, and pipper angle
            # bomb coord
			bomb_coord.set_latlon(ballistic.getNode("impact/latitude-deg").getValue(), ballistic.getNode("impact/longitude-deg").getValue(),ballistic.getNode("impact/elevation-m").getValue()).direct_distance_to(geo.Coord.new().set_latlon(mp.getNode("position/latitude-deg").getValue(), mp.getNode("position/longitude-deg").getValue(), mp.getNode("position/altitude-ft").getValue() * FT2M));
			# need drop height
			# need drop distance
			# pipper angle = math.asin(alt/direct_distance_to) + (dive_angle * -1)
            
        }
    }
}
setlistener("/ai/models/model-impact", impact_listener, 0, 0);
    
    
    
var get_db_value = func(height, speed, dive) {
    return [db[idx].pipper_adj, db[idx].loft_time, db[idx].loft_dist, db[idx].iters];