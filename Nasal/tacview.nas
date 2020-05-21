# ID Scheme
# currently using ints, but it accepts hex
# 999 - my plane
# 1000 - 11000 - other planes
# 11000 - 21000 - missiles
# 21000 - 41000 - explosions

var main_update_rate = 0.3;
var write_rate = 10;

var outstr = "";

var timestamp = "";
var output_file = "";
var f = "";
var myplaneID = 999;
var starttime = 0;
var writetime = 0;

seen_ids = [];

obj3d = {
    l: 0,
    w: 0,
    h: 0,
    type: "Ground+Static+Building",
};
#  {parents:[obj3d], l: ,w: ,h: },
depot_db = {
    0: {parents:[obj3d], l: 30,w: 32,h: 8}, # depot
    1: {parents:[obj3d], l: 60,w: 75,h: 7}, # compound
    2: {parents:[obj3d], l: 44,w: 44,h: 24}, # gasometer
    3: nil,
    4: {parents:[obj3d], l: 91,w: 45,h: 20}, # warehouse
    5: {parents:[obj3d], l: 91,w: 160,h: 30}, # powerplant
    6: {parents:[obj3d], l: 120,w: 7.5,h: 7.5}, # bridge
    7: {parents:[obj3d], l: 5,w: 24.5,h: 5.2}, # 40ft container
    8: {parents:[obj3d], l: 20,w: 20,h: 8}, # apttower
    9: {parents:[obj3d], l: 40,w: 48,h: 16}, # lighthangar
    10: {parents:[obj3d], l: 32,w: 48,h: 10}, # bunker
    11: {parents:[obj3d], l: 54,w: 22,h: 36}, # flat
    12: {parents:[obj3d], l: 5,w: 24.5,h: 5.2}, # container target
    13: nil,
    14: {parents:[obj3d], l: 46,w: 24,h: 7.5}, # doubleshelter
    15: {parents:[obj3d], l: 70,w: 60,h: 14}, # factory
    16: {parents:[obj3d], l: 76,w: 32,h: 4}, # fuel farm
    17: {parents:[obj3d], l: 55,w: 76,h: 10}, # hard shelter
    18: {parents:[obj3d], l: 50,w: 50,h: 4}, # mil checkpoint
    19: {parents:[obj3d], l: 100,w: 100,h: 55}, # oil rig
    20: {parents:[obj3d], l: 40,w: 40,h: 12}, # radar station
};

var colors = ["Red","Orange","Green","Violet"];

var tacobj = {
    tacviewID: 0,
    lat: 0,
    lon: 0,
    alt: 0,
    roll: 0,
    pitch: 0,
    heading: 0,
    speed: -1,
    valid: 0,
};

var lat = 0;
var lon = 0;
var alt = 0;
var roll = 0;
var pitch = 0;
var heading = 0;
var speed = 0;
var mutexWrite = thread.newlock();

var startwrite = func() {
    timestamp = getprop("/sim/time/utc/year") ~ "-" ~ getprop("/sim/time/utc/month") ~ "-" ~ getprop("/sim/time/utc/day") ~ "T";
    timestamp = timestamp ~ getprop("/sim/time/utc/hour") ~ ":" ~ getprop("/sim/time/utc/minute") ~ ":" ~ getprop("/sim/time/utc/second") ~ "Z";
    filetimestamp = string.replace(timestamp,":","-");
    output_file = getprop("/sim/fg-home") ~ "/Export/tacview-" ~ filetimestamp ~ ".acmi";
    # create the file
    f = io.open(output_file, "w+");
    io.close(f);
    thread.lock(mutexWrite);
    write("FileType=text/acmi/tacview\nFileVersion=2.1\n");
    write("0,ReferenceTime=" ~ timestamp ~ "\n#0\n");
    write(myplaneID ~ ",T=" ~ getLon() ~ "|" ~ getLat() ~ "|" ~ getAlt() ~ "|" ~ getRoll() ~ "|" ~ getPitch() ~ "|" ~ getHeading() ~ ",Name=MiG-21bis,CallSign="~getprop("/sim/multiplay/callsign")~"\n"); #
    thread.unlock(mutexWrite);
    starttime = systime();
    setprop("/sim/screen/black","Starting tacview recording");
    settimer(func(){mainloop();}, main_update_rate);
}

