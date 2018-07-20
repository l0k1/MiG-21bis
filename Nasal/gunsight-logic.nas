# AFALCOS - lead computing optical sight

var MIL2DEG =  0.05625;
var DEG2MIL = 17.77778;
var RAD2MIL = 1018.591636;
var MIL2RAD = 0.00098174770424681;

var interp = func(x, x0, x1, y0, y1) {
    return y0 + (x - x0) * ((y1 - y0) / (x1 - x0));
}

### MiG-21 specific variables for the ASP-PFD gunsight

var gun_rkt_switch = props.globals.getNode("controls/armament/gunsight/gun-missile-switch");
var shoot_bomb_switch = props.globals.getNode("controls/armament/gunsight/pipper-mode-select-switch");
var auto_man_switch = props.globals.getNode("/controls/armament/gunsight/auto-man-switch");
var throttle_drum = props.globals.getNode("/controls/armament/gunsight/throttle-drum");
var lock_bars_pos = props.globals.getNode("controls/radar/lock-bars-pos");
var pipper_scale = props.globals.getNode("/controls/armament/gunsight/pipper-scale");
var angle_setting_pre = props.globals.getNode("/controls/armament/gunsight/angle-setting-prefilter");
var angle_setting_post = props.globals.getNode("/controls/armament/gunsight/angle-setting-postfilter");
var angle_motorcontrol = props.globals.getNode("/controls/armament/gunsight/angle-setting-motorcontrol");
var span_prop = props.globals.getNode("/controls/armament/gunsight/target-size-knob");
var knobpos = props.globals.getNode("controls/armament/panel/pylon-knob");
var gyroMslSwitch = props.globals.getNode("controls/armament/gunsight/pipper-accuracy-switch");
var damper = props.globals.getNode("controls/armament/gunsight/damping");
var distance_scale = props.globals.getNode("controls/armament/gunsight/scale-dial-prefilter");
var missile_scale = props.globals.getNode("controls/armament/gunsight/missile-scale-prefilter");
var gunsight_power = props.globals.getNode("fdm/jsbsim/electric/output/gunsight");
var air_gnd_switch = props.globals.getNode("controls/armament/panel/air-gnd-switch");
var lock_light = props.globals.getNode("controls/armament/gunsight/lock-light");
var launch_light = props.globals.getNode("controls/armament/gunsight/launch-light");
var breakoff_light = props.globals.getNode("controls/armament/gunsight/breakoff-light");

var min_drum = 0;
var max_drum = 1;
var min_pip = 5; # radius in mils
var max_pip = 40; # radius in mils
var min_gate = 0; # in px
var max_gate = 473; # in px

###

