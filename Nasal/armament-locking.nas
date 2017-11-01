
var ir_sar_switch = "/controls/armament/panel/ir-sar-switch";
var TRUE = 1;
var FALSE = 0;

##### RADAR TARGET LOCKING

var radar_seekTarget = func() {
	if ( getprop(ir_sar_switch) == 2 ) {
		var c_dist = 999999;
		var c_most = nil;
		var lowerBar = (getprop("/controls/radar/lock-bars-pos")/950) * radar_logic.radarRange;
		var upperBar = ((getprop("/controls/radar/lock-bars-pos")+getprop("controls/radar/lock-bars-scale")) / 950) * radar_logic.radarRange;
		var centerBar = (upperBar + lowerBar) / 2;
		foreach(var track; radar_logic.tracks) {
			var dist_rad = track.get_polar();
			#print("radar seeker info:");
			#print("distance: " ~ dist_rad[0]);
			#print("x_ang: " ~ (dist_rad[1] * R2D));
			#print("y_ang: " ~ (dist_rad[3] * R2D));
			#print("lowerBar: " ~ lowerBar);
			#print("upperBar: " ~ upperBar);
			#print("centerBar: " ~ centerBar);
			if ( dist_rad[0] != 900000 and dist_rad[0] > lowerBar and dist_rad[0] < upperBar and math.abs(dist_rad[1] * R2D) < 5 and math.abs(dist_rad[3] * R2D) < 5) { # if the target is between lowerbar and upperbar on the radar, and is no more than 5* off centerline in all directions (left, up, right, down)
				if ( math.abs(dist_rad[0] - centerBar) < c_dist ) {
					c_dist = dist_rad[0];
					c_most = track;
				}
			}
		}
		if ( c_most != nil ) {
			radar_logic.input.radarMode.setValue("locked-init");
			lockTarget(c_most);
		}
	}
}

##### IR TARGET LOCKING

var ir_seekTarget= func() {
	if ( getprop(ir_sar_switch) == 0 ) {
		#print("checking for IR target");
		var c_dist = 999999;
		var c_most = nil;
		var ir_seek_limit = 10000; # ir seek can't see past 5km (for now)
		foreach(var track; radar_logic.tracks) {
			var dist_rad = track.get_polar();
			#print("ir seeker info:");
			#print("distance: " ~ dist_rad[0]);
			#print("x_ang: " ~ (dist_rad[1] * R2D));
			#print("y_ang: " ~ (dist_rad[2] * R2D));
      # IR Seeker cone, normalized at 1* pitch up and straight ahead.
      # maximum distance of 5.5 degrees in any direction.
			if ( dist_rad[0] != 900000 and dist_rad[0] < ir_seek_limit and math.abs(dist_rad[1] * R2D) < 5 and dist_rad[2] * R2D < 6 and dist_rad[2] > -4 * R2D) { # target distance < seek range, no more than 5* left/right, 3* up and 7* down
					c_dist = dist_rad[0];
					c_most = track;
			}
		}
		if ( c_most != nil and c_most != radar_logic.selection ) {
			lockTarget(c_most);
		} elsif ( c_most == nil ) {
			#print("unlocking 1");
			unlockTarget();
		}
		settimer( func { ir_seekTarget(); }, 0.1);
	}
}

var lockTarget = func(c_most) {
	radar_logic.selection = c_most;
	radar_logic.radarLogic.paint(c_most.getNode(), TRUE);
	armament.contact = radar_logic.selection;
	#print("locked target");
}

var unlockTarget = func() {
	if ( radar_logic.selection != nil ) {
		#print("unlocking target");
		radar_logic.radarLogic.paint(radar_logic.selection.getNode(), FALSE);
		radar_logic.selection = nil;
		armament.contact = nil;
		if ( radar_logic.input.radarMode.getValue() == "locked" or radar_logic.input.radarMode.getValue() == "locked-init" ) {
			radar_logic.input.radarMode.setValue("normal-init");
		}
	}
}

setlistener( ir_sar_switch, func { ir_seekTarget_init(); } );
ir_seekTarget_init = func() {
	if ( getprop(ir_sar_switch) == 0 ) {
		ir_seekTarget();
	}
}

##### BEAM RIDER TARGETTING

# from http://wiki.flightgear.org/User:Necolatis/terrain_detection_from_nasal

