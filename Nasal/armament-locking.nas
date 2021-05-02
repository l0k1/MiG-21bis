
var ir_sar_switch = "/controls/armament/panel/ir-sar-switch";
var fixed_beam_switch = "/controls/radar/power-panel/fixed-beam";
var lockHash = props.globals.getNode("/sim/multiplay/generic/string[6]");
var TRUE = 1;
var FALSE = 0;

##### RADAR TARGET LOCKING

var radar_seekTarget = func() {
	if ( getprop("fixed_beam_switch") != 1 ) {
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
			lockTarget(c_most,"radar");
		}
	}
}

##### IR TARGET LOCKING - no longer used

var ir_seekTarget= func() {
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
		lockTarget(c_most,"ir");
	} elsif ( c_most == nil ) {
		print("unlocking 1");
		unlockTarget();
	}
	settimer( func { ir_seekTarget(); }, 0.1);
}

var lockTarget = func(c_most,mode) {
	radar_logic.selection = c_most;
	radar_logic.radarLogic.paint(c_most.getNode(), TRUE);
	armament.contact = radar_logic.selection;
	lockHash.setValue(left(md5(c_most.get_Callsign()),4));
	lock_mode = mode;
	#print("locked target");
}

var lock_mode = "none";

var unlockTarget = func() {
	if ( radar_logic.selection != nil ) {
		lock_mode = "none";
		lockHash.setValue("");
		radar_logic.radarLogic.paint(radar_logic.selection.getNode(), FALSE);
		radar_logic.selection = nil;
		armament.contact = nil;
		if ( radar_logic.input.radarMode.getValue() == "locked" or radar_logic.input.radarMode.getValue() == "locked-init" ) {
			radar_logic.input.radarMode.setValue("normal-init");
		}
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
		print("returning ac");
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

	return geo.Coord.new().set_latlon(ac.lat() + out[0], ac.lon() + out[1], ((ac.alt() * M2FT) + out[2]) * FT2M);
}

var beam_search = func(myPos) {
	#first find a coord in the radar beam in aircraft coordinates
	#beam angled down 1.5*
	
	#var beam_x = -15000*math.cos(-1.5*D2R);#1.5 deg down, 15Km out
	#var beam_y = 0;
	#var beam_z = 15000*math.sin(-1.5*D2R);
	#var beam = getGPS(beam_x, beam_y, beam_z, myPos);

	var beam = getGPS(-100000*math.cos(-1.5*D2R), 0, 100000*math.sin(-1.5*D2R), myPos);
	
	#we now find the vector the beam is pointed in:
	v = get_cart_ground_intersection({"x":myPos.x(), "y":myPos.y(), "z":myPos.z()}, {"x":beam.x()-myPos.x(), "y":beam.y()-myPos.y(), "z":beam.z()-myPos.z()});
	if (v != nil) {
		gps_lock_geo.set_latlon(v.lat, v.lon, v.elevation);
		#var terrainDist = myPos.direct_distance_to(gps_lock_geo);
		#printf("terrain found %0.1f meters down the beam", terrainDist);
	} else {
		gps_lock_geo.set_xyz(beam.x(),beam.y(),beam.z());
	}
}

var gps_lock_geo = geo.Coord.new().set_xyz(0,0,0);
var beam_update_rate = 0.15;
var closest_dist = 100000;
var closest_track = nil;
var gps_contact = radar_logic.ContactGPS.new("BEAMTGT", gps_lock_geo);

var n = props.globals.getNode("models",1);
var i = 0;
for (i = 0; 1==1; i += 1) {
	if (n.getChild("model",i,0) == nil) {
		break;
	}
}

#var objModel = n.getChild("model",i,1);
#
#objModel.getNode("elevation",1).setDoubleValue(-999);
#objModel.getNode("latitude",1).setDoubleValue(0);
#objModel.getNode("longitude",1).setDoubleValue(0);
#objModel.getNode("elevation-ft-prop",1).setValue(objModel.getPath()~"/elevation");
#objModel.getNode("latitude-deg-prop",1).setValue(objModel.getPath()~"/latitude");
#objModel.getNode("longitude-deg-prop",1).setValue(objModel.getPath()~"/longitude");
#objModel.getNode("heading",1).setDoubleValue(0);
#objModel.getNode("pitch",1).setDoubleValue(0);
#objModel.getNode("roll",1).setDoubleValue(0);
#objModel.getNode("heading-deg-prop",1).setValue(objModel.getPath()~"/heading");
#objModel.getNode("pitch-deg-prop",1).setValue(objModel.getPath()~"/pitch");
#objModel.getNode("roll-deg-prop",1).setValue(objModel.getPath()~"/roll");
#
#objModel.getNode("path",1).setValue("Aircraft/MiG-21bis/Models/tgtsphere.xml"); # this is the model to be loaded.
#
#var loadNode = objModel.getNode("load", 1);
#loadNode.setBoolValue(1);
#loadNode.remove();

var beam_target_lock = func() {
	if ( radar_canvas.radarscreen.cur_state == radar_canvas.radar_beamed ) {
		var my_geo = geo.aircraft_position();
		beam_search(my_geo);
		gps_contact.coord = gps_lock_geo;

		if ( radar_logic.selection != nil and radar_logic.selection.get_Callsign() != "BEAMTGT") {
			#print("unlocked");
			unlockTarget();
			lockTarget(gps_contact,"radar");
		} elsif (radar_logic.selection == nil) {
			#print("locked on that radar tgt");
			lockTarget(gps_contact,"radar");
		}
		#print('lat: ' ~ gps_contact.get_Latitude());
		#print('lon: ' ~ gps_contact.get_Longitude());
		#print('alt: ' ~ gps_contact.get_altitude());
		settimer(func(){beam_target_lock();},beam_update_rate);
	}
}

##### CUSTOM MISSILE TARGETTING

var kh25_guidance = func(input) {
	#print("weapon pitch:" ~ input.weapon_pitch);
	#print("guiding");
	#print("guidance: " ~ input.guidance);
	detect_range = input.seeker_detect_range * NM2M;
	if (input.guidance == "radiation") {
		#print("guidance is radiation");
		return {};
	}
	foreach (track; mpdb.cx_master_list) {
		#print("track distance: " ~ track.coord.distance_to(input.weapon_position) ~ " | seeker range:   " ~ detect_range);
		#print("checking track " ~ track.get_Callsign());
		if (track.coord.distance_to(input.weapon_position) > detect_range) {
			#print("not within range");
			continue;
		}

		if (track.isRadiating(input.weapon_position) == 0 ) {
			#print("not radiating");
			continue;
		}
		
		#ground angle
		yg_rad = vector.Math.getPitch(input.weapon_position, track.coord) * D2R - input.weapon_pitch;
		xg_rad = (input.weapon_position.course_to(track.coord) - input.weapon_heading) * D2R;
	
		while ( xg_rad >  math.pi ) { xg_rad = xg_rad - 2 * math.pi; }
		while ( xg_rad < -math.pi ) { xg_rad = xg_rad + 2 * math.pi; }
		while ( yg_rad >  math.pi ) { yg_rad = yg_rad - 2 * math.pi; }
		while ( yg_rad < -math.pi ) { yg_rad = yg_rad + 2 * math.pi; }

		#print("found target at pitch: " ~ yg_rad * R2D ~ " | heading: " ~ xg_rad);
      
    	var seeker_fov_rad = input.seeker_fov * D2R;
		if (yg_rad > -seeker_fov_rad and yg_rad < seeker_fov_rad and xg_rad > -seeker_fov_rad  and xg_rad < seeker_fov_rad) {
			#print("locked!");
			return {guidance: "radiation", target: track};
		}
	}
	return {};
}

#{time_s, dist_m, mach, weapon_position, guidance, seeker_detect_range, seeker_fov, weapon_pitch, weapon_heading}
#{guidance, guidanceLaw, target}

var r27t1_guidance = func(input) {
	#print("weapon pitch:" ~ input.weapon_pitch);
	detect_range = input.seeker_detect_range * NM2M;
	if (input.guidance == "ir") {
		return {};
	}
	foreach (track; mpdb.cx_master_list) {
		#print("track distance: " ~ track.coord.distance_to(input.weapon_position) ~ " | seeker range:   " ~ detect_range);
		if (track.coord.distance_to(input.weapon_position) > detect_range) {
			continue;
		}
		
		#ground angle
		yg_rad = vector.Math.getPitch(input.weapon_position, track.coord) * D2R - input.weapon_pitch;
		xg_rad = (input.weapon_position.course_to(track.coord) - input.weapon_heading) * D2R;
	
		while ( xg_rad >  math.pi ) { xg_rad = xg_rad - 2 * math.pi; }
		while ( xg_rad < -math.pi ) { xg_rad = xg_rad + 2 * math.pi; }
		while ( yg_rad >  math.pi ) { yg_rad = yg_rad - 2 * math.pi; }
		while ( yg_rad < -math.pi ) { yg_rad = yg_rad + 2 * math.pi; }

		#print("found target at pitch: " ~ yg_rad * R2D ~ " | heading: " ~ xg_rad);
      
    	var seeker_fov_rad = input.seeker_fov * D2R;
		if (yg_rad > -seeker_fov_rad and yg_rad < seeker_fov_rad and xg_rad > -seeker_fov_rad  and xg_rad < seeker_fov_rad) {
			#print("locked!");
			return {guidance: "ir", target: track};
		}
	}
	return {};
}
