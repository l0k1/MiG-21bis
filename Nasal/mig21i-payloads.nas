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
    # ir missiles
    "RS-2US":            pos_arm.new("RS-2US","RS-2US",182,"ir",1,0),
    "R-55S":             pos_arm.new("R-55S","R-55S",199,"ir",2,2),
    "R-3S":              pos_arm.new("R-3S","R-3S",165,"ir",3,3),
    "R-3U":              pos_arm.new("R-3U","R-3U",165,"ir",39,3),
    "R-13M":             pos_arm.new("R-13M","R-13M",194,"ir",4,3),
    "R-60":              pos_arm.new("R-60","R-60",96,"ir",31,0),
    "R-60x2":            pos_arm.new("R-60","R-60",96,"ir",32,0,,2), # 32 if 2 missiles loaded, 31 if 1
    "R-27T1":            pos_arm.new("R-27T1","R-27T1",550,"ir",7,3),
    # radar missiles
    "R-3R":              pos_arm.new("R-3R","R-3R",168,"radar",8,3),
    "R-27R1":            pos_arm.new("R-27R1","R-27R1",560,"radar",9,3),
    # bombs
    "FAB-100":           pos_arm.new("FAB-100","FAB-100",220,"bomb",10,0,250),
    "FAB-100x4":         pos_arm.new("FAB-100x4","FAB-100x4",960,"bomb",14,1,250), # 11,12,13,14 ids for the bombs, reducing as each bomb drops
    "P-100":             pos_arm.new("P-100","P-100",221,"bomb",33,0,250),
    "P-100x4":           pos_arm.new("P-100x4","P-100x4",961,"bomb",37,1,250), # 34,35,36,37 ids for the bombs, reducing as each bomb drops
    "FAB-250":           pos_arm.new("FAB-250","FAB-250",551,"bomb",15,0,250),
    "FAB-500":           pos_arm.new("FAB-500","FAB-500",1146,"bomb",16,0,250),
    "BETAB-500ShP":      pos_arm.new("BETAB-500ShP","BETAB-500ShP",1160,"bomb",38,0,125),
    # heavy
    "RN-14T":            pos_arm.new("RN-14T","RN-14T",856,"heavy",17,0,500),
    "RN-18T":            pos_arm.new("RN-18T","RN-18T",1150,"heavy",18,0,500),
    "RN-24":             pos_arm.new("RN-24","RN-24",860,"heavy",19,0,1000),
    "RN-28":             pos_arm.new("RN-28","RN-28",1200,"heavy",20,0,1000),
    # anti-radiation
    "Kh-25MP":           pos_arm.new("Kh-25MP","Kh-25MP",695,"antirad",21,2),
    # beam
    "Kh-66":             pos_arm.new("Kh-66","Kh-66",632,"beam",22,2),
    # rockets
    "UB-16":             pos_arm.new("UB-16","UB-16",141,"rocket",23,0,,16),
    "UB-32":             pos_arm.new("UB-32","UB-32",582,"rocket",24,0,,32),
    "S-21":              pos_arm.new("S-21","S-21",341,"heavyrocket",25,0,60), # google search for с-21 ракет (cyrillic)
    "S-24":              pos_arm.new("S-24","S-24",518,"heavyrocket",26,2,60),
    "PTB-490 Droptank":  pos_arm.new("PTB-490 Droptank","PTB-490 Droptank",180,"tank",27,0),
    "PTB-800 Droptank":  pos_arm.new("PTB-800 Droptank","PTB-800 Droptank",230,"tank",28,0),
    "Smokepod":          pos_arm.new("Smokepod","Smokepod",157,"tank",29,0),
    # countermeasures
    "Conformal CM":      pos_arm.new("Conformal CM","Conformal CM",210,"cm",30,0),
    # joke
    "HMCS":              pos_arm.new("HMCS", "HMCS",420,"tank",31,0),
};

