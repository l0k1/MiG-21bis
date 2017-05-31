# todo: ground clutter - not sure on best way to do this. rapidly moving circles? might be code intensive.
# todo: fixed-beam, side-compensation, and low-alt switch operation (i.e. get radar angular limits working)

var dR = 0.823; #display red value
var dG = 0.902; #display green value
var dB = 0.118; #display blue value
var fS = 60;	#font size
var lL = 80;	#line length (it's a little case L, not a [one])
var lW = 4;		#line width

var lock_bars_scale = "/controls/radar/lock-bars-scale";
var lock_bars_pos = "/controls/radar/lock-bars-pos";
var radar_mode = "/controls/radar/mode";
var show_callsigns = "/controls/radar/panel/iff";

var radarRange = 60000;
var radarRange10k = radarRange / 1000;

var RADAR_BOTTOM_LIMIT = -30;
var RADAR_TOP_LIMIT = 30;
var RADAR_LEFT_LIMIT = -30;
var RADAR_RIGHT_LIMIT = 30;

var clamp = func(v, min, max) { v < min ? min : v > max ? max : v }

var FALSE = 0;
var TRUE  = 1;

var locked_target = nil;


var radar_screen = {
	
	
	canvas_settings: {
	  "name": "radarDisplay",   # The name is optional but allow for easier identification
	  "size": [1024, 1024], # Size of the underlying texture (should be a power of 2, required) [Resolution]
	  "view": [1024, 1024],  # Virtual resolution (Defines the coordinate system of the canvas [Dimensions]
							# which will be stretched the size of the texture, required)
	  "mipmapping": 1       # Enable mipmapping (optional)
	},
	new: func(placement)
	{
		var m = {
			parents: [radar_screen],
			radar_canvas: canvas.new(radar_screen.canvas_settings)
		};
	
		#radar settings
		
		m.radar_range = radarRange; #radar range in meters - should be set by properties at some point
		m.no_blip=20; # max number of blips
		
		#radar canvas
	
		m.radar_canvas.addPlacement(placement);
		m.radar_canvas.setColorBackground(0.100,0.161,0.106,1);

		m.radar_group = m.radar_canvas.createGroup();
		m.blips = m.radar_canvas.createGroup();
		m.dumb = m.radar_canvas.createGroup();
		
		m.gschild = [];

		m.pinto_rulez = m.dumb.createChild("text", "pinto rulez")
			.setTranslation(506, 200)      # The origin is in the top left corner
			.setAlignment("center-center") # All values from osgText are supported (see $FG_ROOT/Docs/README.osgtext)
			.setFont("LiberationFonts/LiberationMono-Regular.ttf") # Fonts are loaded either from $AIRCRAFT_DIR/Fonts or $FG_ROOT/Fonts
			.setFontSize(64, 1.2)        # Set fontsize and optionally character aspect ratio
			.setColor(dR,dG,dB)             # Text color
			.setText("pinto rulez");
		m.xruler = m.dumb.createChild("text", "pinto rulez 2")
			.setTranslation(506, 170)      # The origin is in the top left corner
			.setAlignment("center-center") # All values from osgText are supported (see $FG_ROOT/Docs/README.osgtext)
			.setFont("LiberationFonts/LiberationMono-Regular.ttf") # Fonts are loaded either from $AIRCRAFT_DIR/Fonts or $FG_ROOT/Fonts
			.setFontSize(64, 1.2)        # Set fontsize and optionally character aspect ratio
			.setColor(dR,dG,dB)             # Text color
			.setText("---------------------------------------------");
		m.pinto_rulez.hide();
		m.xruler.hide();

		#text - top numbers
		m.m30 = m.radar_group.createChild("text", "30 distance marker")
			.setTranslation(506,90)
			.setAlignment("center-center")
			.setFont("LiberationFonts/LiberationMono-Regular.ttf")
			.setFontSize(fS)
			.setColor(dR,dG,dB)
			.setText(int(radarRange10k));
			
		m.m20_left = m.radar_group.createChild("text", "20 distance marker left")
			.setTranslation(96,377)
			.setAlignment("center-center")
			.setFont("LiberationFonts/LiberationMono-Regular.ttf")
			.setFontSize(fS)
			.setColor(dR,dG,dB)
			.setText(int((radarRange10k/3)*2));

		m.m20_right = m.radar_group.createChild("text", "20 distance marker right")
			.setTranslation(918,377)
			.setAlignment("center-center")
			.setFont("LiberationFonts/LiberationMono-Regular.ttf")
			.setFontSize(fS)
			.setColor(dR,dG,dB)
			.setText(int((radarRange10k/3)*2));
			
		m.m10_left = m.radar_group.createChild("text", "10 distance marker left")
			.setTranslation(96,663)
			.setAlignment("center-center")
			.setFont("LiberationFonts/LiberationMono-Regular.ttf")
			.setFontSize(fS)
			.setColor(dR,dG,dB)
			.setText(int(radarRange10k/3));
			
		m.m10_right = m.radar_group.createChild("text", "10 distance marker right")
			.setTranslation(918,663)
			.setAlignment("center-center")
			.setFont("LiberationFonts/LiberationMono-Regular.ttf")
			.setFontSize(fS)
			.setColor(dR,dG,dB)
			.setText(int(radarRange10k/3));
			
		m.m0 = m.radar_group.createChild("text", "0 distance marker")
			.setTranslation(506,950)
			.setAlignment("center-center")
			.setFont("LiberationFonts/LiberationMono-Regular.ttf")
			.setFontSize(fS)
			.setColor(dR,dG,dB)
			.setText(0);

		#text - middle numbers
		m.r10_left = m.radar_group.createChild("text", "10 horiz left")
			.setTranslation(141,595)
			.setAlignment("center-center")
			.setFont("LiberationFonts/LiberationMono-Regular.ttf")
			.setFontSize(fS)
			.setColor(dR,dG,dB)
			.setText("10");
			
		m.r5_left = m.radar_group.createChild("text", "5 horiz left")
			.setTranslation(316,595)
			.setAlignment("center-center")
			.setFont("LiberationFonts/LiberationMono-Regular.ttf")
			.setFontSize(fS)
			.setColor(dR,dG,dB)
			.setText("5");
			
		m.r10_right = m.radar_group.createChild("text", "10 horiz right")
			.setTranslation(871,595)
			.setAlignment("center-center")
			.setFont("LiberationFonts/LiberationMono-Regular.ttf")
			.setFontSize(fS)
			.setColor(dR,dG,dB)
			.setText("10");
			
		m.r5_right = m.radar_group.createChild("text", "5 horiz right")
			.setTranslation(696,595)
			.setAlignment("center-center")
			.setFont("LiberationFonts/LiberationMono-Regular.ttf")
			.setFontSize(fS)
			.setColor(dR,dG,dB)
			.setText("5");
			
		#paths - top lines
		m.vertlinetop1 = m.radar_group.createChild("path", "top1-vert")
			.move(0,(lL/2)-lL)
			.line(0,lL/2)
			.setColor(dR,dG,dB)
			.setStrokeLineWidth(lW)
			.setStrokeLineCap("round")
			.setTranslation(180,140);

		m.vertlinetop4 = m.radar_group.createChild("path", "top4-vert")
			.move(0,(lL/2)-lL)
			.line(0,lL/2)
			.setColor(dR,dG,dB)
			.setStrokeLineWidth(lW)
			.setStrokeLineCap("round")
			.setTranslation(398,140);
			
		m.vertlinetop4 = m.radar_group.createChild("path", "top4-vert")
			.move(0,(lL/2)-lL)
			.line(0,lL/2)
			.setColor(dR,dG,dB)
			.setStrokeLineWidth(lW)
			.setStrokeLineCap("round")
			.setTranslation(616,140);
			
		m.vertlinetop4 = m.radar_group.createChild("path", "top4-vert")
			.move(0,(lL/2)-lL)
			.line(0,lL/2)
			.setColor(dR,dG,dB)
			.setStrokeLineWidth(lW)
			.setStrokeLineCap("round")
			.setTranslation(834,140);
			
		#paths - middle vertical lines	
		m.vertlinemid1 = m.radar_group.createChild("path", "mid1-vert")
			.move(0,(lL/2)-lL)
			.line(0,lL/2)
			.setColor(dR,dG,dB)
			.setStrokeLineWidth(lW)
			.setStrokeLineCap("round")
			.setTranslation(141,555);
			
		m.vertlinemid2 = m.radar_group.createChild("path", "mid2-vert")
			.move(0,(lL/2)-lL)
			.line(0,lL/2)
			.setColor(dR,dG,dB)
			.setStrokeLineWidth(lW)
			.setStrokeLineCap("round")
			.setTranslation(316,555);
			
		m.vertlinemid3 = m.radar_group.createChild("path", "mid3-vert")
			.move(0,(lL/2)-lL)
			.line(0,lL/2)
			.setColor(dR,dG,dB)
			.setStrokeLineWidth(lW)
			.setStrokeLineCap("round")
			.setTranslation(871,555);

		m.vertlinemid4 = m.radar_group.createChild("path", "mid4-vert")
			.move(0,(lL/2)-lL)
			.line(0,lL/2)
			.setColor(dR,dG,dB)
			.setStrokeLineWidth(lW)
			.setStrokeLineCap("round")
			.setTranslation(696,555);

		#paths - horizontal lines
		m.horizline30L = m.radar_group.createChild("path", "line30L")
			.move((lL/2)-lL,0)
			.line(lL/2,0)
			.setColor(dR,dG,dB)
			.setStrokeLineWidth(lW)
			.setStrokeLineCap("round")
			.setTranslation(456,90);
			
		m.horizline30R = m.radar_group.createChild("path", "line30R")
			.move((lL/2)-lL,0)
			.line(lL/2,0)
			.setColor(dR,dG,dB)
			.setStrokeLineWidth(lW)
			.setStrokeLineCap("round")
			.setTranslation(596,90);

		m.horizline20L = m.radar_group.createChild("path", "line20L")
			.move((lL/2)-lL,0)
			.line(lL/2,0)
			.setColor(dR,dG,dB)
			.setStrokeLineWidth(lW)
			.setStrokeLineCap("round")
			.setTranslation(186,377);
			
		m.horizline20R = m.radar_group.createChild("path", "line20R")
			.move((lL/2)-lL,0)
			.line(lL/2,0)
			.setColor(dR,dG,dB)
			.setStrokeLineWidth(lW)
			.setStrokeLineCap("round")
			.setTranslation(868,377);
			
		m.horizline10L = m.radar_group.createChild("path", "line10L")
			.move((lL/2)-lL,0)
			.line(lL/2,0)
			.setColor(dR,dG,dB)
			.setStrokeLineWidth(lW)
			.setStrokeLineCap("round")
			.setTranslation(186,663);
			
		m.horizline10R = m.radar_group.createChild("path", "line10R")
			.move((lL/2)-lL,0)
			.line(lL/2,0)
			.setColor(dR,dG,dB)
			.setStrokeLineWidth(lW)
			.setStrokeLineCap("round")
			.setTranslation(868,663);

		#middle box
		m.lockbox = m.radar_group.createChild("path", "lockbox")
			.move(-20,0)
			.line(-30,0)
			.line(0,-573)
			.line(30,0)
			.move(40,0)
			.line(30,0)
			.line(0,573)
			.line(-30,0)
			.setColor(dR,dG,dB)
			.setStrokeLineWidth(lW)
			.setStrokeLineCap("round")
			.setTranslation(506,950);
			
		#triangle dealios
		m.triangle1 = m.radar_group.createChild("path", "triangle1")
			.line(-20,0)
			.line(20,-34.6)
			.line(20,34.6)
			.line(-20,0)
			.setColor(dR,dG,dB)
			.setStrokeLineWidth(lW)
			.setStrokeLineCap("round")
			.setTranslation(180,900);

		m.triangle2 = m.radar_group.createChild("path", "triangle2")
			.line(-20,0)
			.line(20,-34.6)
			.line(20,34.6)
			.line(-20,0)
			.setColor(dR,dG,dB)
			.setStrokeLineWidth(lW)
			.setStrokeLineCap("round")
			.setTranslation(398,970);
			
		m.triangle3 = m.radar_group.createChild("path", "triangle3")
			.line(-20,0)
			.line(20,-34.6)
			.line(20,34.6)
			.line(-20,0)
			.setColor(dR,dG,dB)
			.setStrokeLineWidth(lW)
			.setStrokeLineCap("round")
			.setTranslation(616,970);

		m.triangle4 = m.radar_group.createChild("path", "triangle4")
			.line(-20,0)
			.line(20,-34.6)
			.line(20,34.6)
			.line(-20,0)
			.setColor(dR,dG,dB)
			.setStrokeLineWidth(lW)
			.setStrokeLineCap("round")
			.setTranslation(834,900);
		
		#lock bars
		m.lowerBar = m.radar_group.createChild("path","lowerBar")
			.move(-50,0)
			.line(100,0)
			.setColor(dR,dG,dB)
			.setStrokeLineWidth(lW + 2)
			.setStrokeLineCap("round")
			.setTranslation(506,950);
			
		m.upperBar = m.radar_group.createChild("path","upperBar")
			.move(-50,0)
			.line(100,0)
			.setColor(dR,dG,dB)
			.setStrokeLineWidth(lW + 2)
			.setStrokeLineCap("round")
			.setTranslation(506,750);
		
		# radar contacts
		m.below_blip = [];
		m.even_blip = [];
		m.above_blip = [];
		m.blip_text = [];
		for(var i=0; i < m.no_blip; i = i+1) {
			var b_blip = m.blips.createChild("path", "b_blip" ~ i)
			.move(-30,0)
			.line(60,0)
			.move(-30,0)
			.line(0,60)
			.setStrokeLineWidth(lW)
			.setColor(dR, dG, dB);
			
			var e_blip = m.blips.createChild("path", "e_blip" ~ i)
			.move(-30,0)
			.line(60,0)
			.move(-30,-30)
			.line(0,60)
			.setStrokeLineWidth(lW)
			.setColor(dR, dG, dB);
			
			var a_blip = m.blips.createChild("path", "a_blip" ~ i)
			.move(-30,0)
			.line(60,0)
			.move(-30,0)
			.line(0,-60)
			.setStrokeLineWidth(lW)
			.setColor(dR, dG, dB);
			
			var blip_text = m.blips.createChild("text", "blip_text" ~ i)
				.setFont("liberationFonts/LiberationMono-Regular.ttf")
				.setColor(dR, dG, dB)
				.setFontSize(fS);

			b_blip.hide();
			e_blip.hide();
			a_blip.hide();
			blip_text.hide();
			
			append(m.below_blip,b_blip);
			append(m.even_blip,e_blip);
			append(m.above_blip,a_blip);
			append(m.blip_text,blip_text);
		}
		m.lock = m.radar_group.createChild("path") #probably will never use this
               .move(-40,0)
			   .arcSmallCW(40,40,0,80,0)
			   .arcSmallCW(40,40,0,-80,0)
               .setStrokeLineWidth(lW)
               .setColor(dR, dG, dB);
		m.update();
	},
	update: func() {
	
		var mode = getprop(radar_mode);
		
		if ( mode == "off" ) {
		
			foreach(var elem; me.radar_group.getChildren()) {
				elem.hide();
			}
			
			foreach(var elem; me.blips.getChildren()) {
				elem.hide();
			}
			
			foreach(var elem; me.dumb.getChildren()) {
				elem.hide();
			}
	
		} elsif ( mode == "test" ) {
		
		} elsif ( mode == "normal-init" ) {
		
			foreach(var elem; me.radar_group.getChildren()) {
				elem.show();
			}
			setprop(radar_mode, "normal");
		
		} elsif ( mode == "normal" ) {
		
			#used from Necolatis' Saab 37 Viggen
			#print("updating radar screen");
			var b_i=0;
			var lock = FALSE;
			
			#process locking bars
			#950 is bottom limit
			#377 is upper limit
			
			#precalculate requested position
			#scale takes precedence over position
			#lower limit is lpos = 0
			#upper limit is upper-bound = 377
			var lscale = getprop(lock_bars_scale);
			var lpos = getprop(lock_bars_pos);
			
			lscale = clamp(lscale, 50, 250);
			lpos = clamp(lpos, 0, 900);

			if ( 950 - ( lscale + lpos ) < 376 ) {
				lpos =(950 - 377) - lscale;
			} elsif ( lpos < 0 ) {
				lpos = 0;
			}
			
			setprop(lock_bars_scale, lscale);
			setprop(lock_bars_pos, lpos);
			
			me.lowerBar.setTranslation(506, 950 - lpos);
			me.upperBar.setTranslation(506, 950 - ( lpos + lscale ));
			
			if ( getprop("controls/radar/power-panel/fixed-beam") == 0 ) {
				foreach (var mp; radar_logic.tracks) {	
					#print("found contact");
					# Node with valid position data (and "distance!=nil").
					var p = mp.get_polar();
					var distance = p[0];
					var xa_rad = p[3];
					var ya_ang = p[2] * R2D;

					#make blip
					if (b_i < me.no_blip and distance != nil and distance < me.radar_range ){#and alt-100 > getprop("/environment/ground-elevation-m")){
						#print("contact is valid");
						#aircraft is within the radar ray cone
						#var locked = FALSE;
						#if (mp.isPainted() == TRUE) {
						#	lock = TRUE;
						#	locked = TRUE;
						#}
						# plot the blip on the radar screen
						var pixelDistance = -distance*((950-90)/me.radar_range); #distance in pixels

						#translate from polar coords to cartesian coords
						#var pixelX =  pixelDistance * math.cos(xa_rad + math.pi/2) + 1024/2;
						#var pixelY =  pixelDistance * math.sin(xa_rad + math.pi/2) + 950;
						var pixelX = ((xa_rad * R2D / RADAR_LEFT_LIMIT) * -506) + 506; #506 is half width of radar screen
						var pixelY = pixelDistance + 950;
						pixelX = clamp(pixelX, 180, 836);
						pixelY = clamp(pixelY, 100,950);
						
						#print("X,Y: " ~ pixelX ~ "," ~ pixelY);
						#print("pixel blip ("~pixelX~", "~pixelY);
						if ( ya_ang > 1.5 ) {
							me.above_blip[b_i].setTranslation(pixelX, pixelY);
							me.above_blip[b_i].show();
							me.even_blip[b_i].hide();
							me.below_blip[b_i].hide();
						} elsif ( ya_ang < -1.5 ) {
							me.below_blip[b_i].setTranslation(pixelX, pixelY);
							me.below_blip[b_i].show();
							me.even_blip[b_i].hide();
							me.above_blip[b_i].hide();
						} else {
							me.even_blip[b_i].setTranslation(pixelX, pixelY);
							me.even_blip[b_i].show();
							me.below_blip[b_i].hide();
							me.above_blip[b_i].hide();
						}
						if ( getprop(show_callsigns) == 1 ) {
							#print("pixelX = " ~ pixelX);
							if ( pixelX <= 506 ) {
								me.blip_text[b_i].setTranslation(pixelX - 50, pixelY);
								me.blip_text[b_i].setText(mp.get_Callsign());
								me.blip_text[b_i].setAlignment("right-center");
								me.blip_text[b_i].show();
							} else {
							me.blip_text[b_i].setTranslation(pixelX + 50, pixelY);
								me.blip_text[b_i].setText(mp.get_Callsign());
								me.blip_text[b_i].setAlignment("left-center");
								me.blip_text[b_i].show();
							}
						} else {
							me.blip_text[b_i].hide();
						}
						#if (locked == TRUE) {
						#	pixelXL = pixelX;
						#	pixelYL = pixelY;
						#}
					}
					b_i += 1;
				}
			}
			#if (lock == FALSE) {
			#	me.lock.hide();
			#} else {
			#	me.lock.setTranslation(pixelXL, pixelYL);
			#	me.lock.show();
			#}
			for ( i = b_i; i < me.no_blip; i += 1 ) {
				me.even_blip[b_i].hide();
				me.below_blip[b_i].hide();
				me.above_blip[b_i].hide();
				me.blip_text[b_i].hide();
			}
			
		} elsif ( mode == "locked-init" ) {
			foreach(var elem; me.radar_group.getChildren()) {
				elem.hide();
			}
			
			foreach(var elem; me.blips.getChildren()) {
				elem.hide();
			}
			
			foreach(var elem; me.dumb.getChildren()) {
				elem.hide();
			}
			
			setprop(radar_mode, "locked");
			
		} elsif ( mode == "locked" ) {
			#locked-on radar screen
			var locked_target = radar_logic.selection;
			if ( locked_target != nil ) {
				var dist_rad = locked_target.get_polar();
				if ( dist_rad[0] > me.radar_range or math.abs(dist_rad[1] * R2D) > 15 or math.abs(dist_rad[2] * R2D) > 15 or locked_target.isValid() == 0 ) { #if the target is out of lockon range, then exit locked-mode
					setprop(radar_mode,"normal-init");
					radar_logic.unlockTarget();
				} else {
					var ya_ang = dist_rad[2] * R2D;
					#switch from an overhead view to a forward facing view.
					#the blip will move according to angle, instead of distance
					#ar pixelX = ((xa_rad * R2D / RADAR_LEFT_LIMIT) * -506) + 506; #506 is half width of radar screen
					var pixelX = ((dist_rad[1] * R2D / 15) * 506) + 506; #506 is half width of radar screen, and 180 is starting from the left, go over this much
					#var pixelY = ((ya_ang * R2D) / 5) * 425 + 100; #425 is half vertically, 100 is starting from the top
					var pixelY = ((ya_ang / 15) * -425) + 425; #506 is half width of radar screen
					pixelX = clamp(pixelX, 180, 836);
					pixelY = clamp(pixelY, 100,950);
					
					#print("X,Y: " ~ pixelX ~ "," ~ pixelY);
					#print("pixel blip ("~pixelX~", "~pixelY);
					#print(ya_ang);
					if ( ya_ang > 1.5 ) {
						me.above_blip[1].setTranslation(pixelX, pixelY);
						me.above_blip[1].show();
						me.even_blip[1].hide();
						me.below_blip[1].hide();
					} elsif ( ya_ang < -1.5 ) {
						me.below_blip[1].setTranslation(pixelX, pixelY);
						me.below_blip[1].show();
						me.even_blip[1].hide();
						me.above_blip[1].hide();
					} else {
						me.even_blip[1].setTranslation(pixelX, pixelY);
						me.even_blip[1].show();
						me.below_blip[1].hide();
						me.above_blip[1].hide();
					}
					if ( getprop(show_callsigns) == 1 ) {
						#print("pixelX = " ~ pixelX);
						if ( pixelX <= 506 ) {
							me.blip_text[1].setTranslation(pixelX - 50, pixelY);
							me.blip_text[1].setText(locked_target.get_Callsign());
							me.blip_text[1].setAlignment("right-center");
							me.blip_text[1].show();
						} else {
							me.blip_text[1].setTranslation(pixelX + 50, pixelY);
							me.blip_text[1].setText(locked_target.get_Callsign());
							me.blip_text[1].setAlignment("left-center");
							me.blip_text[1].show();
						}
					} else {
						me.blip_text[1].hide();
					}
				}
			} else {
				setprop(radar_mode,"normal-init");
				radar_logic.unlockTarget();
			}
		}
			
		settimer(func { me.update(); }, 0.10);
    },
};

var init = setlistener("/sim/signals/fdm-initialized", func() {
  #print("inniting");
  removelistener(init); # only call once
  var rad = radar_screen.new({"node": "radarDisplay"});
#  var hud_copilot = HUD.new({"node": "HUD.l.canvas.001"});
#  hud_copilot.update();
});

var on_off = func() {
	if ( getprop("controls/radar/power-panel/run") == 0 ) {
		setprop(radar_mode, "off");
	} else {
		setprop(radar_mode, "normal-init");
	}
}

setlistener("controls/radar/power-panel/run", func { on_off(); });
on_off();
	
