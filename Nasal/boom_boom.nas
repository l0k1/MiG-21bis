# for creating the bombing tables
# based on real tables for the L-39
# i only have limited data from the real tables
# csv format: dive_angle, speed, height, loft_time, loft_dist, pipper_adj

debug = 1;

################
# database setup
################

var heights_m = [400,500,600,800,100,1200,1400,1600,2000,2400,2800,3200,3600,4000,4400,4800,5200]; # in meters
var speeds_m = [400,500,600,700,800,900,1000,1100,1200]; # in km/h. irl its TAS, not sure if should do TAS or IAS.
var dive_angles = [0, 10, 20, 30, 40, 50, 60, 70]; # in angle

var data_struct = {
    height: 0,
    speed: 0,
    dive_angle: 0,
    pipper_adj: -1,
    loft_time: -1,
    loft_dist: -1,
    iters: 0,
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
}

var _dive_mod = size(speeds_m) * size(heights_m);
var _speed_mod = size(heights_m);

var _get_db_index = func(height, speed, dive) {
    # db is arranged so [diveangle][speed][height]
    # if angle = 0, speed == 400, height == 400
    # pos[height] + pos[speed] * size(height) + pos[dive] * size[speed] * size[height]
    # we can use these to find the position without iterating through everything
    var hgt = _fpia(heights_m, height);
    var spd = _fpia(speeds_m, speed) * _speed_mod;
    var dve = _fpia(dive_angles, dive) * _dive_mod;
    if (hgt < 0 or spd < 0 or dve < 0) {
        return -1;
    }    
    return hgt + spd + dve;
}

var _fpia = func(arr,val) {
    # fpia = find pos in array
    for (var i = 0; i < size(arr); i = i + 1) {
        if (arr[i] == val) {
            return i;
        }
    }
    return -1;
}

#################
# csv interfacing
#################

var _get_unused = func(){
    for (i = 0; i < size(db); i = i + 1) {
        if (db[i].pipper_adj == -1) {
            return [db[i].speed, db[i].height, db[i].dive_angle];
        }
    }
}

var _load_csv = func(path){
    var data = split("\n",string.replace(io.readfile(path),"\r",""));
    for (var i = 1; i < size(data); i = i + 1){
        var parse = data[i];
        var arse = split(",",parse);
        if (size(arse) < 2) {continue;}
        set_db_value(arse[2],arse[1],arse[0],arse[5],arse[3],arse[4]);
    }
}

