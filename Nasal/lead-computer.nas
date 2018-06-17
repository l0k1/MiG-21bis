#****************************************************************************
#
#  Derived from 
#  A Digital Lead Computing Optical Sight Model
#  Anthony L. Leatham, et al
#  Air Force Academy  
#  Sept. 1974
#  http://www.dtic.mil/dtic/tr/fulltext/u2/786464.pdf
#
#  Appendex D Air Force Avionics Laboratory digital LCOS
#  Contains FORTRAN code that is used here converted into Nasal code.
#
#  Original source for equations and code was from:
#
#  Air-to-Air Gun Fire Control Equations for Digital Lead Computing Optical Sights
#  R.A. Manske
#  AFAL-TM-74-8-NVE-1
#  April 1974
#  Air Force Avionics Laboratory
#  Wring-Patterson AFB, Ohio
#
#  Document location unknown.
#
#  non-static inputs
#
#  range                  in feet
#  rangeRate              range rate in ft/sec
#  P                      angular pitch rate of aircraft body axis in radians/second
#  Q                      angular yaw rate of aircraft body axis in radians/second
#  R                      angular roll rate of aircraft body axis in radians/second
#  normalAcceleration     normal acceleration in ft/sec/sec (-32.17 straight and level)
#  alpha                  angle of attack radians
#  trueAirSpeed           true airspeed - feet per second
#  RHO                    air density in slugs per cubic foot
#
#********************************************************************************

# ================================ Initalize ====================================== 
# Make sure all needed properties are present and accounted 
# for, and that they have sane default values.

# print("gunsight-computer.nas started");

var propertyTreeRoot = "/controls/armament/gunsight/";

var z_offset = 0;
var y_offset = 0;
var gunElevationRadians = 0;

var ballisticCoefficienct = 0;
var muzzleVelocity = 0;
var harmonizationRange = 0;
var range = 0;

# constants
var timeStep = getprop(propertyTreeRoot, "timeStep");

# sight damping factor
var SIG = getprop(propertyTreeRoot, "dampingFactor") * 0.4;

var KSIG = 1.0 / (1.0 + SIG);

var seaLevelAirDensity = 0.00238;
var radiansPerDrgree = 0.0174532925;

# Ballistic coefficient divided by sea level air density
var KBRHO = 0;

var cosGunElevation = 0;
var sinGunElevation = 0;

# Reciprocal of gun harmonization range
var RRH = 0;

var SQRV = 0;
var RHO = 0;

var RDC = 0;
var LA = 0;
var LE = 0;
var VLS = 0;
var rangeRate = 0;
var VOS = 0; 
var VCM = 0;
var VMC = 0;
var rangeRateArray = [0, 0, 0, 0]; 
var rRAindex = 0;

var P = 0;
var Q = 0;
var R = 0;
var normalAcceleration = -32.17;

var maxElevation = getprop(propertyTreeRoot, "maxElevation");
var maxAzimuth = getprop(propertyTreeRoot, "maxAzimuth");

var initSightComputer = func()
{
   # print("gunsite-computer.nas init()");
   
   # Get aircraft/sight specific info
   
   # Offset of gun in feet from sight line
   z_offset = getprop(propertyTreeRoot, "z-offsetFeet");
   y_offset = getprop(propertyTreeRoot, "y-offsetFeet");

   # Elevation of gun(s) above alpha   
   gunElevationRadians = getprop(propertyTreeRoot, "gunElevationDegrees") * 0.0174532925;
   
   # Projectile ballistic Coefficient and muzzle velocity in feet per second
   ballisticCoefficienct = getprop(propertyTreeRoot, "ballisticCoefficienct");
   muzzleVelocity = getprop(propertyTreeRoot, "muzzleVelocity");
   
   # Range where the sight line is = the guns bore line
   harmonizationRange = getprop(propertyTreeRoot, "gunHarminizationRangeFeet");
   
   # range to target usually from an onboard radar system or a 
   # manual system controlled by the aircraft crew   
   range = getprop(propertyTreeRoot, "range");
   
   var seaLevelAirDensity = 0.00238;

   # Ballistic coefficient divided by sea level air density
   KBRHO = ballisticCoefficienct / seaLevelAirDensity;

   cosGunElevation = math.cos(gunElevationRadians);
   sinGunElevation = math.sin(gunElevationRadians);

   # Reciprocal of gun harmonization range
   RRH = 1.0 / harmonizationRange;

   SQRV = math.sqrt(muzzleVelocity);
   RHO = getprop("/environment/density-slugft3");

   VLS = KBRHO * RHO * SQRV * range;
   rangeRate = 0;
   VOS = muzzleVelocity + VLS + rangeRate; 
   VCM = math.sqrt(VOS * VOS - 4.0 * (rangeRate) * VLS);
   VMC = math.sqrt(VOS * VOS - 4.0 * (rangeRate) * VLS);
   
   # print("gunsite-computer.nas initialization done");
}

