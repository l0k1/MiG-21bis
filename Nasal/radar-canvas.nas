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
var iff_control = "/controls/radar/panel/iff";

var radarRange = radar_logic.radarRange;
var radarRange10k = radarRange / 1000;
var distanceMarker_pixels_per_m = 175 / (radarRange / 6);

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
		m.scan_mode = m.radar_canvas.createGroup();
		m.autotrack_mode = m.radar_canvas.createGroup();
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
			.setTranslation(141,580)
			.setAlignment("center-center")
			.setFont("LiberationFonts/LiberationMono-Regular.ttf")
			.setFontSize(fS)
			.setColor(dR,dG,dB)
			.setText(int(radarRange10k/3));
			
		m.r5_left = m.radar_group.createChild("text", "5 horiz left")
			.setTranslation(316,580)
			.setAlignment("center-center")
			.setFont("LiberationFonts/LiberationMono-Regular.ttf")
			.setFontSize(fS)
			.setColor(dR,dG,dB)
			.setText(int(radarRange10k/3/2));
			
		m.r10_right = m.radar_group.createChild("text", "10 horiz right")
			.setTranslation(871,580)
			.setAlignment("center-center")
			.setFont("LiberationFonts/LiberationMono-Regular.ttf")
			.setFontSize(fS)
			.setColor(dR,dG,dB)
			.setText(int(radarRange10k/3));
			
		m.r5_right = m.radar_group.createChild("text", "5 horiz right")
			.setTranslation(696,580)
			.setAlignment("center-center")
			.setFont("LiberationFonts/LiberationMono-Regular.ttf")
			.setFontSize(fS)
			.setColor(dR,dG,dB)
			.setText(int(radarRange10k/3/2));
			
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
			.move(0,(lL/2)-lL) # 80 / 2 - 80 = 40 - 80 = -40
			.line(0,lL/2) # draw a line from set point to 40 pixels up
			.setColor(dR,dG,dB) #520 should be at center, so 540
			.setStrokeLineWidth(lW) #15 pix up
			.setStrokeLineCap("round")
			.setTranslation(141,540);
			
		m.vertlinemid2 = m.radar_group.createChild("path", "mid2-vert")
			.move(0,(lL/2)-lL)
			.line(0,lL/2)
			.setColor(dR,dG,dB)
			.setStrokeLineWidth(lW)
			.setStrokeLineCap("round")
			.setTranslation(316,540);
			
		m.vertlinemid3 = m.radar_group.createChild("path", "mid3-vert")
			.move(0,(lL/2)-lL)
			.line(0,lL/2)
			.setColor(dR,dG,dB)
			.setStrokeLineWidth(lW)
			.setStrokeLineCap("round")
			.setTranslation(871,540);

		m.vertlinemid4 = m.radar_group.createChild("path", "mid4-vert")
			.move(0,(lL/2)-lL)
			.line(0,lL/2)
			.setColor(dR,dG,dB)
			.setStrokeLineWidth(lW)
			.setStrokeLineCap("round")
			.setTranslation(696,540);

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
			.move(-20,0) #486,950
			.line(-30,0) #456,950
			.line(0,-573) #456,377
			.line(30,0) #486,377
			.move(40,0) #526,377
			.line(30,0) #556,377
			.line(0,573) #556,950
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
			
		#target pointer and circle
		m.target_pointer = m.radar_group.createChild("path", "target_pointer")
			.move(-45,0)
			.line(90,0)
			.move(-45,-30)
			.line(0,60)
			.setStrokeLineWidth(lW + 1)
			.setColor(dR, dG, dB)
			.setTranslation(506,520);
		
		m.target_circle = m.radar_group.createChild("path", "target_circle")
			.move(-50,0)
			.arcSmallCW(50,50,0,100,0)
			.arcSmallCW(50,50,0,-100,0)
			.setStrokeLineWidth(lW)
			.setColor(dR, dG, dB)
			.setTranslation(506,520);
		
		#lock bars
		m.lowerBar = m.scan_mode.createChild("path","lowerBar")
			.move(-50,0)
			.line(100,0)
			.setColor(dR,dG,dB)
			.setStrokeLineWidth(lW + 2)
			.setStrokeLineCap("round")
			.setTranslation(506,950);
			
		m.upperBar = m.scan_mode.createChild("path","upperBar")
			.move(-50,0)
			.line(100,0)
			.setColor(dR,dG,dB)
			.setStrokeLineWidth(lW + 2)
			.setStrokeLineCap("round")
			.setTranslation(506,750);
			
		#distance bars
		m.leftDistanceBar = m.autotrack_mode.createChild("path","leftDistanceBar")
			# y is 520, x1 is 100, x2 is 390
			.line(290,0)
			.setColor(dR,dG,dB)
			.setStrokeLineWidth(lW + 1)
			.setStrokeLineCap("round")
			.setTranslation(100,520);
			
		m.rightDistanceBar = m.autotrack_mode.createChild("path","rightDistanceBar")
			#y is 520, x1 is 622, x2 is 912
			.line(290,0)
			.setColor(dR,dG,dB)
			.setStrokeLineWidth(lW + 1)
			.setStrokeLineCap("round")
			.setTranslation(622,520);
			
		#distance markers
		m.leftDistanceMarker = m.autotrack_mode.createChild("path","leftDistanceMarker")
			# in the code below, Y should always be at 520
			.line(-15,0)
			.line(15,-40)
			.line(15,40)
			.line(-15,0)
			.setColor(dR,dG,dB)
			.setStrokeLineWidth(lW+3)
			.setStrokeLineCap("round");
			
		m.rightDistanceMarker = m.autotrack_mode.createChild("path","rightDistanceMarker")
			# in the code below, Y should always be at 520
			.line(-15,0)
			.line(15,-40)
			.line(15,40)
			.line(-15,0)
			.setColor(dR,dG,dB)
			.setStrokeLineWidth(lW+3)
			.setStrokeLineCap("round");
		
		# radar contacts
		m.below_blip = [];
		m.even_blip = [];
		m.above_blip = [];
		m.f_addon_blip = [];
		m.blip_text = [];
		for(var i=0; i < m.no_blip; i = i+1) {
			# below blip
			var b_blip = m.blips.createChild("path", "b_blip" ~ i)
			.move(-30,0)
			.line(60,0)
			.move(-30,0)
			.line(0,60)
			.setStrokeLineWidth(lW)
			.setColor(dR, dG, dB);
			
			# even blip
			var e_blip = m.blips.createChild("path", "e_blip" ~ i)
			.move(-30,0)
			.line(60,0)
			.move(-30,-30)
			.line(0,60)
			.setStrokeLineWidth(lW)
			.setColor(dR, dG, dB);
			
			# above blip
			var a_blip = m.blips.createChild("path", "a_blip" ~ i)
			.move(-30,0)
			.line(60,0)
			.move(-30,0)
			.line(0,-60)
			.setStrokeLineWidth(lW)
			.setColor(dR, dG, dB);
			
			#friendly addition
			var f_addon = m.blips.createChild("path", "f_add" ~ i)
			.move(-30,-10)
			.line(60,0)
			.setStrokeLineWidth(lW)
			.setColor(dR, dG, dB);
			
			
			var blip_text = m.blips.createChild("text", "blip_text" ~ i)
				.setFont("liberationFonts/LiberationMono-Regular.ttf")
				.setColor(dR, dG, dB)
				.setFontSize(fS);

			b_blip.hide();
			e_blip.hide();
			a_blip.hide();
			f_addon.hide();
			blip_text.hide();
			
			append(m.below_blip,b_blip);
			append(m.even_blip,e_blip);
			append(m.above_blip,a_blip);
			append(m.f_addon_blip,f_addon);
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

		#print("updating radar, mode: " ~ mode);
		
		if ( mode == "off" ) {
			
			me.radar_group.hide();
			me.scan_mode.hide();
			me.autotrack_mode.hide();
			me.blips.hide();
			me.dumb.hide();
	
		} elsif ( mode == "test" ) {
		
		} elsif ( mode == "normal-init" ) {
			
			me.radar_group.show();
			me.scan_mode.show();
			me.blips.show();
			foreach (var blip; me.blips.getChildren()) {
				blip.hide();
			}
			me.autotrack_mode.hide();
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
			
			if (getprop("controls/radar/power-panel/fixed-beam")) {
				lpos = 330;
				lscale = 200;
			}
			
			me.lowerBar.setTranslation(506, 950 - lpos);
			me.upperBar.setTranslation(506, 950 - ( lpos + lscale ));
			
			if ( getprop("controls/radar/power-panel/fixed-beam") == 0  and getprop("fdm/jsbsim/radar/mode") == 2) {
				foreach (var mp; radar_logic.tracks) {	
					#print("found contact");
					# Node with valid position data (and "distance!=nil").
					var p = mp.get_polar();
					var distance = p[0];
					var xa_rad = p[3];
					var ya_ang = p[2] * R2D;

					#make blip
					if (b_i < me.no_blip and distance != nil and distance < me.radar_range ){ #and alt-100 > getprop("/environment/ground-elevation-m")){
						#print("contact is valid");
						#aircraft is within the radar ray cone
						#var locked = FALSE;
						#if (mp.isPainted() == TRUE) {
						#	lock = TRUE;
						#	locked = TRUE;
						#}
						# plot the blip on the radar screen
						var pixelDistance = -distance*((950)/me.radar_range); #distance in pixels

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
							if (iff.interrogate(mp.getNode())) {
								 me.f_addon_blip[b_i].show();
							}
						} else {
							me.blip_text[b_i].hide();
							me.f_addon_blip[b_i].hide();
						}
						#if (locked == TRUE) {
						#	pixelXL = pixelX;
						#	pixelYL = pixelY;
						#}
					}
					b_i += 1;
				}
			} else {
				if (radar_logic.selection != nil) {
					var p = radar_logic.selection.get_polar();
					var distance = p[0];
					var xa_rad = p[3];
					var ya_ang = p[2] * R2D;
					if (distance != nil and distance < me.radar_range ){
						var pixelDistance = -distance*((950)/me.radar_range); #distance in pixels
						#translate from polar coords to cartesian coords
						var pixelX = ((xa_rad * R2D / RADAR_LEFT_LIMIT) * -506) + 506; #506 is half width of radar screen
						var pixelY = pixelDistance + 950;
						pixelX = clamp(pixelX, 180, 836);
						pixelY = clamp(pixelY, 100,950);
						
						me.even_blip[0].setTranslation(pixelX, pixelY);
						me.even_blip[0].show();
						me.below_blip[0].hide();
						me.above_blip[0].hide();
						me.f_addon_blip[b_i].hide();
						
						if ( getprop(show_callsigns) == 1 ) {
							if ( pixelX <= 506 ) {
								me.blip_text[b_i].setTranslation(pixelX - 50, pixelY);
								me.blip_text[b_i].setText(radar_logic.selection.get_Callsign());
								me.blip_text[b_i].setAlignment("right-center");
								me.blip_text[b_i].show();
							} else {
							me.blip_text[b_i].setTranslation(pixelX + 50, pixelY);
								me.blip_text[b_i].setText(radar_logic.selection.get_Callsign());
								me.blip_text[b_i].setAlignment("left-center");
								me.blip_text[b_i].show();
							}
						} else {
							me.blip_text[b_i].hide();
						}
					}
					b_i = 1;
				} else {
					b_i = 0;
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
			me.radar_group.show();
			me.autotrack_mode.show();
			me.scan_mode.hide();
			me.blips.show();
			foreach (var blip; me.blips.getChildren()) {
				blip.hide();
			}
			me.dumb.hide();
			
			setprop(radar_mode, "locked");
			
		} elsif ( mode == "locked" ) {
			#locked-on radar screen
			var locked_target = radar_logic.selection;
			if ( locked_target != nil ) {
				var dist_rad = locked_target.get_polar();
				if ( dist_rad[0] > me.radar_range or math.abs(dist_rad[1] * R2D) > 15 or math.abs(dist_rad[2] * R2D) > 15 or locked_target.isValid() == 0 ) { #if the target is out of lockon range, then exit locked-mode
					#print("exit1");
					setprop(radar_mode,"normal-init");
					arm_locking.unlockTarget();
				} else {
					var ya_ang = dist_rad[2] * R2D;
					#switch from an overhead view to a forward facing view.
					#the blip will move according to angle, instead of distance
					#ar pixelX = ((xa_rad * R2D / RADAR_LEFT_LIMIT) * -506) + 506; #506 is half width of radar screen
					var pixelX = ((dist_rad[1] * R2D / 15) * 506) + 506; #506 is half width of radar screen, and 180 is starting from the left, go over this much
					#var pixelY = ((ya_ang * R2D) / 5) * 425 + 100; #425 is half vertically, 100 is starting from the top
					var pixelY = ((ya_ang / 15) * -425) + 520; #520 is half width of radar screen
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
					
					#491 and 521 are where the "0" distance marks would be
					#100, 440, 602, and 912 are arbitrarily selected for the min/max of the distance triangle.
					me.leftDistanceMarker.setTranslation(math.clamp(dist_rad[0] * -distanceMarker_pixels_per_m + 491,100,440),520);
					me.rightDistanceMarker.setTranslation(math.clamp(dist_rad[0] * distanceMarker_pixels_per_m + 521,602,912),520);
				}
			} else {
				#print("exit2");
				setprop(radar_mode,"normal-init");
				arm_locking.unlockTarget();
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
		#print("exit3");
		setprop(radar_mode, "normal-init");
	}
}


var interp = func(x, x0, x1, y0, y1) {
    return y0 + (x - x0) * ((y1 - y0) / (x1 - x0));
}

setlistener("controls/radar/power-panel/run", func { on_off(); });
on_off();
