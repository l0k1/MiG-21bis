
var clamp = func(v, min, max) { v < min ? min : v > max ? max : v }

var FALSE = 0;
var TRUE  = 1;

var update_rate = 0.1;

var RADAR_SCREEN = {
    new: func(placement,name){
        var m = {parents: [RADAR_SCREEN]};
        m.radar_canvas = canvas.new({
                                        "name": name,   # The name is optional but allow for easier identification
                                        "size": [1024, 1024], # Size of the underlying texture (should be a power of 2, required) [Resolution]
                                        "view": [1024, 1024],  # Virtual resolution (Defines the coordinate system of the canvas [Dimensions]
                                        # which will be stretched the size of the texture, required)
                                        "mipmapping": 1       # Enable mipmapping (optional)
                                        });
        m.radar_canvas.addPlacement(placement);
        
        # state information
        m.cur_main_func = nil;
        m.cur_init_func = nil;
        m.cur_end_func = nil;
        m.cur_state = nil;

        # default settings
        m.aec = [0.823, 0.902, 0.118]; # active element color
        m.bgc = [0.1, 0.161, 0.106, 1.00]; # background color
        m.fS = 60;    #font size
        m.lL = 80;    #line length (it's a little case L, not a [one])
        m.lW = 4;     #line width

        me.lscale = 0;
        me.lpos = 0;
        
        m.contact_line_length = 60;
        m.contact_array = [];

        m.font = "LiberationFonts/LiberationMono-Regular.ttf";

        # properties
        m.lock_bars_scale = "/controls/radar/lock-bars-scale";
        m.lock_bars_pos = "/controls/radar/lock-bars-pos";
        m.iff_button = "/controls/radar/panel/iff";
        m.iff_control = "/controls/radar/panel/iff";

        # needed info
        m.radar_range = radar_logic.radarRange;
        m.radarRange10k = m.radar_range / 1000;
        m.distanceMarker_pixels_per_m = 175 / (m.radar_range / 6);

        m.RADAR_BOTTOM_LIMIT = radar_logic.RADAR_BOTTOM_LIMIT;
        m.RADAR_TOP_LIMIT = radar_logic.RADAR_TOP_LIMIT;
        m.RADAR_LEFT_LIMIT = radar_logic.RADAR_LEFT_LIMIT;
        m.RADAR_RIGHT_LIMIT = radar_logic.RADAR_RIGHT_LIMIT;
        m.locked_target = nil;

        m.radar_canvas.setColorBackground(m.bgc);
        
        m.static_group = m.radar_canvas.createGroup();
        m.lockbar_group = m.radar_canvas.createGroup();
        m.locked_group = m.radar_canvas.createGroup();
        m.contact_group = m.radar_canvas.createGroup();
        
        ##### radar screen text objects ########################################
        
        
        m.m30 = m.static_group.createChild("text", "30 distance marker")
            .setTranslation(506,90)
            .setAlignment("center-center")
            .setFont(m.font)
            .setFontSize(m.fS)
            .setColor(m.aec)
            .setText(int(m.radarRange10k));
            
        m.m20_left = m.static_group.createChild("text", "20 distance marker left")
            .setTranslation(96,377)
            .setAlignment("center-center")
            .setFont(m.font)
            .setFontSize(m.fS)
            .setColor(m.aec)
            .setText(int((m.radarRange10k/3)*2));
            
        m.m20_right = m.static_group.createChild("text", "20 distance marker right")
            .setTranslation(918,377)
            .setAlignment("center-center")
            .setFont(m.font)
            .setFontSize(m.fS)
            .setColor(m.aec)
            .setText(int((m.radarRange10k/3)*2));
            
        m.m10_left = m.static_group.createChild("text", "10 distance marker left")
            .setTranslation(96,663)
            .setAlignment("center-center")
            .setFont(m.font)
            .setFontSize(m.fS)
            .setColor(m.aec)
            .setText(int(m.radarRange10k/3));
            
        m.m10_right = m.static_group.createChild("text", "10 distance marker right")
            .setTranslation(918,663)
            .setAlignment("center-center")
            .setFont(m.font)
            .setFontSize(m.fS)
            .setColor(m.aec)
            .setText(int(m.radarRange10k/3));
            
        m.m0 = m.static_group.createChild("text", "0 distance marker")
            .setTranslation(506,950)
            .setAlignment("center-center")
            .setFont(m.font)
            .setFontSize(m.fS)
            .setColor(m.aec)
            .setText(0);
            
        m.r10_left = m.static_group.createChild("text", "10 horiz left")
            .setTranslation(141,580)
            .setAlignment("center-center")
            .setFont(m.font)
            .setFontSize(m.fS)
            .setColor(m.aec)
            .setText(int(m.radarRange10k/3));
            
        m.r5_left = m.static_group.createChild("text", "5 horiz left")
            .setTranslation(316,580)
            .setAlignment("center-center")
            .setFont(m.font)
            .setFontSize(m.fS)
            .setColor(m.aec)
            .setText(int(m.radarRange10k/3/2));
            
        m.r10_right = m.static_group.createChild("text", "10 horiz right")
            .setTranslation(871,580)
            .setAlignment("center-center")
            .setFont(m.font)
            .setFontSize(m.fS)
            .setColor(m.aec)
            .setText(int(m.radarRange10k/3));
            
        m.r5_right = m.static_group.createChild("text", "5 horiz right")
            .setTranslation(696,580)
            .setAlignment("center-center")
            .setFont(m.font)
            .setFontSize(m.fS)
            .setColor(m.aec)
            .setText(int(m.radarRange10k/3/2));
        
        ##### radar screen path objects ########################################
        
        #paths - top lines
        m.vertlinetop1 = m.static_group.createChild("path", "top1-vert")
            .move(0,(m.lL/2)-m.lL)
            .line(0,m.lL/2)
            .setColor(m.aec)
            .setStrokeLineWidth(m.lW)
            .setStrokeLineCap("round")
            .setTranslation(180,140);

        m.vertlinetop4 = m.static_group.createChild("path", "top4-vert")
            .move(0,(m.lL/2)-m.lL)
            .line(0,m.lL/2)
            .setColor(m.aec)
            .setStrokeLineWidth(m.lW)
            .setStrokeLineCap("round")
            .setTranslation(398,140);
            
        m.vertlinetop4 = m.static_group.createChild("path", "top4-vert")
            .move(0,(m.lL/2)-m.lL)
            .line(0,m.lL/2)
            .setColor(m.aec)
            .setStrokeLineWidth(m.lW)
            .setStrokeLineCap("round")
            .setTranslation(616,140);
            
        m.vertlinetop4 = m.static_group.createChild("path", "top4-vert")
            .move(0,(m.lL/2)-m.lL)
            .line(0,m.lL/2)
            .setColor(m.aec)
            .setStrokeLineWidth(m.lW)
            .setStrokeLineCap("round")
            .setTranslation(834,140);
            
        #paths - middle vertical lines    
        m.vertlinemid1 = m.static_group.createChild("path", "mid1-vert")
            .move(0,(m.lL/2)-m.lL) # 80 / 2 - 80 = 40 - 80 = -40
            .line(0,m.lL/2) # draw a line from set point to 40 pixels up
            .setColor(m.aec) #520 should be at center, so 540
            .setStrokeLineWidth(m.lW) #15 pix up
            .setStrokeLineCap("round")
            .setTranslation(141,540);
            
        m.vertlinemid2 = m.static_group.createChild("path", "mid2-vert")
            .move(0,(m.lL/2)-m.lL)
            .line(0,m.lL/2)
            .setColor(m.aec)
            .setStrokeLineWidth(m.lW)
            .setStrokeLineCap("round")
            .setTranslation(316,540);
            
        m.vertlinemid3 = m.static_group.createChild("path", "mid3-vert")
            .move(0,(m.lL/2)-m.lL)
            .line(0,m.lL/2)
            .setColor(m.aec)
            .setStrokeLineWidth(m.lW)
            .setStrokeLineCap("round")
            .setTranslation(871,540);

        m.vertlinemid4 = m.static_group.createChild("path", "mid4-vert")
            .move(0,(m.lL/2)-m.lL)
            .line(0,m.lL/2)
            .setColor(m.aec)
            .setStrokeLineWidth(m.lW)
            .setStrokeLineCap("round")
            .setTranslation(696,540);

        #paths - horizontal lines
        m.horizline30L = m.static_group.createChild("path", "line30L")
            .move((m.lL/2)-m.lL,0)
            .line(m.lL/2,0)
            .setColor(m.aec)
            .setStrokeLineWidth(m.lW)
            .setStrokeLineCap("round")
            .setTranslation(456,90);
            
        m.horizline30R = m.static_group.createChild("path", "line30R")
            .move((m.lL/2)-m.lL,0)
            .line(m.lL/2,0)
            .setColor(m.aec)
            .setStrokeLineWidth(m.lW)
            .setStrokeLineCap("round")
            .setTranslation(596,90);

        m.horizline20L = m.static_group.createChild("path", "line20L")
            .move((m.lL/2)-m.lL,0)
            .line(m.lL/2,0)
            .setColor(m.aec)
            .setStrokeLineWidth(m.lW)
            .setStrokeLineCap("round")
            .setTranslation(186,377);
            
        m.horizline20R = m.static_group.createChild("path", "line20R")
            .move((m.lL/2)-m.lL,0)
            .line(m.lL/2,0)
            .setColor(m.aec)
            .setStrokeLineWidth(m.lW)
            .setStrokeLineCap("round")
            .setTranslation(868,377);
            
        m.horizline10L = m.static_group.createChild("path", "line10L")
            .move((m.lL/2)-m.lL,0)
            .line(m.lL/2,0)
            .setColor(m.aec)
            .setStrokeLineWidth(m.lW)
            .setStrokeLineCap("round")
            .setTranslation(186,663);
            
        m.horizline10R = m.static_group.createChild("path", "line10R")
            .move((m.lL/2)-m.lL,0)
            .line(m.lL/2,0)
            .setColor(m.aec)
            .setStrokeLineWidth(m.lW)
            .setStrokeLineCap("round")
            .setTranslation(868,663);

        #middle box
        m.lockbox = m.static_group.createChild("path", "lockbox")
            .move(-20,0) #486,950
            .line(-30,0) #456,950
            .line(0,-573) #456,377
            .line(30,0) #486,377
            .move(40,0) #526,377
            .line(30,0) #556,377
            .line(0,573) #556,950
            .line(-30,0)
            .setColor(m.aec)
            .setStrokeLineWidth(m.lW)
            .setStrokeLineCap("round")
            .setTranslation(506,950);
            
        #triangle dealios
        m.triangle1 = m.static_group.createChild("path", "triangle1")
            .line(-20,0)
            .line(20,-34.6)
            .line(20,34.6)
            .line(-20,0)
            .setColor(m.aec)
            .setStrokeLineWidth(m.lW)
            .setStrokeLineCap("round")
            .setTranslation(180,900);

        m.triangle2 = m.static_group.createChild("path", "triangle2")
            .line(-20,0)
            .line(20,-34.6)
            .line(20,34.6)
            .line(-20,0)
            .setColor(m.aec)
            .setStrokeLineWidth(m.lW)
            .setStrokeLineCap("round")
            .setTranslation(398,970);
            
        m.triangle3 = m.static_group.createChild("path", "triangle3")
            .line(-20,0)
            .line(20,-34.6)
            .line(20,34.6)
            .line(-20,0)
            .setColor(m.aec)
            .setStrokeLineWidth(m.lW)
            .setStrokeLineCap("round")
            .setTranslation(616,970);

        m.triangle4 = m.static_group.createChild("path", "triangle4")
            .line(-20,0)
            .line(20,-34.6)
            .line(20,34.6)
            .line(-20,0)
            .setColor(m.aec)
            .setStrokeLineWidth(m.lW)
            .setStrokeLineCap("round")
            .setTranslation(834,900);
            
        #target pointer and circle
        m.target_pointer = m.static_group.createChild("path", "target_pointer")
            .move(-45,0)
            .line(90,0)
            .move(-45,-30)
            .line(0,60)
            .setStrokeLineWidth(m.lW + 1)
            .setColor(m.aec)
            .setTranslation(506,520);
        
        m.target_circle = m.static_group.createChild("path", "target_circle")
            .move(-50,0)
            .arcSmallCW(50,50,0,100,0)
            .arcSmallCW(50,50,0,-100,0)
            .setStrokeLineWidth(m.lW)
            .setColor(m.aec)
            .setTranslation(506,520);
            
        #distance bars
        m.leftDistanceBar = m.locked_group.createChild("path","leftDistanceBar")
            # y is 520, x1 is 100, x2 is 390
            .line(290,0)
            .setColor(m.aec)
            .setStrokeLineWidth(m.lW + 1)
            .setStrokeLineCap("round")
            .setTranslation(100,520);
            
        m.rightDistanceBar = m.locked_group.createChild("path","rightDistanceBar")
            #y is 520, x1 is 622, x2 is 912
            .line(290,0)
            .setColor(m.aec)
            .setStrokeLineWidth(m.lW + 1)
            .setStrokeLineCap("round")
            .setTranslation(622,520);
            
        #distance markers
        m.leftDistanceMarker = m.locked_group.createChild("path","leftDistanceMarker")
            # in the code below, Y should always be at 520
            .line(-15,0)
            .line(15,-40)
            .line(15,40)
            .line(-15,0)
            .setColor(m.aec)
            .setStrokeLineWidth(m.lW+3)
            .setStrokeLineCap("round");
            
        m.rightDistanceMarker = m.locked_group.createChild("path","rightDistanceMarker")
            # in the code below, Y should always be at 520
            .line(-15,0)
            .line(15,-40)
            .line(15,40)
            .line(-15,0)
            .setColor(m.aec)
            .setStrokeLineWidth(m.lW+3)
            .setStrokeLineCap("round");
        
        ##### lock bars ########################################################
        
        m.lowerBar = m.lockbar_group.createChild("path","lowerBar")
            .move(-50,0)
            .line(100,0)
            .setColor(m.aec)
            .setStrokeLineWidth(m.lW + 2)
            .setStrokeLineCap("round")
            .setTranslation(506,950);
            
        m.upperBar = m.lockbar_group.createChild("path","upperBar")
            .move(-50,0)
            .line(100,0)
            .setColor(m.aec)
            .setStrokeLineWidth(m.lW + 2)
            .setStrokeLineCap("round")
            .setTranslation(506,750);
            
        ##### contact markers ##################################################
        
        # do this as dynamically as we can
        # to create a new contact, call create_contact_marker
        # it will add a contact to me.contact_array
        # with the members vert, horiz, and friend
        # vert will have to be moved up and down
        # these are hidden by default
        
        return m;
    },
    
    off_mode_init: func() {
        me.static_group.hide();
        me.lockbar_group.hide();
        me.locked_group.hide();
        me.contact_group.hide();
    },
    
    off_mode_update: func() {
        return;
    },

    standby_mode_init: func() {
        me.static_group.show();
        me.lockbar_group.show();
        me.locked_group.hide();
        me.contact_group.hide();
        me.lscale = clamp(getprop(me.lock_bars_scale), 50, 250);
        me.lpos = clamp(getprop(me.lock_bars_pos), 0, 473);
        me.draw_lockbars();
    },

    standby_mode_update: func() {
        me.lscale = clamp(getprop(me.lock_bars_scale), 50, 250);
        me.lpos = clamp(getprop(me.lock_bars_pos), 0, 473);
        me.draw_lockbars();
    },

    broken_mode_init: func() {
        me.static_group.show();
        me.lockbar_group.show();
        me.locked_group.hide();
        me.contact_group.hide();
    },

    broken_mode_update: func() {
        me.draw_lockbars();
    },
    
    scan_mode_init: func() {
        me.static_group.show();
        me.lockbar_group.show();
        me.locked_group.hide();
        me.contact_group.show();
        me.lscale = clamp(getprop(me.lock_bars_scale), 50, 250);
        me.lpos = clamp(getprop(me.lock_bars_pos), 0, 473);
        me.draw_lockbars();
    },
    
    scan_mode_update: func() {

        # make sure our lock bars dont go out of bounds

        me.lscale = clamp(getprop(me.lock_bars_scale), 50, 250);
        me.lpos = clamp(getprop(me.lock_bars_pos), 0, 473);

        me.draw_lockbars();

        me.cx_count = 0;

        foreach (var mp; radar_logic.tracks) {
            #print("found contact");
            me.p = mp.get_polar();
            me.distance = me.p[0];
            me.xa_rad = me.p[3];
            me.ya_ang = me.p[2] * R2D;
            #make blip
            if (me.distance != nil and me.distance < me.radar_range ){ #and alt-100 > getprop("/environment/ground-elevation-m")){
                #aircraft is within the radar ray cone
                # plot the blip on the radar screen
                me.pixelDistance = -me.distance*((950)/me.radar_range); #distance in pixels
                #translate from polar coords to cartesian coords
                me.pixelX = ((me.xa_rad * R2D / me.RADAR_LEFT_LIMIT) * -506) + 506; #506 is half width of radar screen
                me.pixelY = me.pixelDistance + 950;
                me.pixelX = clamp(me.pixelX, 180, 836);
                me.pixelY = clamp(me.pixelY, 100,950);
                
                # make sure we have enough contact markers
                me.b = me.cx_count;
                me.cx_count = me.cx_count + 1;
                if (size(me.contact_array) < me.cx_count) {
                    me.create_contact_marker();
                }

                me.draw_contact(me.b, me.pixelX, me.pixelY, me.ya_ang, mp);
            }
        }
        if (me.cx_count == 0 or rwr.iff_power_node.getValue() < 110 or getprop(me.iff_button) == 0) {
            rwr.decod_node.setValue(0);
        }
        for (me.i = me.cx_count; me.i < size(me.contact_array); me.i = me.i + 1) {
            me.contact_array[me.i].horiz.hide();
            me.contact_array[me.i].vert.hide();
            me.contact_array[me.i].friend.hide();
        }
    
    },
    
    locked_mode_init: func() {
        me.static_group.show();
        me.lockbar_group.hide();
        me.locked_group.show();
        me.contact_group.show();
        for (me.i = 1; me.i < size(me.contact_array); me.i = me.i + 1) {
            me.contact_array[me.i].horiz.hide();
            me.contact_array[me.i].vert.hide();
            me.contact_array[me.i].friend.hide();
        }
    },
    
    locked_mode_update: func() {
        me.locked_target = radar_logic.selection;
        if ( me.locked_target != nil ) {
            me.dist_rad = me.locked_target.get_polar();
            if ( me.dist_rad[0] > me.radar_range or math.abs(me.dist_rad[1] * R2D) > 15 or math.abs(me.dist_rad[2] * R2D) > 15 or me.locked_target.isValid() == 0 ) { #if the target is out of lockon range, then exit locked-mode
                #print("exit1");
                #### invalid target
                #### fix me
                arm_locking.unlockTarget();
            } else {
                me.ya_ang = me.dist_rad[2] * R2D;
                #switch from an overhead view to a forward facing view.
                #the blip will move according to angle, instead of distance
                me.pixelX = ((me.dist_rad[1] * R2D / 15) * 506) + 506; #506 is half width of radar screen, and 180 is starting from the left, go over this much
                me.pixelY = ((me.ya_ang / 15) * -425) + 520; #520 is half width of radar screen
                me.pixelX = clamp(me.pixelX, 180, 836);
                me.pixelY = clamp(me.pixelY, 100,950);

                if (size(me.contact_array) < 1) {
                    me.create_contact_marker();
                }

                me.draw_contact(0, me.pixelX, me.pixelY, me.ya_ang, me.locked_target);
                
                #491 and 521 are where the "0" distance marks would be
                #100, 440, 602, and 912 are arbitrarily selected for the min/max of the distance triangle.
                me.leftDistanceMarker.setTranslation(math.clamp(me.dist_rad[0] * -me.distanceMarker_pixels_per_m + 491,100,440),520);
                me.rightDistanceMarker.setTranslation(math.clamp(me.dist_rad[0] * me.distanceMarker_pixels_per_m + 521,602,912),520);
            }
        } else {
            #print("exit2");
            arm_locking.unlockTarget();
        }
    
    },
    
    locked_mode_end: func() {
        if (radar_logic.selection != nil) {
            arm_locking.unlockTarget();
        }
    },

    beamed_mode_init: func() {
        me.lpos = 330;
        me.lscale = 200;
        me.draw_lockbars();
        me.static_group.show();
        me.lockbar_group.show();
        me.locked_group.hide();
        me.contact_group.show();
        for (me.i = 1; me.i < size(me.contact_array); me.i = me.i + 1) {
            me.contact_array[me.i].horiz.hide();
            me.contact_array[me.i].vert.hide();
            me.contact_array[me.i].friend.hide();
        }
        arm_locking.beam_target_lock();
    },
    
    beamed_mode_update: func() {
        if (radar_logic.selection != nil) {
            me.p = radar_logic.selection.get_polar();
            me.distance = me.p[0];
            me.xa_rad = me.p[3];
            me.ya_ang = me.p[2] * R2D;
            if (me.distance != nil and me.distance < me.radar_range ){
                me.pixelDistance = -me.distance*((950)/me.radar_range); #distance in pixels
                #translate from polar coords to cartesian coords
                me.pixelX = ((me.xa_rad * R2D / me.RADAR_LEFT_LIMIT) * -506) + 506; #506 is half width of radar screen
                me.pixelY = me.pixelDistance + 950;
                me.pixelX = clamp(me.pixelX, 180, 836);
                me.pixelY = clamp(me.pixelY, 100,950);

                if (size(me.contact_array) < 1) {
                    me.create_contact_marker();
                }

                me.draw_contact(0, me.pixelX, me.pixelY, 0, radar_logic.selection);
                
            }
        }
    },

    beamed_mode_end: func() {
        arm_locking.unlockTarget();
    },

    create_contact_marker: func() {
        append(me.contact_array,{
                                vert: me.contact_group.createChild("path","vblp")
                                                .move(0,me.contact_line_length/2)
                                                .line(0,-me.contact_line_length)
                                                .setStrokeLineWidth(me.lW)
                                                .setColor(me.aec)
                                                .hide(),
                                horiz: me.contact_group.createChild("path","hbp1")
                                                .move(-me.contact_line_length/2,0)
                                                .line(me.contact_line_length,0)
                                                .setStrokeLineWidth(me.lW)
                                                .setColor(me.aec)
                                                .hide(),
                                friend: me.contact_group.createChild("path","hbp2")
                                                .move(-me.contact_line_length/2,-me.contact_line_length/6)
                                                .line(me.contact_line_length,0)
                                                .setStrokeLineWidth(me.lW)
                                                .setColor(me.aec)
                                                .hide(),
        });
        
    },
    
    draw_contact: func(idx, pixX, pixY, ang, mpcx) {
        # translate the correct markers into place
        me.contact_array[idx].horiz.show().setTranslation(pixX, pixY);
        if (me.cur_state != radar_beamed and getprop(me.iff_button) == 1) {
            me.contact_array[idx].vert.hide();
            if (rwr.iff_power_node.getValue() > 110) {
                if (iff.interrogate(mpcx.getNode())) {
                    me.contact_array[idx].friend.show().setTranslation(pixX, pixY);
                } else {
                    me.contact_array[idx].friend.hide();
                }
                rwr.decod_node.setValue(1);
            }
        } else {
            me.contact_array[idx].friend.hide();
            if ( ang > 1.5 ) {
                # tgt is above
                me.contact_array[idx].vert.show().setTranslation(pixX, pixY - (me.contact_line_length / 2));
            } elsif ( ang < -1.5 ) {
                me.contact_array[idx].vert.show().setTranslation(pixX, pixY + (me.contact_line_length / 2));
            } else {
                me.contact_array[idx].vert.show().setTranslation(pixX, pixY);
            }
        }
    },

    draw_lockbars: func() {
        me.lowerBar.setTranslation(506, 950 - me.lpos);
        me.upperBar.setTranslation(506, 950 - ( me.lpos + me.lscale ));
    },

    update_range: func(newrange) {
        me.radar_range = newrange;
        me.radarRange10k = radar_range / 1000;
        me.distanceMarker_pixels_per_m = 175 / (me.radar_range / 6);
        
        me.m30.setText(int(me.radarRange10k));
        me.m20_left.setText(int((me.radarRange10k/3)*2));
        me.m20_right.setText(int((me.radarRange10k/3)*2));
        me.m10_left.setText(int(me.radarRange10k/3));
        me.m10_right.setText(int(me.radarRange10k/3));
        me.m0.setText(0);
        me.r10_left.setText(int(me.radarRange10k/3));
        me.r5_left.setText(int(me.radarRange10k/3/2));
        me.r10_right.setText(int(me.radarRange10k/3));
        me.r5_right.setText(int(me.radarRange10k/3/2));
    },
    
    change_state: func(state) {
        if (state.main_func == nil) { return; }
        if (state.temp == 0) {
            me.cur_state = state;
            if (me.cur_end_func != nil) {
                #print('calling the end func');
                call(me.cur_end_func, nil, me);
            }
            me.cur_main_func = state.main_func;
            me.cur_init_func = state.init_func;
            me.cur_end_func = state.end_func;
            if (me.cur_init_func != nil) {
                #print('calling the init func');
                call(me.cur_init_func, nil, me);
            }
        } else if (state.temp == 1) {
            if (state.init_func != nil) {
                call(state.init_func, nil, me);
            }
            if (state.main_func != nil) {
                call(state.main_func, nil, me);
            }
            if (state.end_func != nil) {
                call(state.end_func, nil, me);
            }
        }
    },

    main_loop: func() {
        # control switches are:

        # main power control
        # fdm/jsbsim/radar/mode
        # off = 0, standby = 1, on = 2
        # low alt
        # controls/radar/power-panel/low-alt
        # off = 0, h signal = 1, low alt = 2
        # per http://www.mig-21-online.de/mig-21/funkmessvisier/funkmessvisier-betriebsarten-2/#Fix
        # they are used to help filter out ground clutter on the radar screen
        # fixed beam
        # controls/radar/power-panel/fixed-beam # should be a green light
        # off = 0, on = 1

        # all the following are 0/off, 1/onn
        # radar control panel
        # various jamming filters
        # controls/radar/panel/continuous-jam
        # controls/radar/panel/intermittent-jam
        # controls/radar/panel/passive-jam
        # controls/radar/panel/weather-filter
        # target interrogator
        # controls/radar/panel/iff
        # low speed targets enabled, more fuzz
        # controls/radar/panel/lst-mode
        # return to scan mode
        # controls/radar/panel/reset
        # test the radar functionality
        # controls/radar/panel/selftest

        # damage is controlled by
        # fdm/jsbsim/radar/antenna-damage


        # check for electricity power
        #if (me.cur_state != hud_state_off and prop_io.hud_power < 0.8) {
        #    me.change_state(hud_state_off);
        #} elsif (me.cur_state == hud_state_off and prop_io.hud_power > 0.8) {
        #    me.change_state(hud_dev_mode);
        #}

        me.cmode = getprop("fdm/jsbsim/radar/mode");

        if (me.cur_state != radar_off and me.cmode == 0) {
            # radar off
            me.change_state(radar_off);
        } elsif (me.cur_state != radar_broken and me.cmode != 0 and getprop("fdm/jsbsim/radar/antenna-damage") >= 0.99) {
            # radar broken
            me.change_state(radar_broken);
        } elsif (me.cur_state != radar_standby and me.cmode == 1) {
            # radar standby
            me.change_state(radar_standby);
        } elsif (me.cmode == 2) {
            if (me.cur_state != radar_beamed and getprop("controls/radar/power-panel/fixed-beam")) {
                me.change_state(radar_beamed);
            } elsif (me.cur_state != radar_locked and !getprop("controls/radar/power-panel/fixed-beam") and radar_logic.selection != nil) {
                me.change_state(radar_locked);
            } elsif (me.cur_state != radar_scan and (radar_logic.selection == nil or (me.cur_state == radar_beamed and !getprop("controls/radar/power-panel/fixed-beam")))) {
                me.change_state(radar_scan);
            }
        }
        if (me.cur_main_func != nil) {
            call(me.cur_main_func, nil, me);
        }
        settimer(func { me.main_loop(); }, update_rate);
    },
};