# add in virtual pylons too

var update_pylons = func(pylon) {

    # this function is called from a setlistener, whenever the weight of a pylon is updated.
    
    # first part, see what the new name is and its weight
    if (pylon < 7) {
        var selected = getprop("/payload/weight["~pylon~"]/selected");
        var pylon_weight = getprop("/payload/weight["~pylon~"]/weight-lb");
    } else {
        var selected = getprop("/payload/virtual/weight["~pylon~"]/selected");
        var pylon_weight = getprop("/payload/virtual/weight["~pylon~"]/weight-lb");
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
    } elsif (payload.name != "none" and pylon_weight != payload.weight and payload.name != "FAB-100x4") {
        #print('reset pylon ' ~ pylon ~ ' with ' ~ payload.name);
        empty_pylon(pylon);
        create_pylon(pylon,payload,selected);
    } elsif (payload.name == "FAB-100x4" and pylon_weight != 300 and pylon_weight != 520 and pylon_weight != 740 and pylon_weight != 960) {
        #print("fab-100x4 special handling on pylon " ~ pylon);
        empty_pylon(pylon);
        create_pylon(pylon,payload,selected);
    } elsif (payload.name == "P-100x4" and pylon_weight != 301 and pylon_weight != 521 and pylon_weight != 741 and pylon_weight != 961) {
        #print("fab-100x4 special handling on pylon " ~ pylon);
        empty_pylon(pylon);
        create_pylon(pylon,payload,selected);
    } elsif (payload.name == "none") {
        #print('empty pylon ' ~ pylon);
        empty_pylon(pylon);
    }
    
    # R-60x2 dual pylon special handling
    if (payload.name == "R-60" and pylon > 6) {
        if (pylon == 0) {
            var rv_p = 0;
        } elsif (pylon == 8) {
            var rv_p = 4;
        } else {
            var rv_p = pylon;
        }
        rv_p = getprop("payload/weight["~rv_p~"]/selected");
        if (rv_p != nil and rv_p != "R-60x2") {
            if (weight != 0) {
                setprop("/payload/virtual/weight["~pylon~"]/weight-lb",0);
                setprop("/payload/virtual/weight["~pylon~"]/selected","none");
            }
        }
    }

    if (payload.name == "HMCS") {
        setprop("fdm/jsbsim/systems/hmcs/quantity",100);
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
    
    
    if (payload.type == "bomb") {
        setprop("/payload/released/"~payload.name~"["~pylon~"]",FALSE);
    }

    if (payload.type == "tank") {
        if (selected == "PTB-800") {
            setprop("/consumables/fuel/tank["~pylon_to_tank_array[pylon]~"]/level-norm",1400);
        } else {
            setprop("/consumables/fuel/tank["~pylon_to_tank_array[pylon]~"]/level-norm",850);
        }
    }
    
    if (selected == "FAB-100x4") {
        if (pylon == 1) {
            setprop("/ai/submodels/submodel[32]/count",1);
            setprop("/ai/submodels/submodel[33]/count",1);
            setprop("/ai/submodels/submodel[34]/count",1);
            setprop("/ai/submodels/submodel[35]/count",1);
            setprop("/payload/released/FAB-100[5]",0);
            setprop("/payload/released/FAB-100[6]",0);
            setprop("/payload/released/FAB-100[7]",0);
            setprop("/payload/released/FAB-100[8]",0);
        } elsif (pylon == 3) {
            setprop("/ai/submodels/submodel[36]/count",1);
            setprop("/ai/submodels/submodel[37]/count",1);
            setprop("/ai/submodels/submodel[38]/count",1);
            setprop("/ai/submodels/submodel[39]/count",1);
            setprop("/payload/released/FAB-100[9]",0);
            setprop("/payload/released/FAB-100[10]",0);
            setprop("/payload/released/FAB-100[11]",0);
            setprop("/payload/released/FAB-100[12]",0);
        }
    }
    
    if (selected == "P-100x4") {
        if (pylon == 1) {
            setprop("/ai/submodels/submodel[80]/count",1);
            setprop("/ai/submodels/submodel[81]/count",1);
            setprop("/ai/submodels/submodel[82]/count",1);
            setprop("/ai/submodels/submodel[83]/count",1);
            setprop("/payload/released/P-100[5]",0);
            setprop("/payload/released/P-100[6]",0);
            setprop("/payload/released/P-100[7]",0);
            setprop("/payload/released/P-100[8]",0);
        } elsif (pylon == 3) {
            setprop("/ai/submodels/submodel[84]/count",1);
            setprop("/ai/submodels/submodel[85]/count",1);
            setprop("/ai/submodels/submodel[86]/count",1);
            setprop("/ai/submodels/submodel[87]/count",1);
            setprop("/payload/released/P-100[9]",0);
            setprop("/payload/released/P-100[10]",0);
            setprop("/payload/released/P-100[11]",0);
            setprop("/payload/released/P-100[12]",0);
        }
    }

    if (payload.type == "rocket") {
        #print('adding ammo for pylon ' ~ pylon);
        if (pylon == 0) {
            setprop("/ai/submodels/submodel[22]/count",payload.ammo_count);
        } elsif (pylon == 1){
            setprop("/ai/submodels/submodel[23]/count",payload.ammo_count);
        } elsif (pylon == 3){
            setprop("/ai/submodels/submodel[24]/count",payload.ammo_count);
        } elsif (pylon == 4){
            setprop("/ai/submodels/submodel[25]/count",payload.ammo_count);
        }
    }elsif (selected == "Conformal CM") {
        #0 ~ flares left
        #1 ~ flares right
        #2 ~ chaff left
        #3 ~ chaff right
        #18 flares, 9 chaff
        if (pylon == 5) {
            setprop("/ai/submodels/submodel[0]/count",20);
            setprop("/ai/submodels/submodel[2]/count", 9);
        } elsif (pylon == 6) {
            setprop("/ai/submodels/submodel[1]/count",20);
            setprop("/ai/submodels/submodel[3]/count", 9);
        }
    # TODO: split this out
    } elsif (selected != "FAB-100x4" and selected != "Conformal CM" and selected != "P-100x4") {
        if (pylon == 0) {
            setprop("/ai/submodels/submodel[22]/count",0);
        } elsif (pylon == 1) {
            setprop("/ai/submodels/submodel[23]/count",0);

            setprop("/ai/submodels/submodel[32]/count",0);
            setprop("/ai/submodels/submodel[33]/count",0);
            setprop("/ai/submodels/submodel[34]/count",0);
            setprop("/ai/submodels/submodel[35]/count",0);

            setprop("/ai/submodels/submodel[80]/count",0);
            setprop("/ai/submodels/submodel[81]/count",0);
            setprop("/ai/submodels/submodel[82]/count",0);
            setprop("/ai/submodels/submodel[83]/count",0);
        } elsif (pylon == 3) {
            setprop("/ai/submodels/submodel[24]/count",0);

            setprop("/ai/submodels/submodel[36]/count",0);
            setprop("/ai/submodels/submodel[37]/count",0);
            setprop("/ai/submodels/submodel[38]/count",0);
            setprop("/ai/submodels/submodel[39]/count",0);

            setprop("/ai/submodels/submodel[84]/count",0);
            setprop("/ai/submodels/submodel[85]/count",0);
            setprop("/ai/submodels/submodel[86]/count",0);
            setprop("/ai/submodels/submodel[87]/count",0);
        } elsif (pylon == 4) {
            setprop("/ai/submodels/submodel[25]/count",0);
        } elsif (pylon == 5) {
            setprop("/ai/submodels/submodel[0]/count",0);
            setprop("/ai/submodels/submodel[2]/count",0);
        } elsif (pylon == 6) {
            setprop("/ai/submodels/submodel[1]/count",0);
            setprop("/ai/submodels/submodel[3]/count",0);
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


var armament_loop = func() {
    drop_tank_handling_loop();
    settimer(armament_loop, UPDATE_PERIOD);
}

var pylon_to_tank_array = [12,-1,11,-1,13];

########### listener for handling unjamming #########

var charge_used = [0,0,0];

var unjam = func(button) {
    if ( charge_used[button] == 0 and getprop("/fdm/jsbsim/electric/output/gun") > 33) {
        charge_used[button] = 1;
        setprop("/fdm/jsbsim/systems/armament/GSh-23-jammed",0);
    }
}

setlistener("controls/armament/panel/reload[0]", func { unjam(0); } );
setlistener("controls/armament/panel/reload[1]", func { unjam(1); } );
setlistener("controls/armament/panel/reload[2]", func { unjam(2); } );

###########  trigger propogation  ###########

var missile_firing_order = [[1,3,0,4],[3,1,0,4],[0,4,1,3],[4,1,3,0]];

var trigger_propogation = func() {
    #return array of active pylons
    #returning -1 means no pylon selected

    #pylon knob
    #0: 1/2 bomb | 16 rkt
    #1: 3/4 bomb | 8 rkt
    #2: 1/4 bomb | 4 rkt
    #3: 1/2 rkt
    #4: 3/4 rkt
    #5: 3/4 msl
    #6: 1/2 msl
    #7: 1 msl
    #8: 2 msl
    #9: 3 msl
    #10: 4 msl
    #pylons go 3,1,2,4 left to right IRL
    #pylons go 0,1,3,4 left to right internally

    # missile preference is set by the IR/SAR switch
    # missile order is determined by the armament selector knob
    # 1: order is 1,2,3,4
    # 2: order is 2,1,3,4
    # 3: order is 3,4,1,2
    # 4: order is 4,1,2,3
    # if pylon is unpowered, skip it
    # if pylon is powered but fails, don't skip it
    
    if ( getprop("/fdm/jsbsim/systems/armament/release") != 1 ) {
        setprop("/controls/armament/rocket-trigger",0);
    } else {    
        var knobpos = getprop("controls/armament/panel/pylon-knob");
        if ( knobpos == 0 ) {
            setprop("/controls/armament/rocket-setting",16);
            setprop("/controls/armament/rocket-trigger",1);
            if (getprop("/controls/armament/bomb-arm") == 0) {
                if (payloads[getprop("/payload/weight[1]/selected")].type == "bomb") { jettison([1]); }
                if (payloads[getprop("/payload/weight[3]/selected")].type == "bomb") { jettison([3]); }
            } else {
                if (payloads[getprop("/payload/weight[1]/selected")].type == "bomb") { bomb_release(1,"bomb"); }
                if (payloads[getprop("/payload/weight[3]/selected")].type == "bomb") { bomb_release(3,"bomb"); }
            }
        } elsif ( knobpos == 1 ) {
            setprop("/controls/armament/rocket-setting",8);
            setprop("/controls/armament/rocket-trigger",1);
            if (getprop("/controls/armament/bomb-arm") == 0) {
                if (payloads[getprop("/payload/weight[0]/selected")].type == "bomb") { jettison([0]); }
                if (payloads[getprop("/payload/weight[4]/selected")].type == "bomb") { jettison([4]); }
            } else {
                if (payloads[getprop("/payload/weight[0]/selected")].type == "bomb") { bomb_release(0,"bomb"); }
                if (payloads[getprop("/payload/weight[4]/selected")].type == "bomb") { bomb_release(4,"bomb"); }
            }
        } elsif ( knobpos == 2 ) {
            setprop("/controls/armament/rocket-setting",4);
            setprop("/controls/armament/rocket-trigger",1);
            if (getprop("/controls/armament/bomb-arm") == 0) {
                if (payloads[getprop("/payload/weight[0]/selected")].type == "bomb") { jettison([0]); }
                if (payloads[getprop("/payload/weight[1]/selected")].type == "bomb") { jettison([1]); }
                if (payloads[getprop("/payload/weight[3]/selected")].type == "bomb") { jettison([3]); }
                if (payloads[getprop("/payload/weight[4]/selected")].type == "bomb") { jettison([4]); }
            } else {
                if (payloads[getprop("/payload/weight[0]/selected")].type == "bomb") { bomb_release(0,"bomb"); }
                if (payloads[getprop("/payload/weight[1]/selected")].type == "bomb") { bomb_release(1,"bomb"); }
                if (payloads[getprop("/payload/weight[3]/selected")].type == "bomb") { bomb_release(3,"bomb"); }
                if (payloads[getprop("/payload/weight[4]/selected")].type == "bomb") { bomb_release(4,"bomb"); }
            }
            return [0,3,knobpos];
        } elsif ( knobpos == 3 ) {
            if ( getprop("payload/weight[1]/selected") == "Kh-25MP"  and getprop("/fdm/jsbsim/electric/output/pwr-to-pylons[1]") > 32) {
                missile_release(1);
            } elsif ( getprop("payload/weight[3]/selected") == "Kh-25MP" and getprop("payload/weight[1]/selected") != "Kh-25MP" and getprop("/fdm/jsbsim/electric/output/pwr-to-pylons[3]") > 32) {
                missile_release(3);
            } else {
                bomb_release(1,"heavyrocket");
                settimer(func{
                    bomb_release(3,"heavyrocket");
                },0.1);
            }
        } elsif ( knobpos == 4 ) {
            bomb_release(0,"heavyrocket");
            settimer(func{
                bomb_release(4,"heavyrocket");
            },0.1);
        } elsif ( knobpos == 5 ) {
            var ret1 = getprop("payload/virtual/weight[7]/selected") == "R-60" ? 7 : 0;
            var ret2 = getprop("payload/virtual/weight[8]/selected") == "R-60" ? 8 : 4;        
            missile_release(ret1);
            settimer(func{
                missile_release(ret2);
            },0.1);
        } elsif ( knobpos == 6 ) {
            missile_release(1);
            settimer(func{
                missile_release(3);
            },0.1);
        } elsif ( knobpos >= 7 ) {
            # missile_firing_order
            #
            # issues
            # if ir/sar is not set, pick first missile
            # check virtual pylons
            #
            var pylon_check = -1;
            var pylon_select = -1;
            var selected_type = 1; # 0 is IR, 2 is RGM
            var virtual = "";
            for(var i = 0; i <= 3; i = i + 1){
                # get missile pylon
                pylon_check = missile_firing_order[knobpos - 7][i];
                
                # check that the pylon is powered
                if ( getprop("/fdm/jsbsim/electric/output/pwr-to-pylons",pylon_check) < 32 ) { continue; }
                
                #propogate out for our R-60's
                if( pylon_check == 0 and getprop("payload/virtual/weight[7]/selected") == "R-60" ) { pylon_check = 7; }
                if( pylon_check == 4 and getprop("payload/virtual/weight[8]/selected") == "R-60" ) { pylon_check = 8; }
                #print("loop: " ~ i ~ ":pylon:" ~ pylon_check~":type:"~selected_type);
                
                virtual = pylon_check < 7 ? "/" : "/virtual/";
                
                if ( (getprop(ir_sar_switch) == 1 and payloads[getprop("payload" ~ virtual ~ "weight["~pylon_check~"]/selected")].type_norm != 1 ) or (selected_type != getprop(ir_sar_switch) and payloads[getprop("payload" ~ virtual ~ "weight["~pylon_check~"]/selected")].type_norm == getprop(ir_sar_switch)) ) {
                         pylon_select = pylon_check;
                         break;
                } elsif ( selected_type == 1 and payloads[getprop("payload" ~ virtual ~ "weight["~pylon_check~"]/selected")].type_norm != 1 ) {
                    pylon_select = pylon_check;
                    selected_type = payloads[getprop("payload" ~ virtual ~ "weight["~pylon_check~"]/selected")].type_norm;
                }
            }
            if (pylon_select != -1 ) {
                missile_release(pylon_select);
            }
        }
    }
}

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
    } else {
        if (getprop("/fdm/jsbsim/electric/output/msl-rgm-emer-lcn-lchr-rkt-bombs-jett") < 110) {return;}
        foreach (var pylon; pylons) {
            selected = getprop("payload/weight[" ~ pylon ~ "]/selected");
            if (selected == nil) { continue; }
            if (selected == "none") { continue; }
            if (payloads[selected].type == "tank") { continue; }
            if (selected == "R-60x2") {
                var v_p = pylon == 0 ? 7 : 8;
                var virt = getprop("payload/virtual/weight["~v_p~"]/selected");
                if (virt != nil and armament.AIM.active[v_p] != nil) {
                    armament.AIM.active[v_p].eject();
                    sounds.disconnect();
                    setprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~v_p~"]",0);
                    setprop("payload/virtual/weight["~v_p~"]/selected", "none");
                }
                if (armament.AIM.active[pylon] != nil) {
                    armament.AIM.active[pylon].eject();
                    sounds.disconnect();
                    setprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~pylon~"]",0);
                    setprop("payload/weight["~pylon~"]/selected", "none");
                }
            } elsif (selected == "FAB-100x4") {
                var sub_pylon = pylon;
                var check_array = pylon == 1 ? [32,33,34,35] : [36,37,38,39];
                var idx = 0;
                foreach (var p; check_array){
                    idx = idx + 1;
                    if (getprop("/ai/submodels/submodel["~p~"]/count") > 0) {
                        sub_pylon = p;
                        break;
                    }
                }
                #print(idx);
                if (sub_pylon != p) {
                    setprop("payload/weight[" ~ ( pylon ) ~ "]/selected", "none" );
                    setprop("/payload/weight["~pylon~"]/id",0);
                    setprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~pylon~"]",0);
                    continue;
                } else {
                    setprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~pylon~"]",getprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~pylon~"]") - 220);
                    if (idx == 4) { idx = payloads["FAB-100x4"].id; }
                    setprop("/payload/weight["~pylon~"]/id",payloads["FAB-100x4"].id - idx);
                }
                #print("setting " ~sub_pylon~ " to zero");
                setprop("/ai/submodels/submodel["~sub_pylon~"]/count",0);
                setprop("payload/jettison/FAB-100["~sub_pylon~"]",1);
                sounds.disconnect();
                return_trigger("FAB-100",sub_pylon);
            } elsif (selected == "P-100x4") {
                var sub_pylon = pylon;
                var check_array = pylon == 1 ? [80,81,82,83] : [84,85,86,87];
                var idx = 0;
                foreach (var p; check_array){
                    idx = idx + 1;
                    if (getprop("/ai/submodels/submodel["~p~"]/count") > 0) {
                        sub_pylon = p;
                        break;
                    }
                }
                #print(idx);
                if (sub_pylon != p) {
                    setprop("payload/weight[" ~ ( pylon ) ~ "]/selected", "none" );
                    setprop("/payload/weight["~pylon~"]/id",0);
                    setprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~pylon~"]",0);
                    continue;
                } else {
                    setprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~pylon~"]",getprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~pylon~"]") - 220);
                    if (idx == 4) { idx = payloads["P-100x4"].id; }
                    setprop("/payload/weight["~pylon~"]/id",payloads["P-100x4"].id - idx);
                }
                #print("setting " ~sub_pylon~ " to zero");
                setprop("/ai/submodels/submodel["~sub_pylon~"]/count",0);
                setprop("payload/jettison/P-100["~sub_pylon~"]",1);
                sounds.disconnect();
                return_trigger("P-100",sub_pylon);
            } elsif (payloads[selected].type == "bomb") {
                if (getprop("/controls/armament/bomb-arm") == 1) {
                    bomb_release(pylon);
                } else {
                    setprop("payload/jettison/"~selected~"["~pylon~"]",1);
                    setprop("payload/weight[" ~ pylon ~ "]/selected","none");
                    sounds.disconnect();
                    return_trigger(selected,pylon);
                }
            } else {
                if ((payloads[selected].type == "ir" or
                        payloads[selected].type == "radar" or
                        payloads[selected].type == "antirad" or
                        payloads[selected].type == "beam") and
                        armament.AIM.active[pylon] != nil) {
                    armament.AIM.active[pylon].eject();
                    sounds.disconnect();
                    setprop("fdm/jsbsim/inertia/pointmass-weight-lbs["~pylon~"]",0);
                    setprop("payload/weight["~pylon~"]/selected", "none");
                } else {
                    sounds.disconnect();
                    setprop("payload/jettison/"~selected~"["~pylon~"]",1);
                    setprop("payload/weight[" ~ pylon ~ "]/selected","none");
                    return_trigger(selected,pylon);
                }
            }
        }
    }
}