var getRangeRate = func()
{
   # print("gunsite-computer.nas getRangeRate");
   var oldRange = range;
   range = getprop(propertyTreeRoot, "range");
   rangeRateArray[rRAindex] = (oldRange - range) / timeStep;
   rRAindex = rRAindex + 1;
   if (rRAindex > 3) 
   {
      rRAindex = 0;
   }
   var rangeRateSum = 0;
   forindex(i; rangeRateArray)
   {
      rangeRateSum = rangeRateSum + rangeRateArray[i];	
   }
   var rangeRateAve = rangeRateSum / 4;
   setprop("/controls/armament/gunsight/rangeRate", rangeRateAve);   
   return -1.0 * rangeRateAve;
}

var getAccelerationData = func()
{
   # print("gunsite-computer.nas getAccelerationData()");
   
   P = getprop("/orientation/p-body");
   Q = getprop("/orientation/q-body");
   R = getprop("/orientation/r-body");
   normalAcceleration = getprop("/accelerations/pilot/z-accel-fps_sec");
}

var getTrueAirSpeed = func()
{
   # print("gunsite-computer.nas getTrueAirspeed()");
   
   # from http://en.wikipedia.org/wiki/True_airspeed
   # TASKnots = A0 * M * sqrt(T/T0)
   # where A0 = speed of sound a standard sea level (661.47 Kts) 
   #       M = MACH speed of aircraft
   #       T = static air temperature in Kelvin at aircraft position
   #       T0 = temperature a standard sea level (288.15 K)
   
   var ambientTemperatureKelvin = getprop("/environment/temperature-degc") + 273.15;
   var MACH = getprop("/velocities/mach");
   var TASKnots = 661.47 * MACH * math.sqrt(ambientTemperatureKelvin / 288.15);
   
   # print("true airspeed = ", TASKnots);
   # return TAS in feet per second.
   return TASKnots * 1.68781;
}   

var getAzimuthAndElevation = func()
{   
   # print("gunsite-computer.nas getAzimuthAndElevation");
   
   getAccelerationData();
   # print("normalAcceleration = ", normalAcceleration);
   rangeRate = getRangeRate();
   range = getprop(propertyTreeRoot, "range");
   var alpha = getprop("/orientation/alpha-deg") * radiansPerDrgree;
   
   var trueAirSpeed = getTrueAirSpeed();
   
   var totalInitialVelocity = trueAirSpeed + muzzleVelocity;
   var SQRV = math.sqrt(trueAirSpeed + totalInitialVelocity);
   
   var RHO = getprop("/environment/density-slugft3");
   
   var SLA = LA * (1.0 - 0.16667 * LA * LA);
   var SLE = LE * (1.0 - 0.16667 * LE * LE);
   var CLE = 1.0 - (LE * LE)/2;
   var CLA = 1.0 - (LA * LA)/2;
   var RCOS = 1.0/(CLA * CLE);
   var RDE = (-rangeRate - RDC * SLE) * RCOS;
   var RE = range * RCOS;
   
   # Approximation used for sqrt
   # If y=approx. square root of x, then SQTR(x) = 0.5 * (y + x/y) is very close
   SQRV = 0.5 * (SQRV + (trueAirSpeed + totalInitialVelocity)/SQRV);
   VLS = KBRHO * RHO * RE * SQRV;
   VOS = totalInitialVelocity - RDE - VLS;
   
   # Approximation used for sqrt
   # RDE = -rangeRate makes this calculation identical to other LCOSS
   RDE = -rangeRate;
   VCM = 0.5 * (VCM + (VOS * VOS - 4.0 * (trueAirSpeed + RDE) * VLS) / VCM);
   var VE = 0.5 * (VOS + VCM);
   
   var recipricalTimeOfFlight = VE / RE;
   var averageRelativeVelocity = VE + RDE;
      
   var rRange = 1.0 / range;
   var KH = 1.0 - range * RRH;   
   var VN = averageRelativeVelocity - SIG * RDE * VLS * (averageRelativeVelocity + trueAirSpeed)/(VCM * averageRelativeVelocity);
      
   var PG = P * cosGunElevation - R * sinGunElevation;
   var RG = P * sinGunElevation + R * cosGunElevation;
  
   RDC = trueAirSpeed * (alpha + gunElevationRadians) * 
          (totalInitialVelocity - averageRelativeVelocity) / 
		   (trueAirSpeed + totalInitialVelocity) + 
		   0.5 * normalAcceleration / recipricalTimeOfFlight;
   
   # WJ and WK are computed sight line angular rates
   var WK = (KH * y_offset * CLA * recipricalTimeOfFlight - VN * SLA) * rRange;
   var WJ = ((RDC - KH * z_offset * recipricalTimeOfFlight) * CLE - VN * CLA * SLE) * rRange;
   var LED = (WJ + SLA * PG - CLA * Q) * KSIG;
   var LAD = ((WK - SLE * (CLA * PG + SLA * Q)) / CLE -RG) * KSIG;
   
   LA = LA + LAD * timeStep;
   LE = LE + LED * timeStep;
}