var stopwrite = func() {
    setprop("/sim/screen/black","Stopping tacview recording");
    writetofile();
    starttime = 0;
    seen_ids = [];
    explo_arr = [];
    explosion_timeout_loop(1);
}

var mainloop = func() {
    if (!starttime) {
        return;
    }
    settimer(func(){mainloop();}, main_update_rate);
    if (systime() - writetime > write_rate) {
        writetofile();
    }
    thread.lock(mutexWrite);
    write("#" ~ (systime() - starttime)~"\n");
    writeMyPlanePos();
    writeMyPlaneAttributes();
    thread.unlock(mutexWrite);
    foreach (var cx; mpdb.cx_master_list) {
        var mm = cx.get_model2();
        var inf = nil;
        if (mm == "depot" or mm == "struct" or mm == "point" or mm == "rig") {
            inf = depot_db[cx.node.getNode("sim/multiplay/generic/int[17]").getValue()];
        }
        thread.lock(mutexWrite);
        if (find_in_array(seen_ids, cx.tacobj.tacviewID) == -1) {
            append(seen_ids, cx.tacobj.tacviewID);
            write(cx.tacobj.tacviewID ~ ",Name="~cx.get_model2() ~ ",CallSign=" ~ cx.get_Callsign());
            if (inf != nil) {
                if (inf.w) {
                    write(",Length="~inf.l~",Width="~inf.w~",Height="~inf.h);
                }
                write(",Type="~inf.type);
            }
            mm = colors[math.floor(rand() * size(colors))];
            write(",Color="~mm~"\n");
        }
        if (cx.tacobj.valid) {
            lon = cx.get_Longitude();
            lat = cx.get_Latitude();
            alt = cx.get_altitude() * FT2M;
            roll = cx.get_Roll();
            pitch = cx.get_Pitch();
            heading = cx.get_heading();
            speed = cx.get_Speed()*KT2MPS;
            
            write(cx.tacobj.tacviewID ~ ",T=");
            if (lon != cx.tacobj.lon) {
                write(lon);
                cx.tacobj.lon = lon;
            }
            write("|");
            if (lat != cx.tacobj.lat) {
                write(lat);
                cx.tacobj.lat = lat;
            }
            write("|");
            if (alt != cx.tacobj.alt) {
                write(alt);
                cx.tacobj.alt = alt;
            }
            write("|");
            if (roll != cx.tacobj.roll) {
                write(roll);
                cx.tacobj.roll = roll;
            }
            write("|");
            if (pitch != cx.tacobj.pitch) {
                write(pitch);
                cx.tacobj.pitch = pitch;
            }
            write("|");
            if (heading != cx.tacobj.heading) {
                write(heading);
                cx.tacobj.heading = heading;
            }
            if (speed != cx.tacobj.speed) {
                write(",TAS="~speed);
                cx.tacobj.speed = speed;
            }
            write("\n");
        }
        thread.unlock(mutexWrite);
    }
    explosion_timeout_loop();
}

var writeMyPlanePos = func() {
    thread.lock(mutexWrite);
    write(myplaneID ~ ",T=" ~ getLon() ~ "|" ~ getLat() ~ "|" ~ getAlt() ~ "|" ~ getRoll() ~ "|" ~ getPitch() ~ "|" ~ getHeading() ~ "\n");
    thread.unlock(mutexWrite);
}

var writeMyPlaneAttributes = func() {
    thread.lock(mutexWrite);
    write(myplaneID ~ ",TAS="~getTas()~",MACH="~getMach()~",AOA="~getAoA()~",HDG="~getHeading()~",Throttle="~getThrottle()~",Afterburner="~getAfterburner()~"\n");
    thread.unlock(mutexWrite);
}