#var countermeasure_trigger = func() {
#    #print("in func");
#    #print("trig set to: |" ~getprop("/controls/armament/cm-trigger")~"|");
#    if (getprop("/controls/armament/cm-trigger") == 0) { 
#        #print("setting trigs to 0");
#        setprop("/controls/armament/chaff-trigger",0);
#        setprop("/controls/armament/flare-trigger",0);
#        return;
#    }
#    if (getprop("/fdm/jsbsim/electric/output/jato-start") < 20) { return; }
#    if (getprop("/fdm/jsbsim/electric/output/jato-jett") < 20) { return; }
#    #print("setting trigs to 1");
#    setprop("/controls/armament/chaff-trigger",1);
#    setprop("/controls/armament/flare-trigger",1);
#}

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
############ Impact messages #####################

var hit_count = 0;
var hit_callsign = "";
var hit_timer = 0;
var closest_distance = 200;

var hit_counter = {
    new: func(name, hit_count, hit_callsign, hit_timer, closest_distance, inc_terrain) {
        var m = {parents:[hit_counter]};
        m.name = name;
        m.hit_count = hit_count;
        m.hit_callsign = hit_callsign;
        m.hit_timer = hit_timer;
        m.closest_distance = closest_distance;
        m.inc_terrain = inc_terrain;
        return m;
    }
};

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