var _merge_csv = func(path){
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

var _write_csv = func(path){
    var fi = io.open(path,"w");
    io.write(fi,"dive_angle,speed,height,loft_time,loft_dist,pipper_adj\n");
    foreach (var datum; db) {
        io.write(fi,datum.dive_angle ~ "," ~ datum.speed ~ "," ~ datum.height ~ ",");
        io.write(fi,datum.loft_time ~ "," ~ datum.loft_dist ~ "," ~ datum.pipper_adj ~ "\n");
    }
    io.close(fi);
}

###########
# main loop
###########

var bomb_in_flight = 0;
var release_time = 0;
var release_speed = 0;
var release_alt = 0;
var release_pitch = 0;
var launch_coord = geo.Coord.new();
var bomb_coord = geo.Coord.new();

var KT2KMH = 1.852;

var trigger_check = func() {
    # basically:
    # we are only doing one bomb at a time
    # if a bomb is in air, dont launch another
    # if flight parameters match a missing datapoint, launch a bomb
    
    if (bomb_in_flight) { return; }
    #if (math.abs(getprop("orientation/yaw-deg")) > 2) { return; }
    if (math.abs(getprop("orientation/roll-deg")) > 5) { return; }
    
    # check speed
    var myspeed = getprop("velocities/airspeed-kt") * KT2KMH;
    var myheight = getprop("position/altitude-ft") * FT2M;
    var mydive = getprop("orientation/pitch-deg") * -1;
    setprop("aa_kmh",myspeed);
    setprop("aa_alt",myheight);
    setprop("aa_dive",mydive);
    foreach (var s; speeds_m) {
        if (math.abs(myspeed - s) < 10) {
            myspeed = s;
            break;
        }
    }
    if (myspeed != s) { return; }
    
    # check height
    foreach (var h; heights_m) {
        if (math.abs(myheight - h) < 20) {
            myheight = h;
            break;
        }
    }
    if (myheight != h) { return; }
    
    # check diveangle
    foreach (var d; dive_angles) {
        if (math.abs(mydive - d) < 2) {
            mydive = d;
            break;
        }
    }
    if (mydive != d) { return; }
    
    #kungfu("weve made it past our checks");
    # check if we already have the data
    if (get_db_value(myheight, myspeed, mydive)[0] != -1) { return; }
    
    # if we are here, it means we are within params, and we dont have the data. yipee.
    # trigger the bomb on payloads 1 and 3, and record our pos
    
    launch_coord = geo.aircraft_position();
    release_time = systime();
    release_pitch = mydive;
    release_speed = myspeed;
    release_alt = myheight;
    payloads.bomb_release(1);
    payloads.bomb_release(3);
    screen.log.write("Collecting data for: " ~ myspeed ~ "kmh, " ~ myheight ~ "m, " ~ release_pitch,1.0,0.0,0.0);
    bomb_in_flight = 1;
    
    # and now, we listen...
}

var impact_listener = func {
    var ballistic = props.globals.getNode(props.globals.getNode("/ai/models/model-impact").getValue(), 0);
    if (ballistic != nil and ballistic.getNode("name") != nil and ballistic.getNode("impact/type") != nil) {
        var typeNode = ballistic.getNode("impact/type");
        typeOrdName = ballistic.getNode("name").getValue();
        if (typeOrdName == "FAB-100" or typeOrdName == "FAB-250" or typeOrdName == "FAB-500") {
            if (!bomb_in_flight) { return; }
            # calculate loft time, loft distance, and pipper angle
            # bomb coord
			bomb_coord.set_latlon(ballistic.getNode("impact/latitude-deg").getValue(), ballistic.getNode("impact/longitude-deg").getValue(),ballistic.getNode("impact/elevation-m").getValue());
			# need drop height
			# need drop distance
			# pipper angle = math.asin(alt/direct_distance_to) + (dive_angle * -1)
            var drop_ang = release_pitch - (math.asin((launch_coord.alt() - bomb_coord.alt())/launch_coord.direct_distance_to(bomb_coord))*R2D);
            set_db_value(release_alt, release_speed, release_pitch, drop_ang, systime() - release_time,launch_coord.distance_to(bomb_coord));
            bomb_in_flight = 0;
            screen.log.write("Data collected: time " ~ (int(systime() - release_time)) ~ "s, distance " ~ int(launch_coord.distance_to(bomb_coord)) ~ "m, angle " ~ drop_ang,1.0,0.0,0.0);
        }
    }
}
setlistener("/ai/models/model-impact", impact_listener, 0, 0);



var main_loop = func() {
    if (getprop("/aa_bomb_testing_enable")) {
        trigger_check();
    }
    settimer(func(){main_loop();},0.2);
}

main_loop();

var csv_path = getprop("/sim/fg-home") ~ "/Export/MiG-21bis/bomb_data.csv";
var is_loaded = 0;

var kungfu = func(str) {
    if (debug) {
        print(str)
    }
}

####################
# callable functions
####################

var start_collection = func() {
    setprop("/aa_bomb_testing_enable",1);
}

var stop_collection = func() {
    setprop("/aa_bomb_testing_enable",0);
}

var import_csv = func(path = nil) {
    path = !path ? csv_path : path;
    if (io.stat(path) == nil){
        screen.log.write("Import failed");
        kungfu("unable to stat " ~ path);
        return;
    } elsif (!is_loaded) {
        _load_csv(path);
        is_loaded = 1;
    } else {
        _merge_csv(path);
    }
}

var export_csv = func(path = nil) {
    path = !path ? csv_path : path;
    _write_csv(path)
}

var request_info = func(){
    var info = _get_unused();
    screen.log.write("Speed: " ~ info[0] ~ "kmh, alt: " ~ info[1] ~ "m, angle: " ~ info[2],1.0,0.0,0.0);
}