var gunSightMain = func()
{
   # print("gunSightMain()");
   if (getprop(propertyTreeRoot, "computer-on") == 1)
   {   
      getAzimuthAndElevation();
      # LA and LE are azimuth and elevation angles of the computed sight line
      # LA and LE are in radians.  
	  
	  # Compute PLA and PLE as negative mills
      # var PLA = -1000.0 * LA;
      # var PLE = -1000.0 * LE;
		 
      # update reticle position
	  # Under extreme conditions such as a spin the algorithm 
	  # can generate invalid results and return NaN for LA 
      # and LE which causes the whole thing to break down.	  
	  # If that happens set them to 0 (reinitialize LA and LE)
	  # and continue on.
	  
	   # clamp LA and LE to max deflection values for the sight
	   var tempLA = LA;
	   var tempLE = LE;

       if (LA > maxAzimuth/1000)
       {
          tempLA = maxAzimuth/1000;
       }
       else if (LA < -maxAzimuth/1000)
       {
           tempLA = -maxAzimuth/1000;
       }
	   if (LE > maxElevation/1000)
       {
          tempLE = maxElevation/1000;
       }
       else if (LE < -maxElevation/1000)
       {
           tempLE = -maxElevation/1000;
       }
      call(func setprop(propertyTreeRoot, "azimuth", tempLA), nil, var LEerr = []);
	  if (size(LEerr))
	  {
	    tempLA = 0;
		setprop(propertyTreeRoot, "azimuth", tempLA);
	  }
	  
	  call (func setprop(propertyTreeRoot, "elevation", tempLE), nil, var LAerr = []);
	  if (size(LAerr))
	  {
	    tempLE = 0;
		setprop(propertyTreeRoot, "elevation", tempLE)
	  }
	  
	  # print("gunSightMain loop");
	  # print("LA (azimuth) = ", LA);
	  # print("LE (elevation)= ", LE);
	  # wait a while and do this again
	  settimer(gunSightMain, timeStep);
   } 
}

# listener for the the sight computer/gyro to be powered up or down.
# Will start gunSightMain process when the gun sight computer/gyro is powered on.        
var listenGunSightGyroPower = func(i) 
{    
    if (getprop(propertyTreeRoot, "computer-on") == 1)
	{
	    initSightComputer();
		setprop(propertyTreeRoot, "gunsightComputerInitialized", 1);
	    # print("gunsite-computer.nas power switched");
        gunSightMain();
	}
	else
	{
	   setprop(propertyTreeRoot, "gunsightComputerInitialized", 0);
	}
}

setprop("/controls/armament/gunsight/gunsightComputerInitialized", 0);

var L1 = setlistener("/sim/signals/fdm-initialized", func(i) 
{
    var L = setlistener("/controls/armament/gunsight/computer-on", listenGunSightGyroPower, 1, 0);
}, 1, 0);

      
