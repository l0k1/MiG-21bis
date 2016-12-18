#todo: make sure we have enough voltage. update me.power() for that.
#todo: the other fixed gunsight thingy. scale-sight?

var fixednetswitch = "/controls/armament/gunsight/fixed-net-power-switch";
var redpath = "/controls/armament/gunsight/red";
var bluepath = "/controls/armament/gunsight/blue";
var greenpath = "/controls/armament/gunsight/green";
var fixed_net_alphapath = "/controls/armament/gunsight/fixed-net-brightness-knob";
var fontsizepath = "/controls/armament/gunsight/font-size";
var linewidthpath = "/controls/armament/gunsight/thickness";
var viewX = "/sim/current-view/x-offset-m";
var viewY = "/sim/current-view/y-offset-m";
var viewZ = "/sim/current-view/z-offset-m";
var ghosting_x = "/controls/armament/gunsight/ghosting-x";
var ghosting_y = "/controls/armament/gunsight/ghosting-y";
var scaling = "/controls/armament/gunsight/scaling";
var sight_align_elevation = "/controls/armament/gunsight/elevation";
var sight_align_windage = "/controls/armament/gunsight/windage";

#pipper modes and info
var pipperpowerswitch = "/controls/armament/gunsight/pipper-power-switch";
var pipperscale = "/controls/armament/gunsight/pipper-scale";
var pipperaccuracy = "/controls/armament/gunsight/pipper-accuracy-switch";
var pippergunmissile = "/controls/armament/gunsight/gun-missile-switch";
var pippermode = "/controls/armament/gunsight/pipper-mode-select-switch";
var targetsizeknob = "/controls/armament/gunsight/target-size-knob";
var pipperangularcorrection = "/controls/armament/gunsight/pipper-angular-correction-knob";
var pipperbrightness = "/controls/armament/gunsight/pipper-brightness-knob";
var pipperautomanual = "/controls/armament/gunsight/auto-man-switch";

var air_gnd_switch = "/controls/armament/panel/air-gnd-switch";
var ir_sar_switch = "/controls/armament/panel/ir-sar-switch";
var gun_missile_switch = "/controls/armament/gunsight/gun-missile-switch";

var pipper_scale_degree_per_pixel = 0.018229508; # amount of degrees per pixel of pipperscale
var pipper_translation_degree_per_pixel = 0.009989712; # degrees to translate the pipper with

var startViewX = getprop(viewX);
var startViewY = getprop(viewY);
var startViewZ = getprop(viewZ);

var clamp = func(v, min, max) { v < min ? min : v > max ? max : v }

var FALSE = 0;
var TRUE  = 1;


