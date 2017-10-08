# RADAR ALTIMETER
# set a radar altimeter limit based on the position of the knob.



var rcs_loop = func() {
	var myCoord = geo.aircraft_position();
	foreach (var mp; props.globals.getNode("/ai/models").getChildren("multiplayer")) {
		var loc = geo.Coord.new().set_latlon(mp.getNode("position/latitude-deg").getValue(),mp.getNode("position/longitude-deg").getValue(),mp.getNode("position/altitude-ft").getValue() * FT2M);
		rwr_detect(myCoord,loc,mp.getNode("orientation/true-heading-deg").getValue(),mp.getNode("orientation/pitch-deg").getValue(),mp.getNode("orientation/roll-deg").getValue());
	}
	settimer(func(){rcs_loop();},0.1);
}

var rwr_detect = func(myCoord,echoCoord,echoHeading,echoPitch,echoRoll){

    # is it close enough

    var distance_to_source = myCoord.direct_distance_to(echoCoord); # in meters

    # is it behind terrain

	radar_logic.isNotBehindTerrain(echoCoord);

    var vectorToEcho   = vector.Math.eulerToCartesian2(myCoord.course_to(echoCoord), vector.Math.getPitch(myCoord,echoCoord));

    # first calculate relative pitch angle to see if the rwr can see the radiation source

    var vectorSide = vector.Math.eulerToCartesian3Y(getprop("/orientation/heading-deg"), getprop("/orientation/pitch-deg"), getprop("/orientation/roll-deg"));
    var vectorTop = vector.Math.eulerToCartesian3Z(getprop("/orientation/heading-deg"), getprop("/orientation/pitch-deg"), getprop("/orientation/roll-deg"));
    var view2Dpitch = vector.Math.projVectorOnPlane(vectorTop,vectorSide);
    var relative_pitch = vector.Math.angleBetweenVectors(vectorToEcho,view2Dpitch)-90;
    
    # check if we are in the radar scope of the radiation source

	var vectorEchoNose = vector.Math.eulerToCartesian3X(echoHeading, echoPitch, echoRoll);
	var vectorEchoTop  = vector.Math.eulerToCartesian3Z(echoHeading, echoPitch, echoRoll);
	var view2D         = vector.Math.projVectorOnPlane(vectorEchoTop,vectorToEcho);
	var angleToNose    = math.abs(geo.normdeg180(vector.Math.angleBetweenVectors(vectorEchoNose, view2D)+180)); #bearing
    var angleToBelly   = math.abs(geo.normdeg180(vector.Math.angleBetweenVectors(vectorEchoTop, vectorToEcho))-90); #pitch


    # it passed, so calculate angle to radiation source

    var vectorNose = vector.Math.eulerToCartesian3X(getprop("/orientation/heading-deg"), getprop("/orientation/pitch-deg"), getprop("/orientation/roll-deg"));
	var view2Droll = vector.Math.projVectorOnPlane(vectorNose,vectorSide);
    var relative_bearing = vector.Math.angleBetweenVectors(vectorToEcho,view2Droll)-90;
    #print("relative_bearing: " ~ relative_bearing);

    if ( relative_bearing > -112.5 and relative_bearing < 22.5 ) { 
   		#front left sensor
    } elsif ( relative_bearing < 112.5 and relative_bearing > -22.5 ) {
    	#front right sensor
    } elsif ( relative_bearing > 112.5 or relative_bearing < 157.5 ) {
    	#rear right sensor
    } else {
    	#rear left sensor
    }
}

# rwr strengths:
# 0 - off - light is off
# 1 - detected but far - blink slowly
# 2 - close/aiming - solid on
# 3 - missile fired - blink quickly
var rwr_sensor = {
	new: func(light_enable_prop, signal_strength_prop, signal_strength = 0, light_enable = 0, blink_rate = 0, blink_rate_low=1.5, blink_rate_high = 0.25) {
		var m = {parents:[pos_arm]};
		m.light_enable_prop = light_enable_prop;
		m.signal_strength_prop = signal_strength_prop;
		m.signal_strength = signal_strength;
		m.light_enable = light_enable;
		m.blink_rate = blink_rate;
		m.blink_rate_low = blink_rate_low;
		m.blink_rate_high = blink_rate_high;
		me._update_props();
		return m;
	},
	set_strength: func(strength) {
		if ( strength > me.signal_strength ) {
			me.signal_strength = strength;
		}
		if ( me.signal_strength == 0 ) {
			me.light_enable(0);
			me.blink_rate = 0;
		} elsif ( me.signal_strength == 1 ) {
			me.blink_rate = me.blink_rate_low;
			me._blink();
		} elsif ( me.signal_strength == 2 ) {
			me.ligth_enable(1);
			me.blink_rate = 0;
		} elsif ( me.signal_strength == 3 ) {
			me.blink_rate = me.blink_rate_high;
			me._blink();
		}

	},
	_blink: func() {
		if ( me.blink_rate != 0 ) {
			me.light_enable == me.light_enable * -1 + 1; #flip the light_enable
			settimer(func(){me.blink();},me.blink_rate);
		}
		me._update_props();
	},
	_update_props: func() {
		props.globals.getNode(me.light_enable_prop).setValue(me.light_enable);
		props.globals.getNode(me.signal_strength_prop).setValue(me.signal_strength);
	},
};

# set up sensors
var sensor_forward_left  = rwr_sensor.new("/instrumentation/rwr/forward-left/light-enable","/instrumentation/rwr/forward-left/signal-strength");
var sensor_forward_right = rwr_sensor.new("/instrumentation/rwr/forward-right/light-enable","/instrumentation/rwr/forward-right/signal-strength");
var sensor_rear_left  = rwr_sensor.new("/instrumentation/rwr/rear-left/light-enable","/instrumentation/rwr/rear-left/signal-strength");
var sensor_rear_right  = rwr_sensor.new("/instrumentation/rwr/rear-right/light-enable","/instrumentation/rwr/rear-right/signal-strength");

rcs_loop();