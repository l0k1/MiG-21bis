
var ir_sar_switch = "/controls/armament/panel/ir-sar-switch";

var lockTarget = func() {
	if ( getprop(ir_sar_switch) == 2 ) {
		var c_dist = 999999;
		var c_most = nil;
		var i = -1;
		var lowerBar = (getprop("/controls/radar/lock-bars-pos")/950) * radarRange;
		var upperBar = ((getprop("/controls/radar/lock-bars-pos")+getprop("controls/radar/lock-bars-scale")) / 950) * radarRange;
		var centerBar = (upperBar + lowerBar) / 2;
		foreach(var track; radar_logic.tracks) {
			i += 1;
			var dist_rad = track.get_polar();
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
			radar_logic.selection = c_most;
			radar_logic.paint(c_most.getNode(), TRUE);
			radar_logic.tracks_index = i;
			armament.contact = selection;
			#print(selection.get_callsign());
		}
	}
}

var ir_seekTarget= func() {
	if ( getprop(ir_sar_switch) == 0 ) {
		#print("checking for IR target");
		var c_dist = 999999;
		var c_most = nil;
		var i = -1;
		var ir_seek_limit = 10000; # ir seek can't see past 5km (for now)
		foreach(var track; radar_logic.tracks) {
			i += 1;
			var dist_rad = track.get_polar();
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
		if ( c_most != nil and c_most != selection ) {
			#input.radarMode.setValue("locked-init");
			radar_logic.selection = c_most;
			radar_logic.paint(c_most.getNode(), TRUE);
			radar_logic.tracks_index = i;
			armament.contact = selection;
			#print("found target: " ~ selection.get_Callsign());
		} elsif ( c_most == nil ) {
			#print("unlocking 1");
			unlockTarget();
		}
		settimer( func { ir_seekTarget(); }, 0.1);
	}
}

var unlockTarget = func() {
	if ( selection != nil ) {
		print("unlocking target");
		radar_logic.paint(selection.getNode(), FALSE);
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