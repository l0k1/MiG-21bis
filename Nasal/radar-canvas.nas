var dR = 0.823; #display red value
var dG = 0.902; #display green value
var dB = 0.118; #display blue value
var fS = 60;	#font size
var lL = 80;	#line length (it's a little case L, not a [one])
var lW = 4;		#line width

var clamp = func(v, min, max) { v < min ? min : v > max ? max : v }

var FALSE = 0;
var TRUE  = 1;


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
		
		m.radar_range = 60000; #radar range in meters - should be set by properties at some point
		m.no_blip=20; # max number of blips
		
		#radar canvas
	
		m.radar_canvas.addPlacement(placement);
		m.radar_canvas.setColorBackground(0.100,0.161,0.106,1);

		m.radar_group = m.radar_canvas.createGroup();

		m.pinto_rulez = m.radar_group.createChild("text", "pinto rulez")
			.setTranslation(506, 200)      # The origin is in the top left corner
			.setAlignment("center-center") # All values from osgText are supported (see $FG_ROOT/Docs/README.osgtext)
			.setFont("LiberationFonts/LiberationMono-Regular.ttf") # Fonts are loaded either from $AIRCRAFT_DIR/Fonts or $FG_ROOT/Fonts
			.setFontSize(64, 1.2)        # Set fontsize and optionally character aspect ratio
			.setColor(dR,dG,dB)             # Text color
			.setText("pinto rulez");
		m.xruler = m.radar_group.createChild("text", "pinto rulez 2")
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
			.setText("60");
			
		m.m20_left = m.radar_group.createChild("text", "20 distance marker left")
			.setTranslation(96,377)
			.setAlignment("center-center")
			.setFont("LiberationFonts/LiberationMono-Regular.ttf")
			.setFontSize(fS)
			.setColor(dR,dG,dB)
			.setText("40");

		m.m20_right = m.radar_group.createChild("text", "20 distance marker right")
			.setTranslation(918,377)
			.setAlignment("center-center")
			.setFont("LiberationFonts/LiberationMono-Regular.ttf")
			.setFontSize(fS)
			.setColor(dR,dG,dB)
			.setText("40");
			
		m.m10_left = m.radar_group.createChild("text", "10 distance marker left")
			.setTranslation(96,663)
			.setAlignment("center-center")
			.setFont("LiberationFonts/LiberationMono-Regular.ttf")
			.setFontSize(fS)
			.setColor(dR,dG,dB)
			.setText(20);
			
		m.m10_right = m.radar_group.createChild("text", "10 distance marker right")
			.setTranslation(918,663)
			.setAlignment("center-center")
			.setFont("LiberationFonts/LiberationMono-Regular.ttf")
			.setFontSize(fS)
			.setColor(dR,dG,dB)
			.setText(20);
			
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
			
		# radar contacts
		m.below_blip = [];
		m.even_blip = [];
		m.above_blip = [];
		for(var i=0; i < m.no_blip; i = i+1) {
			var b_blip = m.radar_group.createChild("path")
			.move(-30,0)
			.line(60,0)
			.move(-30,0)
			.line(0,60)
			.setStrokeLineWidth(lW)
			.setColor(dR, dG, dB);
			
			var e_blip = m.radar_group.createChild("path")
			.move(-30,0)
			.line(60,0)
			.move(-30,-30)
			.line(0,60)
			.setStrokeLineWidth(lW)
			.setColor(dR, dG, dB);
			
			var a_blip = m.radar_group.createChild("path")
			.move(-30,0)
			.line(60,0)
			.move(-30,0)
			.line(0,-60)
			.setStrokeLineWidth(lW)
			.setColor(dR, dG, dB);

			b_blip.hide();
			e_blip.hide();
			a_blip.hide();
			
			append(m.below_blip,b_blip);
			append(m.even_blip,e_blip);
			append(m.above_blip,a_blip);
		}
		m.lock = m.radar_group.createChild("path")
               .move(-40,0)
			   .arcSmallCW(40,40,0,80,0)
			   .arcSmallCW(40,40,0,-80,0)
               .setStrokeLineWidth(lW)
               .setColor(dR, dG, dB);
		print("done setting up canvaso!");
		m.update();
	},
	update: func() {
		#used from Necolatis' Saab 37 Viggen
		#print("updating radar screen");
        var b_i=0;
        var lock = FALSE;
        foreach (var mp; radar_logic.tracks) {	
			#print("found contact");
			# Node with valid position data (and "distance!=nil").

			var distance = mp.get_polar()[0];
			var xa_rad = mp.get_polar()[1];
			var alt_diff = mp.get_altitude() - getprop("/position/altitude-ft");

			#make blip
			if (b_i < me.no_blip and distance != nil and distance < me.radar_range ){#and alt-100 > getprop("/environment/ground-elevation-m")){
				#print("contact is valid");
				#aircraft is within the radar ray cone
				var locked = FALSE;
				if (mp.isPainted() == TRUE) {
					lock = TRUE;
					locked = TRUE;
				}
				#aircraft is between the current stroke and the previous stroke position
				# plot the blip on the radar screen
				var pixelDistance = -distance*((950-90)/me.radar_range); #distance in pixels

				#translate from polar coords to cartesian coords
				var pixelX =  pixelDistance * math.cos(xa_rad + math.pi/2) + 1024/2;
				var pixelY =  pixelDistance * math.sin(xa_rad + math.pi/2) + 950;
				#print("pixel blip ("~pixelX~", "~pixelY);
				if ( alt_diff > 1000 ) {
					me.above_blip[b_i].setTranslation(pixelX, pixelY);
					me.above_blip[b_i].show();
					me.even_blip[b_i].hide();
					me.below_blip[b_i].hide();
				} elsif ( alt_diff < -1000 ) {
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
				if (locked == TRUE) {
					pixelXL = pixelX;
					pixelYL = pixelY;
				}
			}
			b_i += 1;
        }
        if (lock == FALSE) {
			me.lock.hide();
        } else {
			me.lock.setTranslation(pixelXL, pixelYL);
			me.lock.show();
        }
		for ( i = b_i; i < me.no_blip; i += 1 ) {
			me.even_blip[b_i].hide();
			me.below_blip[b_i].hide();
			me.above_blip[b_i].hide();
		}
		
		settimer(func { me.update(); }, 0.15);
    },
};

var init = setlistener("/sim/signals/fdm-initialized", func() {
  #print("inniting");
  removelistener(init); # only call once
  var rad = radar_screen.new({"node": "radarDisplay"});
#  var hud_copilot = HUD.new({"node": "HUD.l.canvas.001"});
#  hud_copilot.update();
});