explo = {
    tacviewID: 0,
    time: 0,
};

var explo_arr = [];

# needs threadlocked before calling
var writeExplosion = func(lat,lon,altm,rad) {
    var e = {parents:[explo]};
    e.tacviewID = 21000 + int(math.floor(rand()*20000));
    e.time = systime();
    append(explo_arr, e);
    write("#" ~ (systime() - starttime)~"\n");
    write(e.tacviewID ~",T="~lon~"|"~lat~"|"~altm~",Radius="~rad~",Type=Explosion\n");
}

var explosion_timeout_loop = func(all = 0) {
    foreach(var e; explo_arr) {
        if (e.time) {
            if (systime() - e.time > 15 or all) {
                thread.lock(mutexWrite);
                write("#" ~ (systime() - starttime)~"\n");
                write("-"~e.tacviewID);
                thread.unlock(mutexWrite);
                e.time = 0;
            }
        }
    }
}

var write = func(str) {
    outstr = outstr ~ str;
}

var writetofile = func() {
    if (outstr == "") {
        return;
    }
    writetime = systime();
    f = io.open(output_file, "a+");
    io.write(f, outstr);
    io.close(f);
    outstr = "";
}

var getLat = func() {
    return getprop("/position/latitude-deg");
}

var getLon = func() {
    return getprop("/position/longitude-deg");
}

var getAlt = func() {
    return rounder(getprop("/position/altitude-ft") * FT2M,0.01);
}

var getRoll = func() {
    return rounder(getprop("/orientation/roll-deg"),0.01);
}

var getPitch = func() {
    return rounder(getprop("/orientation/pitch-deg"),0.01);
}

var getHeading = func() {
    return rounder(getprop("/orientation/heading-deg"),0.01);
}

var getTas = func() {
    return rounder(getprop("/velocities/tas-kt") * KT2MPS,1.0);
}

var getMach = func() {
    return rounder(getprop("/velocities/mach"),0.001);
}

var getAoA = func() {
    return rounder(getprop("/orientation/alpha-deg"),0.01);
}

var getThrottle = func() {
    return rounder(getprop("/fdm/jsbsim/fcs/throttle-cmd-norm"),0.01);
}

var getAfterburner = func() {
    return getprop("/fdm/jsbsim/fcs/aug-active");
}

var rounder = func(x, p) {
    v = math.mod(x, p);
    if ( v <= (p * 0.5) ) {
        x = x - v;
    } else {
        x = (x + p) - v;
    }
}

var find_in_array = func(arr,val) {
    forindex(var i; arr) {
        if ( arr[i] == val ) {
            return i;
        }
    }
    return -1;
}

setlistener("/fdm/jsbsim/systems/armament/release", func() {
    if (!starttime) {
        return;
    }
    thread.lock(mutexWrite);
    write("#" ~ (systime() - starttime)~"\n");
    write("0,Event=Message|"~ myplaneID ~ "|Pickle\n");
    thread.unlock(mutexWrite);
},0,0);

setlistener("/controls/armament/trigger", func(p) {
    if (!starttime) {
        return;
    }
    thread.lock(mutexWrite);
    if (p.getValue()) {
        write("#" ~ (systime() - starttime)~"\n");
        write("0,Event=Message|"~ myplaneID ~ "|Trigger pressed.\n");
    } else {
        write("#" ~ (systime() - starttime)~"\n");
        write("0,Event=Message|"~ myplaneID ~ "|Trigger released.\n");
    }
    thread.unlock(mutexWrite);
},0,0);

setlistener("/sim/multiplay/chat-history", func(p) {
    if (!starttime) {
        return;
    }
    var hist_vector = split("\n",p.getValue());
    if (size(hist_vector) > 0) {
        var last = hist_vector[size(hist_vector)-1];
        thread.lock(mutexWrite);
        write("#" ~ (systime() - tacview.starttime)~"\n");
        write("0,Event=Message|Chat ["~hist_vector[size(hist_vector)-1]~"]\n");
        thread.unlock(mutexWrite);
    }
},0,0);