var gun_sight = {
	
	
	canvas_settings: {
	  "name": "gunsight",   # The name is optional but allow for easier identification
	  "size": [1024, 1024], # Size of the underlying texture (should be a power of 2, required) [Resolution]
	  "view": [1024, 1024],  # Virtual resolution (Defines the coordinate system of the canvas [Dimensions]
							# which will be stretched the size of the texture, required)
	  "mipmapping": 1       # Enable mipmapping (optional)
	},
	new: func(placement)
	{
		var m = {
			parents: [gun_sight],
			gunsight: canvas.new(gun_sight.canvas_settings)
		};
		
		#pipper delta
		m.pDx = 0;
		m.pDy = 0;
	
		#gunsight settings
				
		#gunsight canvas
		
		var dR = m.getColor(redpath);
		var dG = m.getColor(greenpath);
		var dB = m.getColor(bluepath);
		var dAf = getprop(fixed_net_alphapath);
		var dAp = getprop(pipperbrightness);
		var fS = getprop(fontsizepath);	#font size
		var lW = getprop(linewidthpath);		#line width
	
		m.gunsight.addPlacement(placement);
		m.gunsight.setColorBackground(0,0,0,0);

		
		
		############################################################
		## GUNSIGHT CANVAS + LISTENERS ####################################
		############################################################
		
		m.gsight = m.gunsight.createGroup();
		m.gschild = [];
		m.fixed_net_centers = [];
		
		append(m.gschild, m.gsight.createChild("path", "straights")
			.setColor(dR,dG,dB,dAf)
			.setStrokeLineWidth(lW)
			.setStrokeLineCap("round")
			.moveTo(512,326)
			.lineTo(512,533)
			.moveTo(512,555)
			.lineTo(512,575)
			.moveTo(512,595)
			.lineTo(512,617)
			.moveTo(512,637)
			.lineTo(512,946)
			.moveTo(345,500)
			.lineTo(345,527)
			.moveTo(428,500)
			.lineTo(428,527)
			.moveTo(593,500)
			.lineTo(593,527)
			.moveTo(676,500)
			.lineTo(676,527)
			.moveTo(501,346)
			.lineTo(523,346)
			.moveTo(501,432)
			.lineTo(523,432)
			.moveTo(501,720)
			.lineTo(523,720)
			.moveTo(501,823)
			.lineTo(523,823)
			.moveTo(501,886)
			.lineTo(523,886)
			.moveTo(489,555)
			.lineTo(501,555)
			.moveTo(523,555)
			.lineTo(535,555)
			.moveTo(489,596)
			.lineTo(501,596)
			.moveTo(523,596)
			.lineTo(535,596)
			.moveTo(489,637)
			.lineTo(501,637)
			.moveTo(523,637)
			.lineTo(535,637)
			.moveTo(489,680)
			.lineTo(535,680)
			.moveTo(489,761)
			.lineTo(535,761)
			.moveTo(489,844)
			.lineTo(535,844)
			.moveTo(489,924)
			.lineTo(535,924)
			.moveTo(428,514)
			.lineTo(448,514)
			.moveTo(468,514)
			.lineTo(488,514)
			.moveTo(533,514)
			.lineTo(553,514)
			.moveTo(573,514)
			.lineTo(593,514)
			.moveTo(198,826)
			.lineTo(424,600)
			.moveTo(341,922)
			.lineTo(367,858)
			.moveTo(399,782)
			.lineTo(431,704)
			.moveTo(674,922)
			.lineTo(648,858)
			.moveTo(618,782)
			.lineTo(587,704)
			.moveTo(819,826)
			.lineTo(593,600)
			.moveTo(278,751)
			.lineTo(273,746)
			.moveTo(367,662)
			.lineTo(362,657)
			.moveTo(396,633)
			.lineTo(391,628)
			.moveTo(621,633)
			.lineTo(626,628)
			.moveTo(650,662)
			.lineTo(655,657)
			.moveTo(739,751)
			.lineTo(744,746)
			.moveTo(499,573)
			.lineTo(525,547)
			.moveTo(499,547)
			.lineTo(525,573)
			.moveTo(505,622)
			.lineTo(519,608)
			.moveTo(505,608)
			.lineTo(519,622));
			
		append(m.gschild, m.gsight.createChild("path", "inarc")
			.setColor(dR,dG,dB,dAf)
			.setStrokeLineWidth(lW)
			.setStrokeLineCap("round")
			.moveTo(259,479)
			.arcLargeCCWTo(255,255,0,765,479)
			.setStrokeDashArray([69,38,38,38,38,38,38,38,38,116,38,38,38,38,38,38,38,38,69])); # curve is 868 pixels 362
			
		append(m.gschild, m.gsight.createChild("path", "outarc")
			.setColor(dR,dG,dB,dAf)
			.setStrokeLineWidth(lW)
			.setStrokeLineCap("round")
			.moveTo(195,782)
			.arcSmallCCWTo(416,416,0,821,782)
			.setStrokeDashArray([40,40,40,40,40,40,40,147,40,40,40,40,40,40,40]));
		
		for (var i = 0; i < size(m.gschild); i += 1 ) {
			append(m.fixed_net_centers, m.gschild[i].getCenter());
		}
		
		setlistener(fixednetswitch,func { m.fixed_net_power() });
				
		m.fixed_net_power();
		
		############################################################
		## PIPPER CANVAS + LISTENERS ######################################
		############################################################
		
		m.pipper = m.gunsight.createGroup();
		
		m.pipper_elems = [];
		
		append(m.pipper_elems, m.pipper.createChild("path", "center")
			.setColor(dR,dG,dB,dAp)
			.setStrokeLineWidth(lW)
			.setStrokeLineCap("round")
			.moveTo(-7,0)
			.arcSmallCW(7,7,0,14,0)
			.arcSmallCW(7,7,0,-14,0)
			.setTranslation(512,240)
			.setColorFill(dR,dG,dB,dAp));
			
			
		append(m.pipper_elems, m.pipper.createChild("path","diamond 270")
			.setColor(dR,dG,dB,dAp)
			.setStrokeLineWidth(lW * 0.95)
			.setStrokeLineCap("round")
			.line(-24,9)
			.line(-6,-9)
			.line(6,-9)
			.line(24,9)
			.setTranslation(412,512)
			.setRotation(0,0));
			
		append(m.pipper_elems, m.pipper.createChild("path","diamond 315")
			.setColor(dR,dG,dB,dAp)
			.setStrokeLineWidth(lW * 0.95)
			.setStrokeLineCap("round")
			.line(-24,9)
			.line(-6,-9)
			.line(6,-9)
			.line(24,9)
			.setTranslation(441,441)
			.setRotation(45 * D2R,0));
			
		append(m.pipper_elems, m.pipper.createChild("path","diamond 360")
			.setColor(dR,dG,dB,dAp)
			.setStrokeLineWidth(lW * 0.95)
			.setStrokeLineCap("round")
			.line(-24,9)
			.line(-6,-9)
			.line(6,-9)
			.line(24,9)
			.setTranslation(512,412)
			.setRotation(90 * D2R,0));
			
		append(m.pipper_elems, m.pipper.createChild("path","diamond 45")
			.setColor(dR,dG,dB,dAp)
			.setStrokeLineWidth(lW * 0.95)
			.setStrokeLineCap("round")
			.line(-24,9)
			.line(-6,-9)
			.line(6,-9)
			.line(24,9)
			.setTranslation(583,441)
			.setRotation(135 * D2R,0));
			
		append(m.pipper_elems, m.pipper.createChild("path","diamond 90")
			.setColor(dR,dG,dB,dAp)
			.setStrokeLineWidth(lW * 0.95)
			.setStrokeLineCap("round")
			.line(-24,9)
			.line(-6,-9)
			.line(6,-9)
			.line(24,9)
			.setTranslation(612,512)
			.setRotation(180 * D2R,0));
			
		append(m.pipper_elems, m.pipper.createChild("path","diamond 135")
			.setColor(dR,dG,dB,dAp)
			.setStrokeLineWidth(lW * 0.95)
			.setStrokeLineCap("round")
			.line(-24,9)
			.line(-6,-9)
			.line(6,-9)
			.line(24,9)
			.setTranslation(583,583)
			.setRotation(225 * D2R,0));
			
		append(m.pipper_elems, m.pipper.createChild("path","diamond 180")
			.setColor(dR,dG,dB,dAp)
			.setStrokeLineWidth(lW * 0.95)
			.setStrokeLineCap("round")
			.line(-24,9)
			.line(-6,-9)
			.line(6,-9)
			.line(24,9)
			.setTranslation(512,612)
			.setRotation(270 * D2R,0));
			
		append(m.pipper_elems, m.pipper.createChild("path","diamond 225")
			.setColor(dR,dG,dB,dAp)
			.setStrokeLineWidth(lW * 0.95)
			.setStrokeLineCap("round")
			.line(-24,9)
			.line(-6,-9)
			.line(6,-9)
			.line(24,9)
			.setTranslation(441,583)
			.setRotation(315 * D2R,0));
			
		m.pipper_center = [512,240];
			
		setlistener(pipperpowerswitch, func { m.pipper_power(); } );
		setlistener(pipperscale, func { m.pipper_move(); } );
		
		m.pipper_power();
		
		############################################################
		## JOINT LISTENERS ##############################################
		############################################################
		
		setlistener(redpath,func { m.updateColor() });
		setlistener(bluepath,func { m.updateColor() });
		setlistener(greenpath,func { m.updateColor() });
		setlistener(fixed_net_alphapath,func { m.updateColor() });
		
		setlistener(linewidthpath,func { m.updateWidth() });
		
		setlistener(viewX,func { m.fixednet_updateXY();
											m.pipper_move();});
		setlistener(viewY,func { m.fixednet_updateXY();
											m.pipper_move();});
		
		m.update();
	},
	update: func() {
		me.pipper_move();
		settimer(func { me.update(); }, 0);
	},
	fixed_net_power: func() {
		var switch_state = getprop(fixednetswitch);
		if ( switch_state == 1 ) {
			for (var i = 0; i < size(me.gschild); i += 1 ) {
				me.gschild[i].show();
			}
		} else {
			for (var i = 0; i < size(me.gschild); i += 1 ) {
				me.gschild[i].hide();
			}	
		}
	},
	fixednet_updateXY: func() {
		#sight alignment
		var s_ele = getprop(sight_align_elevation);
		var s_win = getprop(sight_align_windage);
		
		#ghosting
		var changeViewX = -1 * (startViewX-getprop(viewX))*getprop(ghosting_x);
		var changeViewY = (startViewY-getprop(viewY))*getprop(ghosting_y);
	
		forindex ( var i; me.gschild ) {
			me.gschild[i].setTranslation(changeViewX + s_win, changeViewY + s_ele);
		}
    },
	
	pipper_power: func() {
		var switch_state = getprop(pipperpowerswitch);
		if ( switch_state == 1 ) {
			foreach ( var elem; me.pipper.getChildren() ) {
				elem.show();
			}
		} else {
		foreach ( var elem; me.pipper.getChildren() ) {
				elem.hide();
			}
		}
	},
	
	pipper_move: func() {
		#get current center coords
		var pip_cen_x = me.pipper_center[0] ; #+ getprop("aax"); #use aax and aay for manual testing
		var pip_cen_y = me.pipper_center[1] ; #+ getprop("aay");
		
		var pipper_adjust_x = 0;
		var pipper_adjust_y = 0;
		
		#center element ghosting
		var ghost_x = -1 * (startViewX-getprop(viewX))*getprop(ghosting_x);
		var ghost_y = (startViewY-getprop(viewY))*getprop(ghosting_y);
	
		#calculate range to target
		#if radar is on and locked, we can use that range. (auto)
		#if radar is set to ground mode, we can calculate range ourselves (auto)
		#otherwise, distance knob and pipper will be our friend. (manual)
		var range = 10000; #decrease me for more accuracy.
		
		#calculate range and pipper location
		
		if ( getprop(ir_sar_switch) != 0 and getprop("controls/radar/power-panel/fixed-beam") == 1 and getprop(air_gnd_switch) == 0) {
			#find range here. radar locked to -1.5*. it's going to be code intensive-ish. =\
			#orientation/heading-deg
			#orientation/pitch-deg
			#position/altitude-ft
			#var my_coord = geo.aircraft_position();
			pipper_adjust_y = -1.5; 
			var test_coord = geo.Coord.new();
			var altitude = getprop("/position/altitude-ft") * FT2M;
			#the 1.5 in the below to variables is to account for the fact that the radar is offset 1.5* below aircraft nose.
			var angle = (getprop("/orientation/pitch-deg") * D2R) - ((1.5 * math.cos(getprop("orientation/roll-deg") * D2R)) * D2R);
			var heading = (getprop("/orientation/heading-deg") * D2R) - ((1.5 * math.sin(getprop("orientation/roll-deg") * D2R)) * D2R);
			
			#print("angle: " ~ (angle * R2D) ~ " | angle_corr: " ~ (1.5 * math.cos(getprop("orientation/roll-deg") * D2R)) ~ " | heading: " ~ (heading * R2D) ~ " | heading_corr: " ~ (1.5 * math.sin(getprop("orientation/roll-deg") * D2R)));
			
			var max_loop = 15;
			var search_tolerance = 0.1;
			# regarding the tolerance value:
			# at shallow angles, we need high accuracy to get close to the correct range.
			# this value is good for 10k meters, if your max range is shorter consider
			# making this 0.01. if this fails, however, it will return a range of (max_r).
			# at really low values ( less than 0.01), if you do not decrease the max range
			# consider increasing iterations considerably.
			# it might be good to vary the tolerance based on the pitch, but i'll leave that
			# up to you.
			
			var max_range = range;
			var min_range = 0;
			
			var i = 0; #for verification
			
			#print("my_lat: " ~ my_coord.lat() ~ " | my_lon: " ~ my_coord.lon());
			
			for ( i = 0; i < max_loop; i = i + 1 ) {
				var mid = min_range + (max_range - min_range) / 2;
				var alt_to_check = altitude - (mid * math.cos(angle + (90 * D2R)));
				var distance_for_elev_calc = math.sin(angle + (90 * D2R)) * mid;
				
				test_coord = geo.aircraft_position().apply_course_distance(heading, distance_for_elev_calc);
				#print("test_lat: " ~ test_coord.lat() ~ " | test_lon: " ~ test_coord.lon());
				var elevation_at_coord = geo.elevation(test_coord.lat(), test_coord.lon());
				
				if ( math.abs(alt_to_check - elevation_at_coord) < search_tolerance ) {
					range = mid;
					break;
				} elsif ( angle < 0 ) {
					if ( alt_to_check < elevation_at_coord ) {
						max_range = mid + 1;
					} else {
						min_range = mid - 1;
					}
				}else{
					if ( alt_to_check < elevation_at_coord ) {
						min_range = mid - 1
					} else {
						max_range = mid + 1;
					}
				}
				#print("iter: " ~ i ~ " | mid: " ~ mid ~ " | min_range: " ~ min_range ~ " | max_range: " ~ max_range ~ " | alt_calc: " ~ alt_to_check ~ " | elev_at: " ~ elevation_at_coord ~ " | dist: " ~ distance_for_elev_calc);
			}
			#print("range: " ~ range ~ " | iters: " ~ i ~ " | alt: " ~ alt_to_check);
			
		# calculate pipper position if IR seeking is active
			
		} elsif ( getprop(ir_sar_switch) == 0 ) {
			# IR won't calculate range, so putting it seperate from the auto-range functions.
			# in theory, the pipper could "surround" the heat source, so letting the range thing slide for now.
			var locked_target = radar_logic.selection;
			if ( locked_target != nil ) {
				var dist_rad = locked_target.get_polar();
				#var x_ang = dist_rad[1] * R2D;
				#var y_ang = dist_rad[2] * R2D;
				range = dist_rad[0];
				if ( getprop(gun_missile_switch) == 1 ) {
					pipper_adjust_x = (dist_rad[1] * R2D);
					pipper_adjust_y = (dist_rad[2] * R2D);
				}
				#print("x deg: " ~ (dist_rad[1] * R2D) ~ " |y deg: " ~ (dist_rad[2] * R2D) ~ " |adjust x: " ~ math.cos(getprop("orientation/roll-deg") * D2R) ~ " |adjust y: " ~ ( -1 * math.sin(getprop("orientation/roll-deg") * D2R)) ~ " |finalx: " ~ pipper_adjust_x ~ " |finaly: " ~ pipper_adjust_y);
			}
		}
		
		if ( getprop(pipperautomanual) == 0 ) {
			#calculate pipper scale based on range value (i.e. automatically)
			#currently assuming a width of 15m, need to fix when the correct instrument is implemented.
			var ang_diam = 2 * (math.atan2(15,2*range));
			var scale = math.clamp((ang_diam * R2D) / pipper_scale_degree_per_pixel,5,220);
			setprop(pipperscale, scale);
			#print("range: " ~ range ~ " | angular diamater: " ~ (ang_diam * R2D) ~ " | scale: " ~  scale);
		} else {
			#calculate range based on pipperscale and inputted diameter.
			#still assuming a width of 15m, still need to fix.
			var scale = getprop(pipperscale);
			var ang_diam = (scale * pipper_scale_degree_per_pixel) * D2R;
			#print("ang_diam " ~ ang_diam);
			range = (15 / 2) / math.tan(ang_diam / 2);
			#print("range " ~ range);
		}
		
		if ( getprop(gun_missile_switch) == 0 ) {
			#gun pipper movement logic. need to do it after range has been calculated.
			#2840 ft/sec if we are calculating for gun.
			var airspeed = getprop("/velocities/airspeed-kt") * KT2MPS;
			var b_speed = 3000 + airspeed; #projectile speed
			var l_angle = 0;    #launch angle adjustment
			if ( getprop(pipperangularcorrection) == 0 ) { 
				#guns default until the knobbin gets installed
				b_speed = (2350 * FT2M) + airspeed; 
				l_angle = -1;
			}
			#adjust launch angle to account for aircraft roll
			#assuming heading variation is 0, otherwise we will need to account for that.
			#using angle of reach formula, hopefully this is accurate enough. adjusted for initial down pitch of -1.
			#print("range: " ~ range ~ " | b_speed: " ~ b_speed);
			angle_of_reach = l_angle + -1 * (0.5 * math.asin((9.81 * range) / math.pow(b_speed,2)) * R2D);
			#adjust x,y for hud
			pipper_adjust_x = -1 * angle_of_reach * math.sin(getprop("/orientation/roll-deg") * D2R);
			pipper_adjust_y = angle_of_reach * math.cos(getprop("/orientation/roll-deg") * D2R);
		}
			
	
	
		#translate center to proper position
		# ^ if that works, we can easily do a clamp to set the max amount of movement based on the gyro/miss switch
		
		pipper_adjust_x = pipper_adjust_x / pipper_translation_degree_per_pixel;
		pipper_adjust_y = -1 * pipper_adjust_y / pipper_translation_degree_per_pixel;
		
		me.pDx = pipper_adjust_x;
		me.pDy = pipper_adjust_y;
		
		pip_cen_x = pip_cen_x + ghost_x + pipper_adjust_x;
		pip_cen_y = pip_cen_y + ghost_y + pipper_adjust_y;
		
		me.pipper_elems[0].setTranslation(pip_cen_x, pip_cen_y);
		
		#translate diamonds based on center element
		var scale = getprop(pipperscale);
		forindex ( var i ; me.pipper_elems ) {
			#only translate the outside elements.
			if ( i != 0 ) {
				var angle = (180 - (45 * (i - 1))) * D2R;
				me.pipper_elems[i].setTranslation(pip_cen_x + scale * math.cos(angle), pip_cen_y + -1 * scale * math.sin(angle));
			}
		}
		setprop("instrumentation/gunsight/range-to-target",range);
	},
	
	
	updateColor: func() {
		var dR = me.getColor(redpath);
		var dB = me.getColor(bluepath);
		var dG = me.getColor(greenpath);
		var dA = getprop(fixed_net_alphapath);
		for (var i = 0; i < size(me.gschild); i += 1 ) {
			me.gschild[i].setColor(dR,dG,dB,dA);
		}
	},
	updateWidth: func() {
		var lW = getprop(linewidthpath);
		for (var i = 0; i < size(me.gschild); i += 1 ) {
			me.gschild[i].setStrokeLineWidth(lW);
		}
	},
	getColor: func(path) {
		x = getprop(path);
		y = x == 0 ? 0 : x > 0 ? x / 255 : x; # if x == 0 return 0 else return x / 255
		return y;
	}
};

var init = setlistener("/sim/signals/fdm-initialized", func() {
  #print("inniting");
  removelistener(init); # only call once
  var gs = gun_sight.new({"node": "sight"});
#  var hud_copilot = HUD.new({"node": "HUD.l.canvas.001"});
#  hud_copilot.update();
});



########################### OTHER NOT-CANVAS, BUT STILL GUNSIGHT RELATED THINGS

#get the current missile max launch range, and set it to a certain property
var max_launch_range_finder = func() {
	var cur_missile = getprop("payload/weight["~(payloads.pylon_select()[0])~"]/selected") ;
	var min = getprop("payload/armament/" ~ cur_missile ~ "/min-fire-range-nm");
	var max = getprop("payload/armament/" ~ cur_missile ~ "/max-fire-range-nm");
	if ( min != nil ) {
		setprop("instrumentation/gunsight/min-launch-range",min);
	}
	if ( max != nil ) {
		setprop("instrumentation/gunsight/max-launch-range",max);
	}
	settimer( func { max_launch_range_finder(); }, 1);
}