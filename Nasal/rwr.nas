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

rcs_loop();