var defeatSpamFilter = func (str) {
    spams += 1;
    if (spams == 15) {
        spams = 1;
    }
    str = str~":";
    for (var i = 1; i <= spams; i+=1) {
        str = str~".";
    }
    var myCallsign = getprop("sim/multiplay/callsign");
    if (myCallsign != nil and find(myCallsign, str) != -1) {
        str = myCallsign~": "~str;
    }
    var newList = [str];
    for (var i = 0; i < size(spamList); i += 1) {
        append(newList, spamList[i]);
    }
    spamList = newList;
}

var spamLoop = func {
    var spam = pop(spamList);
    if (spam != nil) {
        setprop("/sim/multiplay/chat", spam);
    }
    settimer(spamLoop, 1.20);
}

var model_exp = [];

var place_model = func(path, lat, lon, ele, time = 0) {
    #print(path);
    #print(lat);
    #print(lon);
    #print(ele);
    var n = props.globals.getNode("models",1);
    var i = 0;
    for (i = 0; 1==1; i += 1) {
        if (n.getChild("model",i,0) == nil) {
            break;
        }
    }

    var objModel = n.getChild("model",i,1);

    objModel.getNode("elevation",1).setDoubleValue(-999);
    objModel.getNode("latitude",1).setDoubleValue(0);
    objModel.getNode("longitude",1).setDoubleValue(0);
    objModel.getNode("elevation-ft-prop",1).setValue(objModel.getPath()~"/elevation");
    objModel.getNode("latitude-deg-prop",1).setValue(objModel.getPath()~"/latitude");
    objModel.getNode("longitude-deg-prop",1).setValue(objModel.getPath()~"/longitude");
    objModel.getNode("heading",1).setDoubleValue(0);
    objModel.getNode("pitch",1).setDoubleValue(0);
    objModel.getNode("roll",1).setDoubleValue(0);
    objModel.getNode("heading-deg-prop",1).setValue(objModel.getPath()~"/heading");
    objModel.getNode("pitch-deg-prop",1).setValue(objModel.getPath()~"/pitch");
    objModel.getNode("roll-deg-prop",1).setValue(objModel.getPath()~"/roll");

    objModel.getNode("path",1).setValue(path); # this is the model to be loaded.

    var loadNode = objModel.getNode("load", 1);
    loadNode.setBoolValue(1);
    loadNode.remove();
    objModel.getNode("latitude").setDoubleValue(lat);
    objModel.getNode("longitude").setDoubleValue(lon);
    objModel.getNode("elevation").setDoubleValue(ele);

    if (time) {
        append(model_exp,{
            n: objModel,
            t: systime() + time,
            });
    }
}

