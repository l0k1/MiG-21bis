# AFALCOS - lead computing optical sight

var AFALCOS = {
    new: func() {
        var m = {parents: [AFALCOS]};

        m.GA = 0.8 * D2R;   # gun angle in radians down from x axis(?)
        m.VM = 2350.0;   # muzzle speed in feet per second
        m.DT = 0.1;   # integration step size in seconds (loop update rate)
        
        m.gyroTimer = maketimer(m.DT,func(){m.update();});
        
        # properties
        # p, q, r are body angular rates in radians per second
        m.AX = 0;   # aircraft accelerations in ft/sec^2
        m.AY = 0;
        m.AZ = 0;
        m.P =  props.globals.getNode("/orientation/p-body");
        m.Q =  props.globals.getNode("/orientation/q-body");
        m.R =  props.globals.getNode("/orientation/r-body");
        m.HA = props.globals.getNode("/position/altitude-ft");
        m.AL = 0;
        m.ALprop = props.globals.getNode("/orientation/alpha-deg");
        m.ambientTemprature = props.globals.getNode("/environment/temperature-degc");
        m.mach = props.globals.getNode("/velocities/mach");

        ## other stuff
        m.VA = 0;   # aircraft speed in ft/sec
        m.ALA = 0;
        m.ELA = 0;
        m.T = 0;        
        m.rangeRateArray = std.Vector.new([0,0,0,0]);
        me.oldRange = 0;
        m.DDOT = 0; # delta of range to target in feet per second
        m.D = 0;    # range to target in feet
        
        m.gyroTimer.start(); # should be moved into a better control loop later
    },
    
    update: func() {
        me.updateRange();
        me.updateRangeRate();
        me.AL = me.ALprop.getValue() * D2R;
        math.clamp(me.AL,-45,45);
        
        me.VA = 1.68781 * (661.47 * me.mach.getValue() * math.sqrt((me.ambientTemprature.getValue() + 273.15) / 288.15)); # true airspeed in feet
        
        if (me.HA.getValue(); > 36000) {
            me.DH = HA.getValue() - 36000;
            me.RHO = math.pow((0.018828 + (0.039227E-10 * me.DH - 0.043877E-5 ) * me.DH),2) * 2;
        } else {
            me.RHO = math.pow((0.034475 + (0.019213E-10 * me.HA.getValue() - 0.050381E-5 ) * me.HA.getValue()),2) * 2;
        }
        
        me.DRATIO = me.RHO / 0.00238;
        me.VP = me.VM + me.VA;
        me.KB = 0.00614;
        me.VLS = me.D * me.KB * math.pow(me.VP,0.5) * me.DRATIO;
        me.VC = -me.DDOT;
        me.VOS = me.VM + me.VC - me.VLS;
        me.VCM = math.pow(math.pow(me.VOS,2) - 4 * (me.VA - me.VC) * me.VLS,0.5);
        me.RTF = 0.5 * (me.VOS + me.VCM) / me.D;
        me.TF = 1.0 / me.RTF;   #TF is bullet time of flight
        me.VF = me.D / me.TF - me.VC;
        me.JV = (me.VM - me.VF) / (me.VA + me.VM);
        me.B1 = math.cos(me.GA);    # B is the gunline unit vector in body coordinates
        me.B2 = 0.0;
        me.B3 = math.sin(me.GA);
        me.GAL = me.AL - me.GA; # GAL is the gun angle of attack
        me.C6 = me.D + me.DDOT + me.TF;
        me.C7 = me.TF * me.D * me.P.getValue() / 2.0 / me.C6;
        me.C1 = me.VF / me.C6;
        me.C2 = me.JV * me.VA / me.C6;
        me.C3 = me.TF / 2.0 / me.C6;
        me.BXAN2 = -me.B1 * me.AZ + me.AX * me.B3;
        me.BXAN3 = me.B1 * me.AY - me.AX * me.B2;
        me.SL1 = me.B1 + me.B2 * me.ALA - me.B3 * me.ELA; ### SL is sight line unit vector
        me.SL2 = me.B2 - me.B1 * me.ALA;
        me.SL3 = me.B3 + me.B1 * me.ELA;
        me.W2 = -me.C1 * me.ELA - me.C2 * me.GAL + me.C3 * 
                (me.BXAN2 - (me.AY * me.ELA + me.AZ * me.ALA) * me.B2 +
                (me.AX * me.B1 + me.AY * me.B2 + me.AZ * me.B3) * me.ELA);
        me.W3 = -me.C1 * me.ALA + me.C3 * 
                (me.BXAN3 - (me.AY * me.ELA + me.AZ * me.ALA) * me.B3 +
                (me.AX * me.B1 + me.AY * me.B2 + me.AZ * me.B3) * me.ALA);
        me.W2 = me.W2 + (-me.SL1 * me.SL3 + me.C7 * me.SL3) * me.P.getValue() + 
                (1.0 - math.pow(me.SL2,2)) * me.Q.getValue() - 
                (me.SL2 * me.SL3 + me.C7 * me.SL1) * me.R.getValue();
        me.W3 = me.W3 - (me.SL1 * me.SL3 + me.C7 * me.SL2) * me.P.getValue() + 
                (-me.SL2 * me.SL3 + me.C7 * me.SL1) * me.Q.getValue() + 
                (1.0 - math.pow(me.SL3,2)) * me.R.getValue();
        me.C5 =  me.C7 * me.SL1;
        me.DET = 1.0 - math.pow(me.SL2,2) - math.pow(me.SL3,2) + math.pow(me.C5,2);
        me.AINVW2 = ((1.0 - math.pow(me.SL3,2)) * me.W2 + (me.SL2 * me.SL3 + me.C5) * me.W3) / me.DET;
        me.AINVW3 = ((me.SL2 * me.SL3 - me.C5) * me.W2 + (1.0 - math.pow(me.SL2,2)) * me.W3) / me.DET;
        me.DELA = me.GAIN * me.AINVW2;
        me.DALA = me.GAIN * me.AINVW3;
        me.ELA = me.ELA + me.DT * me.DELA;  #ELA and ALA are EL and AZ lead angle components w.r.t. gun
        me.ALA = me.ALA + me.DT * me.DALA;
        me.T = me.T + me.DT;    # may not need this?
        me.ELAB = me.B1 * me.ELA;   # ELAB and ALAB are EL and AZ lead angles in body coordinates
        me.ALAB = me.B1 * me.ALA;
        me.ELAH = -(me.ELA - me.HUDZ / (me.VF * me.TF) + me.GA) * 1000; # hud EL in mils
        me.ALAH = -(me.ALA - me.HUDY / (me.VF * me.TF)) * 1000;         # hud AZ in mils
        settimer(func(){me.update();},me.DT);
    },
    
    updateRange: func() {
        #need range in feet
        me.D = 2000;
    },
    
    updateRangeRate: func() {
        me.oldRange = me.D;
        pop(me.rangeRateArray.vector);
        me.rangeRateArray.insert(0, (me.oldRange - me.D) / me.DT);
        me.DDOT = (me.rangeRateArray.vector[0] + me.rangeRateArray.vector[1] + me.rangeRateArray.vector[2] + me.rangeRateArray.vector[3]) / 4;
    },
}