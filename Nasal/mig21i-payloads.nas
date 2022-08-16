#
# Code largely copied from Nikolai V. Chr.'s most excellent Viggen.
#
### Pylon mapping:
#pylons go 1,3,4,2 left to right IRL
#pylons go 0,1,3,4 left to right internally

# internal  | in-sim    | usage         | name      | actual/virtual
#-------------------------------------  --------------------------
# 0         | 1         | weapons/tank  | outb left | actual
# 1         | 3         | weapons       | inbd left | actual
# 2         | 5         | tank/h.weaps  | center    | actual
# 3         | 4         | weapons       | inbd rght | actual
# 4         | 2         | weapons/tank  | outd rght | actual
# 5         | -         | cm/jato       | rear left | actual
# 6         | -         | cm/jato       | rear rght | actual
# 7         | -         | r-60#2        | link2 #1  | virtual
# 8         | -         | r-60#2        | link2 #3  | virtual

var UPDATE_PERIOD = 0.1;

var FALSE = 0;
var TRUE = 1;

var MISSILE_STANDBY = -1;
var MISSILE_SEARCH = 0;
var MISSILE_LOCK = 1;
var MISSILE_FLYING = 2;

var ir_sar_switch = "/controls/armament/panel/ir-sar-switch";

var interp = func(x,x0,y0,x1,y1) {
    return y0 + ( x - x0 ) * ((y1 - y0) / (x1 - x0))
}

var pos_arm = {
    new: func(name, brevity, weight, type, id, rail_id, hit_max_distance = 65, ammo_count = 0,guidance_func = nil) {
        var m = {parents:[pos_arm]};
        m.name = name;
        m.brevity = brevity;
        m.weight = weight;
        m.type = type;
        m.id = id;
        m.rail_id = rail_id;
        m.type_norm = 1;
        if ( type == "radar" or type == "beam" ) {
            m.type_norm = 2;
        } elsif (type == "ir" ) {
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
    #name: pos_arm.new(name, brevity code, weight, type/guidance, id for animations, rail id, hit message max distance (not used for guided missiles), ammo count (optional), guidance function (optional)
    #bomb names can NOT have spaces in them.
    #type/guidance options: none (dnu),radar, ir, beam, bomb, rocket, tank, antirad, heavy, cm
    #regarding hit distance, the GSh-23 is coded as 35m seperately in this file
    # rail ID's are:
    # 0 - none
    # 1 - MBD2-67U
    # 2 - APU-68
    # 3 - APU-13U2
    "none":              pos_arm.new("none","none",0,"none",0,0),
    "PTB-490 Droptank":  pos_arm.new("PTB-490 Droptank","PTB-490 Droptank",180,"tank",27,0),
    "Smokepod":          pos_arm.new("Smokepod","Smokepod",157,"tank",29,0),
};

# add in virtual pylons too

var update_pylons = func(pylon) {

    # this function is called from a setlistener, whenever the weight of a pylon is updated.
    
    # first part, see what the new name is and its weight
    if (pylon < 7) {
        var selected = getprop("/payload/weight["~pylon~"]/selected");
        var pylon_weight = getprop("/payload/weight["~pylon~"]/weight-lb");
    }
    if ( selected == nil ) {
        return;
    }
    # get the payload object
    var payload = payloads[selected];
    
    # create a pylon with the selected payload
    # special handling for some is needed
    if (payload.name != "none" and pylon_weight == 0 and pylon < 7) {
        create_pylon(pylon,payload,selected);
    } elsif (payload.name == "none") {
        #print('empty pylon ' ~ pylon);
        empty_pylon(pylon);
    }
    
    # JSBSIM weight
    if (getprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~ pylon ~"]") != nil and getprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~ pylon ~"]") != payload.weight) {
        #print("setting weight of " ~ payload.weight ~ " on pylon " ~ i);
        setprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~ pylon ~"]", payload.weight);
    }
}

var create_pylon = func(pylon, payload, selected) {

    if(pylon != 7 and pylon != 8) {
        setprop("/payload/weight["~pylon~"]/id",payload.id);
    }
    if ( selected != "none" and pylon != 7 and pylon != 8 ) {
        setprop("/payload/rail["~pylon~"]/id", payload.rail_id);
    }
    

    if (payload.type == "tank") {
        if (selected == "PTB-800") {
            setprop("/consumables/fuel/tank["~pylon_to_tank_array[pylon]~"]/level-norm",1400);
        } else {
            setprop("/consumables/fuel/tank["~pylon_to_tank_array[pylon]~"]/level-norm",850);
        }
    }

}

var empty_pylon = func(pylon) {

    # remove a pylon
    # set any leftover rockets or countermeasures to 0
    # de-activate and remove the missile object

    setprop("/payload/weight["~pylon~"]/id",0);
    
}


