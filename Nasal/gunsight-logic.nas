var TRUE = 1;
var FALSE = 0;

var pipper_gyro = {
    new: func() {
        var m = {parents: [pipper_gyro]};

        # USER INPUT VARIABLES

        m.timeStep = 0.1; #loop run rate
        
        m.z_offset = -4.69; # offset of the gun in feet from the sight line
        m.y_offset =  0.00; # offset of the gun in feet from the sight line
        m.gunElevation = 0.8*D2R; # elevation of the gun above alpha in radians
        m.ballisticCoefficient = 0.193; #ballistic coefficient of the projectile
        m.muzzleVelocity = 2350.0; #muzzle velocity of the projectile in feet per second
        m.harmonizationRange = 336.0; #gun zero range, feet either that or 3610
        m.range = 2500; # range to target, in feet (probably)
        m.maxElevation = 88.88; # max deflection in mils
        m.maxAzimuth = 88.88;
        m.dampingFactor = 0.85; #value between 0.3 and 1.0, with lower = more jitter

        m.gyroTimer = maketimer(m.timeStep,func(){m.gunGyroMain();});
        m.lastrunState = FALSE;

        m.P = props.globals.getNode("/orientation/p-body");
        m.Q = props.globals.getNode("/orientation/q-body");
        m.R = props.globals.getNode("/orientation/r-body");
        m.normalAcceleration = props.globals.getNode("/accelerations/pilot/z-accel-fps_sec");
        m.ambientTemprature = props.globals.getNode("/environment/temperature-degc");
        m.mach = props.globals.getNode("/velocities/mach");
        m.alpha = props.globals.getNode("/orientation/alpha-deg");
        m.dampingFactor = m.dampingFactor * 0.4;

        m.rangeRateArray = std.Vector.new([0,0,0,0]);

        m.gunGyroInit();
        return m;
    },

    gunGyroInit: func() {
        me.outputLA = 0; # azimuth in mils
        me.outputLE = 0; # elevation in mils

        me.SIG = me.dampingFactor * 0.4;
        me.KSIG = 1.0 / (1.0 + me.SIG);
        
        # other variables
        me.seaLevelAirDensity = 0.00238;
        me.KBRHO = me.ballisticCoefficient / me.seaLevelAirDensity;
        me.cosGunElevation = math.cos(me.gunElevation);
        me.sinGunElevation = math.sin(me.gunElevation);
        me.RRH = 1.0 / me.harmonizationRange;
        me.RHO = props.globals.getNode("/environment/density-slugft3");
        me.VLS = me.KBRHO * me.RHO.getValue() * math.sqrt(me.muzzleVelocity) * me.range;
        me.rangeRate = 0;
        me.VOS = me.muzzleVelocity + me.VLS + me.rangeRate;
        me.VCM = math.sqrt(me.VOS * me.VOS - 4.0 * me.rangeRate * me.VLS);
        
        me.RDC = 0;
        me.LA = 0;
        me.LE = 0;

        me.tasfeet = 0;
        
        #other variables used later
        me.oldRange = 0;
        me.rangeRate = 0;
    },

    getRangeRate: func() {
        me.oldRange = me.range;
        #me.getRange();
        pop(me.rangeRateArray.vector);
        me.rangeRateArray.insert(0, (me.oldRange - me.range) / me.timeStep);
        me.rangeRate = (me.rangeRateArray.vector[0] + me.rangeRateArray.vector[1] + me.rangeRateArray.vector[2] + me.rangeRateArray.vector[3]) / 4;
    },
    
    getAzimuthAndElevation: func() {
        me.getRangeRate();
        me.tasFeet = 1.68781 * (661.47 * me.mach.getValue() * math.sqrt((me.ambientTemprature.getValue() + 273.15) / 288.15)); # true airspeed in feet
        me.totalInitialVelocity = me.tasFeet + me.muzzleVelocity;
        me.SQRV = math.sqrt(me.tasFeet + me.totalInitialVelocity);        
        me.SLA = me.LA * (1.0 - 0.16667 * me.LA * me.LA);
        me.SLE = me.LE * (1.0 - 0.16667 * me.LE * me.LE);
        me.CLE = 1.0 - (me.LE * me.LE) / 2;
        me.CLA = 1.0 - (me.LA * me.LA) / 2;
        me.RCOS = 1.0 / (me.CLA * me.CLE);
        me.RDE = (me.rangeRate - me.RDC * me.SLE) * me.RCOS;

        # worse comes to worse, limit RDC to 2,000,000,000 or something
        # RDC feeds RDE, which feeds averageRelativeVelocity, which feeds RDC, repeat
        
        me.VLS = me.KBRHO * me.RHO.getValue() * (me.range * me.RCOS) * (0.5 * (me.SQRV + (me.tasFeet + me.totalInitialVelocity)/me.SQRV));
        me.VOS = me.totalInitialVelocity - me.RDE - me.VLS;

        me.RDE = me.rangeRate;
        me.VCM = 0.5 * (me.VCM + (me.VOS * me.VOS - 4.0 * (me.tasFeet + me.RDE) * me.VLS) / me.VCM);

        me.VE = 0.5 * (me.VOS + me.VCM);
        me.recipricalTimeOfFlight = me.VE / (me.range * me.RCOS);

        me.averageRelativeVelocity = me.VE + me.RDE;

        me.VN = me.averageRelativeVelocity - me.SIG * me.RDE * me.VLS * (me.averageRelativeVelocity + me.tasFeet)/(me.VCM * me.averageRelativeVelocity);
        me.PG = me.P.getValue() * me.cosGunElevation - me.R.getValue() * me.sinGunElevation;
        me.RG = me.P.getValue() * me.sinGunElevation + me.R.getValue() * me.cosGunElevation;
        
        me.RDC = me.tasFeet * ((me.alpha.getValue() * D2R) + me.gunElevation) * 
            (me.totalInitialVelocity - me.averageRelativeVelocity) / 
            (me.tasFeet + me.totalInitialVelocity) + 
            0.5 * me.normalAcceleration.getValue() / me.recipricalTimeOfFlight;

            #print("tasf " ~ me.tasFeet ~ " | alpha " ~ (me.alpha.getValue()) ~ " | gunelev " ~ me.gunElevation ~ " | tIV " ~ me.totalInitialVelocity ~ " | aRV " ~ me.averageRelativeVelocity ~ " | norm " ~ (me.normalAcceleration.getValue()) ~ " | rtof " ~ me.recipricalTimeOfFlight);
            
        # WJ and WK are computed sight line angular rates
        me.WK = ((1.0 - me.range * me.RRH) * me.y_offset * me.CLA * me.recipricalTimeOfFlight - me.VN * me.SLA) * (1.0 / me.range);
        me.WJ = ((me.RDC - (1.0 - me.range * me.RRH) * me.z_offset * me.recipricalTimeOfFlight) * me.CLE - me.VN * me.CLA * me.SLE) * (1.0 / me.range);
        me.LED = (me.WJ + me.SLA * me.PG - me.CLA * me.Q.getValue()) * me.KSIG;
        me.LAD = ((me.WK - me.SLE * (me.CLA * me.PG + me.SLA * me.Q.getValue())) / me.CLE -me.RG) * me.KSIG;
        
        me.LA = me.LA + me.LAD * me.timeStep;
        me.LE = me.LE + me.LED * me.timeStep;
    },
    
    gunGyroReInit: func() {
        # there is a race condition in there that i cant track down, this should limit things i hope
        # this race condition was also an issue in the original file
        print('reiniting gun gyro');
        me.gunGyroInit();
        #print("LA: " ~ me.LA ~ " | LE: " ~ me.LE);
    },

    getAzimuth: func() {
		call(func() {setprop("/instrumentation/gunsight/pipper-gyro-prop-test", me.outputLA);}, nil, var Lerr = []);
		if (size(Lerr))	{
            me.gunGyroReInit();
			return 0;
		} else {
    		return me.outputLA;
    	}
    },

    getElevation: func() {
		call(func() {setprop("/instrumentation/gunsight/pipper-gyro-prop-test", me.outputLE);}, nil, var Lerr = []);
		if (size(Lerr)) {
            me.gunGyroReInit();
			return 0;
		} else {
    		return me.outputLE;
    	}
    },

    gunGyroMain: func() {
    	if (me.gyroTimer.isRunning == FALSE) {
    		me.gyroTimer.start();
    	}
        if (TRUE) {
        	if (me.lastrunState = FALSE){
        		me.gunGyroReInit();
                me.LA = 0;
                me.LE = 0;
        	}
            me.getAzimuthAndElevation();
            me.outputLA = math.clamp(me.LA,-me.maxAzimuth/1000,me.maxAzimuth/1000);
            me.outputLE = math.clamp(me.LE,-me.maxElevation/1000,me.maxElevation/1000);
            print("PINTO -- LA: " ~ me.outputLA ~ " | LE: " ~ me.outputLE);
        	me.lastrunState = TRUE;

            #set tempLA as azimuth amount
            #set tempLE as elevation amount
            #output is in mils
            # 1 mil = 0.05625 degrees
        } else {
        	me.lastrunState = FALSE;
        }
    },
}

