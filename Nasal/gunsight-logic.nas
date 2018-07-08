var TRUE = 1;
var FALSE = 0;

var pipper_gyro = {
    new: func() {
        var m = {parents: [pipper_gyro]};

        # USER INPUT VARIABLES

        m.timeStep = 0.1; #loop run rate
        
        m.z_offset = -4.69; # offset of the gun in feet from the sight line
        m.y_offset = -3.58; # offset of the gun in feet from the sight line
        m.gunElevation = 0.8*D2R; # elevation of the gun above alpha in radians
        m.ballisticCoefficient = 0.193; #ballistic coefficient of the projectile
        m.muzzleVelocity = 2350.0; #muzzle velocity of the projectile in feet per second
        m.harmonizationRange = 3610; #gun zero range, feet
        m.range = 2500; # range to target, in feet (probably)
        m.maxElevation = 88.88; # max deflection in mils
        m.maxAzimuth = 88.88;
        m.dampingFactor = 0.85; #value between 0.3 and 1.0, with lower = more jitter

        # END USER INPUT VARIABLES

        m.gyroTimer = maketimer(m.timeStep,func(){m.gunGyroMain();});
        m.lastrunState = FALSE;
        m.outputLA = 0; # azimuth in mils
        m.outputLE = 0; # elevation in mils

        m.SIG = m.dampingFactor * 0.4;
        m.KSIG = 1.0 / (1.0 + m.SIG);
        
        # other variables
        m.seaLevelAirDensity = 0.00238;
        m.KBRHO = m.ballisticCoefficient / m.seaLevelAirDensity;
        m.cosGunElevation = math.cos(m.gunElevation);
        m.sinGunElevation = math.sin(m.gunElevation);
        m.RRH = 1.0 / m.harmonizationRange;
        m.RHO = props.globals.getNode("/environment/density-slugft3");
        m.VLS = m.KBRHO * m.RHO.getValue() * math.sqrt(m.muzzleVelocity) * m.range;
        m.rangeRate = 0;
        m.VOS = m.muzzleVelocity + m.VLS + m.rangeRate;
        m.VCM = math.sqrt(m.VOS * m.VOS - 4.0 * m.rangeRate * m.VLS);
        
        m.RDC = 0;
        m.LA = 0;
        m.LE = 0;
        
        # acceleration variables
        m.P = props.globals.getNode("/orientation/p-body");
        m.Q = props.globals.getNode("/orientation/q-body");
        m.R = props.globals.getNode("/orientation/r-body");
        m.normalAcceleration = props.globals.getNode("/accelerations/pilot/z-accel-fps_sec");

        # TAS variables
        m.ambientTemprature = props.globals.getNode("/environment/temperature-degc");
        m.mach = props.globals.getNode("/velocities/mach");
        m.tasfeet = 0;
        
        m.alpha = props.globals.getNode("/orientation/alpha-deg");
        
        #other variables used later
        m.oldRange = 0;
        m.rangeRateArray = std.Vector.new([0,0,0,0]);
        m.rangeRate = 0;
        return m;
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
            
        # WJ and WK are computed sight line angular rates
        me.WK = ((1.0 - me.range * me.RRH) * me.y_offset * me.CLA * me.recipricalTimeOfFlight - me.VN * me.SLA) * (1.0 / me.range);
        me.WJ = ((me.RDC - (1.0 - me.range * me.RRH) * me.z_offset * me.recipricalTimeOfFlight) * me.CLE - me.VN * me.CLA * me.SLE) * (1.0 / me.range);
        me.LED = (me.WJ + me.SLA * me.PG - me.CLA * me.Q.getValue()) * me.KSIG;
        me.LAD = ((me.WK - me.SLE * (me.CLA * me.PG + me.SLA * me.Q.getValue())) / me.CLE -me.RG) * me.KSIG;
        
        me.LA = me.LA + me.LAD * me.timeStep;
        me.LE = me.LE + me.LED * me.timeStep;
    },
    
    gunGyroReInit: func() {
        me.LA = 0;
        me.LE = 0;
    },

    getAzimuth: func() {
    	return me.outputLA;
    },

    getElevation: func() {
    	return me.outputLE;
    },

    gunGyroMain: func() {
    	if (me.gyroTimer.isRunning == FALSE) {
    		me.gyroTimer.start();
    	}
        if (TRUE) {
        	if (me.lastrunState = FALSE){
        		me.gunGyroReInit();
        	}
            me.getAzimuthAndElevation();
            me.outputLA = math.clamp(me.LA,-me.maxAzimuth/1000,me.maxAzimuth/1000);
            me.outputLE = math.clamp(me.LE,-me.maxElevation/1000,me.maxElevation/1000);
            print("LA: " ~ me.outputLA ~ " | LE: " ~ me.outputLE);
        	me.lastrunState = TRUE;

            #set tempLA as azimuth amount
            #set tempLE as elevation amount
            #output is in mils
            # 1 mil = 0.05625 degrees
        } else {
        	me.lastrunState = FALSE
        }
    },
}