var drop_tank_handling_loop = func() {

    # Drop tank stuff

    for (var pylon = 0; pylon <= 10; pylon = pylon + 1) {
        if (pylon < 7) {
            var payloadName = getprop("/payload/weight[" ~ pylon ~ "]/selected");
        } else {
            var payloadName = getprop("/payload/virtual/weight[" ~ pylon ~ "]/selected");
        }
        if (pylon == 0 or pylon == 2 or pylon == 4) {
            if (payloadName != "PTB-800 Droptank" and payloadName != "PTB-490 Droptank") {
                # no drop tank attached, clear that tank
                setprop("/consumables/fuel/tank["~pylon_to_tank_array[pylon]~"]/selected",0);
                setprop("/consumables/fuel/tank["~pylon_to_tank_array[pylon]~"]/jettisoned",1);
                setprop("/consumables/fuel/tank["~pylon_to_tank_array[pylon]~"]/level-norm",0);
            } elsif (payloadName == "PTB-800 Droptank" or payloadName == "PTB-490 Droptank") {
                setprop("/consumables/fuel/tank["~pylon_to_tank_array[pylon]~"]/selected",1);
                setprop("/consumables/fuel/tank["~pylon_to_tank_array[pylon]~"]/jettisoned",0);
            }
        }
        if (pylon == 2 and payloadName == "PTB-490 Droptank" and getprop("/consumables/fuel/tank["~pylon_to_tank_array[pylon]~"]/level-lbs") > 850) {
            setprop("/consumables/fuel/tank["~pylon_to_tank_array[pylon]~"]/level-lbs",850)
        }
    }
}

var pylon_to_tank_array = [12,-1,11,-1,13];

setlistener("/controls/armament/jettison/tanks_jett",func(){jettison([-1]);});
setlistener("/controls/armament/jettison/center_tank",func(){jettison([2]);});
setlistener("/controls/armament/jettison/outbd_jett",func(){jettison([0,4]);});
setlistener("/controls/armament/jettison/inbd_jett",func(){jettison([1,3]);});

var jettison = func(pylons) {
    var selected = "";
    if (pylons[0] == -1) {
        # wing tank jettison button
        if (getprop("/fdm/jsbsim/electric/output/drop-tanks-jett") < 110) {return;}
        foreach (var pylon; [0,4]) {
            selected = getprop("payload/weight[" ~ pylon ~ "]/selected");
            if (payloads[selected].type == "tank") {
                selected = selected == "PTB-490 Droptank" ? "PTB-490" : "PTB-800";
                setprop("payload/jettison/pyro/"~selected~"["~pylon~"]",1);
                setprop("payload/weight[" ~ pylon ~ "]/selected","none");
                setprop("/controls/armament/jettison/boom",1);
                settimer(func(){setprop("/controls/armament/jettison/boom",0);},0.1);
                return_trigger("pyro/" ~ selected,pylon);
            }
        }
    } elsif (pylons[0] == 2) {
        # center tank jettison button
        if (getprop("/fdm/jsbsim/electric/output/drop-tanks-jett") < 110) {return;}
        selected = getprop("payload/weight[2]/selected");
        if (payloads[selected].type == "tank") {
            selected = selected == "PTB-490 Droptank" ? "PTB-490" : "PTB-800";
            setprop("payload/jettison/pyro/"~selected~"[2]",1);
            setprop("payload/weight[2]/selected","none");
            setprop("/controls/armament/jettison/boom",1);
            settimer(func(){setprop("/controls/armament/jettison/boom",0);},0.2);
            sounds.disconnect();
            return_trigger("pyro/" ~ selected,2);
        }
    }
}

var _ret_trig_arr = [];
#return trigger should be passed an array in the format [selected, pylon, systime]
var return_trigger = func(selected, pylon) {
    #print("setting up for " ~ selected ~ ":" ~ pylon);
    append(_ret_trig_arr,[selected,pylon,systime()]);
}

var return_trigger_loop = func() {
    var c_time = systime();
    foreach(var entry; _ret_trig_arr){
        if (c_time - entry[2] >= 4.9) {
            entry[2] = 0;
            #print("returning trigger on " ~ entry[0] ~ ":" ~ entry[1]);
            setprop("payload/released/"~entry[0]~"["~entry[1]~"]",0);
            setprop("payload/jettison/"~entry[0]~"["~entry[1]~"]",0);
        }
    }
    var _narr = [];
    for (var i = 0; i < size(_ret_trig_arr); i = i + 1){
        if (_ret_trig_arr[i][2] != 0) {
            append(_narr,_ret_trig_arr[i]);
        }
    }
    _ret_trig_arr = _narr;
    settimer(return_trigger_loop,0);
}
return_trigger_loop();
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
    }    else {
        setprop("/sim/multiplay/generic/int[19]",0);
        return;
    }
}

var spams = 0;
var spamList = [];

############################# main init ###############

var main_init = func {
    setprop("sim/time/elapsed-at-init-sec", getprop("sim/time/elapsed-sec"));

    setprop("/consumables/fuel/tank[11]/jettisoned", FALSE);
    setprop("/consumables/fuel/tank[12]/jettisoned", FALSE);
    setprop("/consumables/fuel/tank[13]/jettisoned", FALSE);

    # pylon handling listeners

    setlistener("/payload/weight[0]/selected",func{update_pylons(0);});
    setlistener("/payload/weight[1]/selected",func{update_pylons(1);});
    setlistener("/payload/weight[2]/selected",func{update_pylons(2);});
    setlistener("/payload/weight[3]/selected",func{update_pylons(3);});
    setlistener("/payload/weight[4]/selected",func{update_pylons(4);});
    setlistener("/payload/weight[5]/selected",func{update_pylons(5);});
    setlistener("/payload/weight[6]/selected",func{update_pylons(6);});

}

var main_init_listener = setlistener("sim/signals/fdm-initialized", func {
    main_init();
    removelistener(main_init_listener);
}, 0, 0);