radarscreen = RADAR_SCREEN.new({"node": "radarDisplay"}, "radarDisplay");

var state_arch = {
    main_func: nil,
    init_func: nil,
    end_func:  nil,
    temp:        0,
};

# main modes
# run the init once, loop the main, and then before the mode gets switched again it will run the end function
var radar_off       = {parents: [state_arch],  main_func: RADAR_SCREEN.off_mode_update,       init_func: RADAR_SCREEN.off_mode_init,     end_func: nil};
var radar_standby   = {parents: [state_arch],  main_func: RADAR_SCREEN.standby_mode_update,   init_func: RADAR_SCREEN.standby_mode_init, end_func: nil};
var radar_broken    = {parents: [state_arch],  main_func: RADAR_SCREEN.broken_mode_update,    init_func: RADAR_SCREEN.broken_mode_init,  end_func: nil};
var radar_scan      = {parents: [state_arch],  main_func: RADAR_SCREEN.scan_mode_update,      init_func: RADAR_SCREEN.scan_mode_init,    end_func: nil};
var radar_locked    = {parents: [state_arch],  main_func: RADAR_SCREEN.locked_mode_update,    init_func: RADAR_SCREEN.locked_mode_init,  end_func: RADAR_SCREEN.locked_mode_end};
var radar_beamed    = {parents: [state_arch],  main_func: RADAR_SCREEN.beamed_mode_update,    init_func: RADAR_SCREEN.beamed_mode_init,  end_func: RADAR_SCREEN.beamed_mode_end};

# temps
# if temp == 1, it will only fire the init, main, and end functions once.
#var hud_switch_gs_m = {parents: [state_arch], main_func: hud_ref.groundspeed_mach_switch, temp: 1};

radarscreen.change_state(radar_off);
radarscreen.main_loop();