var AFALCOS = {
    # returns lead angles in mils
    
    new: func() {
        var m = {parents: [AFALCOS]};
        m.GA = 0.1;   # gun angle in radians (pos is up) - should be set in wrapper class
        m.VM = 2350.0;   # muzzle speed in feet per second
        m.DT = 0.05;   # integration step size in seconds (loop update rate)
        m.GAIN = 1.5; #sight sensitivity parameter - 0.8 nominally
        m.HUDY = 0; # sorta educated guess: y distance from gun to hud
        m.HUDZ = 4.69; # sorta educated guess: z distance from gun to hud

        m.maxAz = 7; # in degrees
        m.maxEl = 7; # in degrees
        
        m.gyroTimer = maketimer(m.DT,func(){m.update();});
        
        # properties
        # p, q, r are body angular rates in radians per second
        m.AX = props.globals.getNode("/accelerations/pilot/x-accel-fps_sec");   # aircraft accelerations in ft/sec^2
        m.AY = props.globals.getNode("/accelerations/pilot/y-accel-fps_sec");
        m.AZ = props.globals.getNode("/accelerations/pilot/z-accel-fps_sec");
        m.P =  props.globals.getNode("/orientation/p-body");
        m.Q =  props.globals.getNode("/orientation/q-body");
        m.R =  props.globals.getNode("/orientation/r-body");
        m.HA = props.globals.getNode("/position/altitude-ft");
        m.ALprop = props.globals.getNode("/orientation/alpha-deg");
        m.ambientTemprature = props.globals.getNode("/environment/temperature-degc");
        m.mach = props.globals.getNode("/velocities/mach");

        ## other stuff
        m.VA = 0;   # aircraft speed in ft/sec
        m.ALA = 0;
        m.ELA = 0;
        m.ALAH = 0;
        m.ELAH = 0;
        m.AL = 0;
        m.rangeRateArray = std.Vector.new([0,0,0,0]);
        me.oldRange = 0;
        m.DDOT = 0; # delta of range to target in feet per second
        m.D = 0;    # range to target in feet
        
        m.GAINdamp = 1;
        m.gyroDamage = [1,1,1];
        m.gyroEnable = 1;
        
        m.gyroTimer.start(); # should be moved into a better control loop later

        return m;
    },
    
    update: func() {
        #me.updateRange();
        me.updateRangeRate();
        me.AL = me.ALprop.getValue() * D2R;
        math.clamp(me.AL,-45,45);
        
        me.VA = 1.68781 * (661.47 * me.mach.getValue() * math.sqrt((me.ambientTemprature.getValue() + 273.15) / 288.15)); # true airspeed in feet
        
        if (me.HA.getValue() > 36000) {
            me.DH = HA.getValue() - 36000;
            me.RHO = math.pow((0.018828 + (0.039227E-10 * me.DH - 0.043877E-5 ) * me.DH),2) * 2;
        } else {
            me.RHO = math.pow((0.034475 + (0.019213E-10 * me.HA.getValue() - 0.050381E-5 ) * me.HA.getValue()),2) * 2;
        }

        me.D = me.D == 0 ? 1 : me.D;
        
        me.DRATIO = me.RHO / 0.00238;
        me.VP = me.VM + me.VA;
        me.KB = 0.00614;
        me.VLS = me.D * me.KB * math.pow(me.VP,0.5) * me.DRATIO;
        me.VC = -me.DDOT;
        me.VOS = me.VM + me.VC - me.VLS;
        #print("VOS: " ~ me.VOS ~ "|VA: " ~ me.VA ~ "|VC: " ~ me.VC ~ "|VLS: " ~ me.VLS);
        me.VCMsub = math.pow(me.VOS,2) - 4 * (me.VA - me.VC) * me.VLS;
        me.VCM = math.pow(math.abs(me.VCMsub),0.5);
        me.VCM = me.VCMsub < 0 ? -me.VCM : me.VCM;
        me.RTF = 0.5 * (me.VOS + me.VCM) / me.D;
        me.TF = 1.0 / me.RTF;   #TF is bullet time of flight
        me.VF = me.D / me.TF - me.VC;
        me.JV = (me.VM - me.VF) / (me.VA + me.VM);
        me.B1 = math.cos(me.GA);    # B is the gunline unit vector in body coordinates
        me.B2 = 0.0;
        me.B3 = math.sin(me.GA);
        me.GAL = me.AL - me.GA; # GAL is the gun angle of attack
        me.C6 = me.D + me.DDOT + me.TF;
        me.C7 = me.TF * me.D * me._getP() / 2.0 / me.C6;
        #print("TF: " ~ me.TF ~ "|D: " ~ me.D ~ "|P: " ~ me._getP() ~ "|C6: " ~ me.C6);
        me.C1 = me.VF / me.C6;
        me.C2 = me.JV * me.VA / me.C6;
        me.C3 = me.TF / 2.0 / me.C6;
        me.BXAN2 = -me.B1 * me.AZ.getValue() + me.AX.getValue() * me.B3;
        me.BXAN3 = me.B1 * me.AY.getValue() - me.AX.getValue() * me.B2;
        me.SL1 = me.B1 + me.B2 * me.ALA - me.B3 * me.ELA; ### SL is sight line unit vector
        me.SL2 = me.B2 - me.B1 * me.ALA;
        me.SL3 = me.B3 + me.B1 * me.ELA;
        me.W2 = -me.C1 * me.ELA - me.C2 * me.GAL + me.C3 * 
                (me.BXAN2 - (me.AY.getValue() * me.ELA + me.AZ.getValue() * me.ALA) * me.B2 +
                (me.AX.getValue() * me.B1 + me.AY.getValue() * me.B2 + me.AZ.getValue() * me.B3) * me.ELA);
        me.W3 = -me.C1 * me.ALA + me.C3 * 
                (me.BXAN3 - (me.AY.getValue() * me.ELA + me.AZ.getValue() * me.ALA) * me.B3 +
                (me.AX.getValue() * me.B1 + me.AY.getValue() * me.B2 + me.AZ.getValue() * me.B3) * me.ALA);
        me.W2 = me.W2 + (-me.SL1 * me.SL3 + me.C7 * me.SL3) * me._getP() + 
                (1.0 - math.pow(me.SL2,2)) * me._getQ() - 
                (me.SL2 * me.SL3 + me.C7 * me.SL1) * me._getR();
        me.W3 = me.W3 - (me.SL1 * me.SL3 + me.C7 * me.SL2) * me._getP() + 
                (-me.SL2 * me.SL3 + me.C7 * me.SL1) * me._getQ() + 
                (1.0 - math.pow(me.SL3,2)) * me._getR();
        #print("C7: " ~ me.C7 ~ "|SL1: " ~ me.SL1);
        me.C5 =  me.C7 * me.SL1;
        #print("SL2: " ~ me.SL2 ~ "|SL3: " ~ me.SL3 ~ "|C5: " ~ me.C5);
        me.DET = 1.0 - math.pow(me.SL2,2) - math.pow(me.SL3,2) + math.pow(me.C5,2);
        me.AINVW2 = ((1.0 - math.pow(me.SL3,2)) * me.W2 + (me.SL2 * me.SL3 + me.C5) * me.W3) / me.DET;
        me.AINVW3 = ((me.SL2 * me.SL3 - me.C5) * me.W2 + (1.0 - math.pow(me.SL2,2)) * me.W3) / me.DET;
        me.DELA = me.getGain() * me.AINVW2;
        me.DALA = me.getGain() * me.AINVW3;
        me.ELA = damper.getValue() == 1 ? me.ELA / 1.1 : me.ELA + me.DT * me.DELA;
        me.ALA = damper.getValue() == 1 ? me.ALA / 1.1 : me.ALA + me.DT * me.DALA;
        #me.ELA = me.ELA + me.DT * me.DELA;  #ELA and ALA are EL and AZ lead angle components w.r.t. gun
        #me.ALA = me.ALA + me.DT * me.DALA;
        me.ELAB = me.B1 * me.ELA;   # ELAB and ALAB are EL and AZ lead angles in body coordinates
        me.ALAB = me.B1 * me.ALA;
        me.ELAH = -(me.ELA - me.HUDZ / (me.VF * me.TF) + me.GA) * 1000; # hud EL in mils
        me.ALAH = -(me.ALA - me.HUDY / (me.VF * me.TF)) * 1000;         # hud AZ in mils
    },
    
    updateRange: func() {
        #disabling this for now
        return;
    },
    
    updateRangeRate: func() {
        me.oldRange = me.D;
        pop(me.rangeRateArray.vector);
        me.rangeRateArray.insert(0, (me.oldRange - me.D) / me.DT);
        me.DDOT = (me.rangeRateArray.vector[0] + me.rangeRateArray.vector[1] + me.rangeRateArray.vector[2] + me.rangeRateArray.vector[3]) / 4;
    },
    
    getAzimuth: func() {
        return math.clamp(me.ALAH,-me.maxAz * DEG2MIL, me.maxAz * DEG2MIL);
    },
    
    getElevation: func() {
        return math.clamp(-me.ELAH,-me.maxEl * DEG2MIL, me.maxEl * DEG2MIL);
    },
    
    setGyroEnable: func(val) {
        # 1 is enable, 0 is disable
        me.gyroEnable = math.clamp(math.floor(val),0,1);;
    },
    
    setGyroDamage: func(body, amount, absolute = 1) {
        # damage of 0 means gyro is nonfunctioning
        # damage of 1 means gyro is functioning normally
        # damage of 2 means gyro is returning oversensitive
        # body == 0 is P, 1 is Q, and 2 is R
        if (absolute) {
            me.gyroDamage[body] = amount;
        } else {
            me.gyroDamage[body] = me.gyroDamage[body] + amount;
        }
        math.clamp(me.gyroDamage[body],0,1);
    },
    
    getGain: func() {
        return me.GAIN * me.GAINdamp;
    },
    
    setGain: func(val) {
        me.GAIN = math.clamp(val,0.4,5.0);
    },
    
    setGainDamp: func(val) {
        me.GAINdamp = val;
    },
    
    gainUndamp: func() {
        me.GAINdamp = 1;
    },
    
    ### internal functions
    _getP: func() {
        return me.P.getValue() * me.gyroDamage[0] * (me.gyroEnable == 0 ? 0.3333 : 1) * (gunsight_power.getValue() > 32 ? 1 : 0);
    },
    
    _getQ: func() {
        return me.Q.getValue() * me.gyroDamage[1] * (me.gyroEnable == 0 ? 0.3333 : 1) * (gunsight_power.getValue() > 32 ? 1 : 0);
    },
    
    _getR: func() {
        return me.R.getValue() * me.gyroDamage[2] * (me.gyroEnable == 0 ? 0.3333 : 1) * (gunsight_power.getValue() > 32 ? 1 : 0);
    },
};

