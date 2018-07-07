

var pipper_control = {
    new: func() {
        var m = {parents: [pipper_control]};
        
        # gun variables
        m.z_offset = 0; # offset of the gun in feet from the sight line
        m.y_offset = 0; # offset of the gun in feet from the sight line
        m.gunElevation = 0; # elevation of the gun above alpha in radians
        m.ballisticCoefficient = 0; #ballistic coefficient of the projectile
        m.muzzleVelocity = 0; #muzzle velocity of the projectile in feet per second
        m.harmonizationRange = 0; #gun zero range, feet
        m.range = 0; # range to target
        m.maxElevation = 0; # max deflection in mils
        m.maxAzimuth = 0;
        
        m.timeStep = 0; #loop run rate
        
        m.dampingFactor = 0.5; #value between 0.3 and 1.0, with lower = more jitter
        
        m.SIG = m.dampingFactor * 0.4;
        m.KSIG = 1.0 / (1.0 + m.SIG);
        
        # other variables
        m.seaLevelAirDensity = 0.00238;
        m.KBRHO = m.ballisticCoefficient / m.seaLevelAirDensity;
        m.cosGunElevation = math.cos(m.gunElevation);
        m.sinGunElevation = math.sin(m.gunElevation);
        m.RRH = 1.0 / m.harmonizationRange;
        m.RHO = props.globals.getNode("/environment/density-slugft3");
        m.VLS = m.KBRHO * m.RHO.getValue() * math.sqrt(muzzleVelocity) * m.range;
        m.rangeRate = 0;
        m.VOS = m.muzzleVelocity + m.VLS + m.rangeRate;
        m.VCM = math.sqrt(m.VOS * m.VOS - 4.0 * rangeRate * m.VLS);
        
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
        me.getRange();
        pop(me.rangeRateArray.vector);
        me.rangeRateArray.insert(0, (me.oldRange - me.range) / me.timeStep);
        me.rangeRate = (me.rangeRateArray.vector[0] + me.rangeRateArray.vector[1] + me.rangeRateArray.vector[2] + me.rangeRateArray.vector[3]) / 4;
    },
    
    getAzimuthAndElevation: func() {
        me.getRangeRate();
        me.tasFeet = 1.68781 * (661.47 * me.mach.getValue() * math.sqrt((me.ambientTemprature.getValue() + 273.15) / 288.15)); # true airspeed in feet
        
        me.totalInitialVelocity = me.tasFeet + me.muzzleVelocity;
        me.SQRV = math.sqrt(me.tasFeet + me.totalInitialVelocity);
        
        me.SLA = LA * (1.0 - 0.16667 * LA * LA)
        me.SLE = LE * (1.0 - 0.16667 * LE * LE)
        me.CLE = 1.0 - (LE * LE) / 2;
        me.CLA = 1.0 - (LA * LA) / 2;
        me.RCOS = 1.0 / (me.CLA * me.CLE);
        me.RDE = (me.rangeRate - RDC * me.SLE) * me.RCOS;
        
        me.VLS = me.KBRHO * me.RHO.getValue() * (me.range * me.RCOS) * (0.5 * (me.SQRV + (me.tasFeet + me.totalInitialVelocity)/me.SQRV));
        me.VOS = me.totalInitialVelocity - me.RDE - me.VLS;
        
        me.RDE = me.rangeRate;
        me.VCM = 0.5 * (me.VCM + (me.VOS * me.VOS - 4.0 * (me.tasFeet + me.RDE) * me.VLS) / me.VCM);
        me.VE = 0.5 * (me.VOS + me.VCM);
        
        me.recipricalTimeOfFlight = me.VE / (me.range * me.RCOS);
        me.averageRelativeVelocity = me.VE + me.RDE;
        
        me.VN = me.averageRelativeVelocity - me.SIG * me.RDE * me.VLS * (me.averageRelativeVelocity + me.tasFee)/(me.VCM * me.averageRelativeVelocity);
        me.PG = me.P.getValue() * me.cosGunElevation - me.R.getValue() * me.sinGunElevation;
        me.RG = me.P.getValue() * me.sinGunElevation + me.R.getValue() * me.cosGunElevation;
        
        RDC = trueAirSpeed * ((me.alpha.getValue() * D2R) + gunElevationRadians) * 
            (me.totalInitialVelocity - me.averageRelativeVelocity) / 
            (trueAirSpeed + me.totalInitialVelocity) + 
            0.5 * me.normalAcceleration.getValue() / me.recipricalTimeOfFlight;
            
        # WJ and WK are computed sight line angular rates
        me.WK = ((1.0 - me.range * RRH) * y_offset * me.CLA * me.recipricalTimeOfFlight - me.VN * me.SLA) * (1.0 / me.range);
        me.WJ = ((RDC - (1.0 - me.range * RRH) * z_offset * me.recipricalTimeOfFlight) * me.CLE - me.VN * me.CLA * me.SLE) * (1.0 / me.range);
        me.LED = (me.WJ + me.SLA * me.PG - me.CLA * me.Q.getValue()) * KSIG;
        me.LAD = ((me.WK - me.SLE * (me.CLA * me.PG + me.SLA * me.Q.getValue())) / me.CLE -me.RG) * KSIG;
        
        me.LA = LA + me.LAD * timeStep;
        me.LE = LE + me.LED * timeStep;
    },
    
    gunSightMain: func() {
        if (TRUE) {
            me.getAzimuthAndElevation();
            
            var tempLA = math.clamp(LA,-maxAzimuth/1000,maxAzimuth/1000);
            var tempLE = math.clamp(LE,-maxElevation/1000,maxElevation/1000);
            
            #set tempLA as azimuth amount
            #set tempLE as elevation amount
            #output is in mils
            # 1 mil = 0.05625 degrees
            
            settimer(me.gunSightMain, timeStep);
        }
    },
    
    gunSightReInit: func() {
        me.LA = 0;
        me.LE = 0;
    },
}