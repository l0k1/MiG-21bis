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
    