# redo

var AFALCOS = {
    new: func() {
        var m = {parents: [AFALCOS]};
        m.P = 0;    # p, q, r are body angular rates in radians per second
        m.Q = 0;
        m.R = 0;
        m.D = 0;    # range to target in feet
        m.DDOT = 0; # delta of range to target in feet per second
        m.VA = 0;   # aircraft speed in ft/sec
        m.AX = 0;   # aircraft accelerations in ft/sec^2
        m.AY = 0;
        m.AZ = 0;
        m.AL = 0;   # aircraft angle of attack in radians, pos for pos load factor
        m.GA = 0;   # gun angle in radians down from x axis(?)
        m.DT = 0;   # integration step size in seconds
        m.FTIME = 0;    #final time in seconds
        m.HA = 0;   # altitude in feet
        m.VM = 0;   # muzzle speed in feet per second

        ## other stuff
        m.ALA = 0;
        m.ELA = 0;
        m.T = 0;
    },
    update: func() {
        if (me.HA > 36000) {
            me.DH = HA - 36000;
            me.RHO = math.pow((0.018828 + (0.039227E-10 * me.DH - 0.043877E-5 ) * me.DH),2) * 2;
        } else {
            me.RHO = math.pow((0.034475 + (0.019213E-10 * me.HA - 0.050381E-5 ) * me.HA),2) * 2;
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
        me.C7 = me.TF * me.D * me.P / 2.0 / me.C6;
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
        me.W2 = me.W2 + (-me.SL1 * me.SL3 + me.C7 * me.SL3) * me.P + 
                (1.0 - math.pow(me.SL2,2)) * me.Q - 
                (me.SL2 * me.SL3 + me.C7 * me.SL1) * me.R;
        me.W3 = me.W3 - (me.SL1 * me.SL3 + me.C7 * me.SL2) * me.P + 
                (-me.SL2 * me.SL3 + me.C7 * me.SL1) * me.Q + 
                (1.0 - math.pow(me.SL3,2)) * me.R;
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


    }
}