var model_timeout = func() {
    foreach (var m; model_exp) {
        if (m.t and systime() > m.t) {
            m.n.remove();
            m.t = 0;
            model_exp = mpdb.remove_from_array(model_exp, m);
        }
    }
}

var water_materials = {
    "Ocean": "water",
    "Lake": "water",
    "Pond": "water",
    "Reservoir": "water",
    "Stream": "water",
    "Canal": "water",
    "Lagoon": "water",
    "Estuary": "water",
    "Watercourse": "water",
    "Saline": "water",
    "DryLake": "water",
    "IntermittentReservoir": "water",
    "IntermittentLake": "water",
    "IntermittentStream": "water",
    "Marsh": "water",
    "FloodLand": "water",
    "SaltMarsh": "water",
};

############################# main init ###############

var main_init = func {
    setprop("sim/time/elapsed-at-init-sec", getprop("sim/time/elapsed-sec"));

    setprop("/consumables/fuel/tank[11]/jettisoned", FALSE);
    setprop("/consumables/fuel/tank[12]/jettisoned", FALSE);
    setprop("/consumables/fuel/tank[13]/jettisoned", FALSE);

    setlistener("/fdm/jsbsim/systems/armament/release", trigger_propogation);
    setlistener("/controls/armament/pickle", trigger_propogation);

    # pylon handling listeners

    setlistener("/payload/weight[0]/selected",func{update_pylons(0);});
    setlistener("/payload/weight[1]/selected",func{update_pylons(1);});
    setlistener("/payload/weight[2]/selected",func{update_pylons(2);});
    setlistener("/payload/weight[3]/selected",func{update_pylons(3);});
    setlistener("/payload/weight[4]/selected",func{update_pylons(4);});
    setlistener("/payload/weight[5]/selected",func{update_pylons(5);});
    setlistener("/payload/weight[6]/selected",func{update_pylons(6);});
    setlistener("/payload/virtual/weight[7]/selected",func{update_pylons(7);});
    setlistener("/payload/virtual/weight[8]/selected",func{update_pylons(8);});

    #setlistener("/controls/armament/cm-trigger",func{countermeasure_trigger();});

    # start loops
    spamLoop();
    armament_loop();
}

var main_init_listener = setlistener("sim/signals/fdm-initialized", func {
    main_init();
    removelistener(main_init_listener);
}, 0, 0);