var getGPS = func(x, y, z, ac) {
	#
	# get Coord from body structural position. x,y,z must be in meters.
	# derived from Vivian's code in AIModel/submodel.cxx.
	#

	if(x == 0 and y==0 and z==0) {
		return geo.Coord.new(ac);
	}

	var ac_roll = getprop("orientation/roll-deg");
	var ac_pitch = getprop("orientation/pitch-deg");
	var ac_hdg   = getprop("orientation/heading-deg");

	var in    = [0,0,0];
	var trans = [[0,0,0],[0,0,0],[0,0,0]];
	var out   = [0,0,0];

	in[0] =  -x * M2FT;
	in[1] =   y * M2FT;
	in[2] =   z * M2FT;
	# Pre-process trig functions:
	var cosRx = math.cos(-ac_roll * D2R);
	var sinRx = math.sin(-ac_roll * D2R);
	var cosRy = math.cos(-ac_pitch * D2R);
	var sinRy = math.sin(-ac_pitch * D2R);
	var cosRz = math.cos(ac_hdg * D2R);
	var sinRz = math.sin(ac_hdg * D2R);
	# Set up the transform matrix:
	trans[0][0] =  cosRy * cosRz;
	trans[0][1] =  -1 * cosRx * sinRz + sinRx * sinRy * cosRz ;
	trans[0][2] =  sinRx * sinRz + cosRx * sinRy * cosRz;
	trans[1][0] =  cosRy * sinRz;
	trans[1][1] =  cosRx * cosRz + sinRx * sinRy * sinRz;
	trans[1][2] =  -1 * sinRx * cosRx + cosRx * sinRy * sinRz;
	trans[2][0] =  -1 * sinRy;
	trans[2][1] =  sinRx * cosRy;
	trans[2][2] =  cosRx * cosRy;
	# Multiply the input and transform matrices:
	out[0] = in[0] * trans[0][0] + in[1] * trans[0][1] + in[2] * trans[0][2];
	out[1] = in[0] * trans[1][0] + in[1] * trans[1][1] + in[2] * trans[1][2];
	out[2] = in[0] * trans[2][0] + in[1] * trans[2][1] + in[2] * trans[2][2];
	# Convert ft to degrees of latitude:
	out[0] = out[0] / (366468.96 - 3717.12 * math.cos(ac.lat() * D2R));
	# Convert ft to degrees of longitude:
	out[1] = out[1] / (365228.16 * math.cos(ac.lat() * D2R));
	# Set position:
	#var mlat = ac.lat() + out[0];
	#var mlon = ac.lon() + out[1];
	#var malt = (ac.alt() * M2FT) + out[2];
	
	return geo.Coord.new().set_latlon(ac.lat() + out[0], ac.lon() + out[1], (ac.alt() * M2FT) + out[2] * FT2M);
}

var beam_search = func(myPos) {
	#first find a coord in the radar beam in aircraft coordinates
	#beam angled down 1.5*
	
	#var beam_x = -15000*math.cos(-1.5*D2R);#1.5 deg down, 15Km out
	#var beam_y = 0;
	#var beam_z = 15000*math.sin(-1.5*D2R);
	#var beam = getGPS(beam_x, beam_y, beam_z, myPos);
	var beam = getGPS(-15000*math.cos(-1.5*D2R), 0, 15000*math.sin(-1.5*D2R), myPos);
	
	#we now find the vector the beam is pointed in:
	v = get_cart_ground_intersection(myPos.x(), myPos.y(), myPos.z(), beam.x()-myPos.x(), beam.y()-myPos.y(), beam.z()-myPos.z());
	if (v != nil) {
		gps_lock_geo.set_xyz(v[0],v[1],v[2]);
		#var terrainDist = myPos.direct_distance_to(gps_lock_geo);
		#printf("terrain found %0.1f meters down the beam", terrainDist);
	}
}

var gps_lock_geo = geo.Coord.new().set_xyz(0,0,0);
var beam_update_rate = 0.15;
var beam_max_close = 35; # an mp target will need to be at least this close to be "locked"
var closest_track = nil;
var gps_contact = radar_logic.ContactGPS.new("BEAMTGT", gps_lock_geo);

var beam_target_lock = func() {
	if ( getprop("controls/radar/power-panel/fixed-beam") == 1 ) {
		var my_geo = geo.aircraft_position();
		var closest_dist = beam_max_close;
		var i = -1;
		closest_track = nil;
		foreach(var track; radar_logic.tracks) {
			dist_to_track = gps_lock_geo.direct_distance_to(track.get_Coord());
			if ( dist_to_track < closest_dist ) {
				closest_dist = dist_to_track;
				closest_track = track;
			}
		}
		if ( closest_track != nil ) {
			lockTarget(closest_track);
		} else {
			gps_contact.coord = gps_lock_geo;
			if ( radar_logic.selection != nil ) {
				if ( radar_logic.selection.get_Callsign != "BEAMTGT" ) {
					unlockTarget();
					lockTarget(gps_contact);
				}
			} else {
				lockTarget(gps_contact);
			}
		}
		settimer(func(){beam_target_lock();},beam_update_rate);
	}
}

setlistener("controls/radar/power-panel/fixed-beam", func() {
	if (getprop("controls/radar/power-panel/fixed-beam") == 1) {
		beam_target_lock();
	} else {
		unlockTarget();
	}
});