# mig-21 specific stuff

#todo: when a bomb/rkt or gun/shoot switch is flipped, set /controls/armament/gunsight/angle-setting-prefilter to desired angle and /controls/armament/gunsight/angle-setting-motorcontrol to 1

var asp_pfd = {
    new: func() {
        var m = {parents:[asp_pfd]};
        # gyro object
        m.lcos = AFALCOS.new();
        m.span = m.updateSpan();

        # listeners
        #m.pipperListener = setlistener(m.pipper_scale.getPath(), func() {m.updatePipperScale});
        m.angleListener = setlistener(angle_setting_post.getPath(), func() {m.updateAngle();});
        m.spanListener = setlistener(span_prop.getPath(),func() {m.updateSpan();});
        m.throttleDrumListener = setlistener(throttle_drum.getPath(),func() {m.updateSpan();});
        m.gunRktListener = setlistener(gun_rkt_switch.getPath(),func(){m.setAutoAngle();});
        m.shootBombListener = setlistener(shoot_bomb_switch.getPath(),func(){m.setAutoAngle();});
        m.weaponknobListener = setlistener(knobpos.getPath(),func(){m.setAutoAngle();});
        m.gyroMslListener = setlistener(gyroMslSwitch.getPath(), func(){m.setGyroMsl();});
        m.setAutoAngle();
        m.update();
        return m;
    },

    update: func() {
        #the scales in the middle of the gunsight (afaik):
        #if in 300m mode, display mils
        #if in gun, display range per second highest scale
        #if in rkt/msl, use second lowest scale
        #if in rkt/rkt, use lowest scale
        #distance_scale.setValue()
        
        if (throttle_drum.getValue() <= 0) {
            me.lcos.D = 300 * M2FT;
            # determine angle = arctan(opp/adj) = arctan((span/2)/distance) = atan2(y,x)
            # multiply by 1000 to change to mils
            # remember pipper_scale is radius, not diameter.
            pipper_scale.setValue(math.clamp(math.atan2(me.span / 2,(me.lcos.D*FT2M)) * RAD2MIL, min_pip, max_pip));
        } else {
            if (auto_man_switch.getValue()) {
                # manual mode, determine distance via pipperscale
                me.lcos.D = (me.span / 2) / math.tan((pipper_scale.getValue() * MIL2RAD)) * M2FT;
            } else {
                # auto mode
                if(radar_logic.selection != nil and arm_locking.lock_mode == "radar") {
                    me.lcos.D = radar_logic.selection.get_polar()[0] * M2FT;
                } else {
                    me.lcos.D = 600 * M2FT;
                }
                # determine angle = arctan(opp/adj) = arctan(span/distance)
                # remember pipper_scale is radius, not diameter.
                pipper_scale.setValue(math.clamp(math.atan2(me.span / 2,(me.lcos.D*FT2M)) * RAD2MIL, min_pip, max_pip));
            }

            #missile scale logic
            if(radar_logic.selection != nil and arm_locking.lock_mode == "radar" and gunsight_power.getValue() > 32) {
                missile_scale.setValue(math.clamp(interp(radar_logic.selection.get_polar()[0],2000,5000,0,1),0,1));
            } else {
                missile_scale.setValue(0);
            }

        }

        #distance scale logic
        if (throttle_drum.getValue() > 0 and gunsight_power.getValue() > 32) {
            if (shoot_bomb_switch.getValue() == 0 and gun_rkt_switch.getValue() and knobpos.getValue() > 4) {
                distance_scale.setValue(math.clamp(interp(me.lcos.D * FT2M,0,8000,0,1),0,1));
            } elsif (throttle_drum.getValue() > 0) {
                distance_scale.setValue(math.clamp(interp(me.lcos.D * FT2M,400,2000,0,1),0,1));
            }
        } elsif (gunsight_power.getValue() > 32) {
            distance_scale.setValue(math.clamp(interp(pipper_scale.getValue(),min_pip,max_pip,0,1),0,1));
        } else {
            distance_scale.setValue(0);
        }
    
        #breakoff light logic
        if (air_gnd_switch.getValue() == 2 and gunsight_power.getValue() > 32) {
            if (me.lcos.D < (1950 * M2FT)) {
                launch_light.setValue(1);
            } else {
                launch_light.setValue(0);
            }
            if (shoot_bomb_switch.getValue() == 0) {
                if (gun_rkt_switch.getValue() == 0 and me.lcos.D < (1200 * M2FT)) {
                    breakoff_light.setValue(1);
                } elsif (gun_rkt_switch.getValue() and ((knobpos.getValue() <=2 and me.lcos.D < (1200 * M2FT)) or (knobpos.getValue() > 2 and knobpos.getValue() < 5 and me.lcos.D < (1600 * M2FT)))) {
                    breakoff_light.setValue(1);
                } else {
                    breakoff_light.setValue(0);
                }
            }
        }
        
        if (radar_logic.selection != nil and arm_locking.lock_mode == "radar" and gunsight_power.getValue() > 32) {
            lock_light.setValue(1);
        }else{
            lock_light.setValue(0);
        }
                
                
        
        #print("D: " ~ me.lcos.D);
        settimer(func(){me.update();},0.05);
    },


    updateAngle: func() {
        me.lcos.GA = angle_setting_post.getValue() * D2R; # the angle_setting is ran through a jsbsim instrument kinematic for smoothness
    },

    setAutoAngle: func() {
        #print('setting auto angle');
        if (gunsight_power.getValue() < 32) {
            #print('not enough power');
            return;
        }
        me.lcos.VM = 2350.0;   # muzzle speed in feet per second
        if (auto_man_switch.getValue() == 0) {
            # automode == 0, manmode == 1
            if (shoot_bomb_switch.getValue()) {
                #switch set to bomb
                angle_setting_pre.setValue(0); # totally fictional, no idea what this should be
                me.lcos.VM = 250.0;   # muzzle speed in feet per second
            } else {
                #switch set to shoot
                if (gun_rkt_switch.getValue()) {
                    #switch set to rkt
                    #angle based off of knobpos
                    if (knobpos.getValue() <= 2) {
                        # s-5 rocket
                        angle_setting_pre.setValue(1.7);
                    } elsif (knobpos.getValue() <= 4) {
                        # s-24 rocket
                        angle_setting_pre.setValue(2.1);
                    } else {
                        # missile
                        angle_setting_pre.setValue(0.0);
                    }

                } else {
                    #switch set to gun
                    angle_setting_pre.setValue(0.8);
                }
            }
            angle_motorcontrol.setValue(1);
        }
    },

    updateSpan: func() {
        if( throttle_drum.getValue() <= 0 ) {
            if (span_prop.getValue() < 2 ) {
                me.span = interp(span_prop.getValue(),0,2,7,9);
            } else {
                me.span = interp(span_prop.getValue(),2,10,9,27);
            }
        }else{
            me.span = interp(span_prop.getValue(),0,10,2,80);
        }
        #print(me.span);
    },

    updatePipperScale: func() {
        # scale is radius in mils, measured from outside diamond edge
        # minimum diameter of 22 mils
        if (me.pipper_scale.getValue() < 11) {
            me.pipper_scale.setValue(11);
        }
    },

    setGyroMsl: func() {
        me.lcos.setGyroEnable(gyroMslSwitch.getValue() * -1 + 1); 
        print(me.lcos.gyroEnable);
    },

    getAzimuth: func() {
        #print("A:" ~ me.lcos.getAzimuth());
        return me.lcos.getAzimuth();
    },
    
    getElevation: func() {
        #print("E:" ~ me.lcos.getElevation());
        return me.lcos.getElevation();
    },

};

setlistener(throttle_drum.getPath(),func(){
# if in auto mode, move radar lock bars
# if in manual mode, move pipper
    if (auto_man_switch.getValue()) {
        #manual mode
        pipper_scale.setValue(interp(throttle_drum.getValue(), min_drum, max_drum, max_pip, min_pip));
    } else {
        #auto mode
        lock_bars_pos.setValue(interp(throttle_drum.getValue(), min_drum, max_drum, min_gate, max_gate));
    }
});

setlistener(auto_man_switch.getPath(), func() {
    if (auto_man_switch.getValue()) {
        lock_bars_pos.setValue(0);
    } else {
        pipper_scale.setValue(0);
    }
});
