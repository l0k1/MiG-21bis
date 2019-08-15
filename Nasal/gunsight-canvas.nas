

var input = {
    gunsight_power : "/fdm/jsbsim/electric/output/gunsight",
    
    fixednetswitch : "/controls/armament/gunsight/fixed-net-power-switch",
    redpath : "/controls/armament/gunsight/red",
    bluepath : "/controls/armament/gunsight/blue",
    greenpath : "/controls/armament/gunsight/green",
    fixed_net_alphapath : "/controls/armament/gunsight/fixed-net-brightness-knob",
    fontsizepath : "/controls/armament/gunsight/font-size",
    linewidthpath : "/controls/armament/gunsight/thickness",
    viewX : "/sim/current-view/x-offset-m",
    viewY : "/sim/current-view/y-offset-m",
    viewZ : "/sim/current-view/z-offset-m",
    ghosting_x : "/controls/armament/gunsight/ghosting-x",
    ghosting_y : "/controls/armament/gunsight/ghosting-y",
    scaling : "/controls/armament/gunsight/scaling",
    sight_align_elevation : "/controls/armament/gunsight/elevation",
    sight_align_windage : "/controls/armament/gunsight/windage",
    
    #pipper modes and info
    pipperpowerswitch : "/controls/armament/gunsight/pipper-power-switch",
    pipperscale : "/controls/armament/gunsight/pipper-scale",
    pipperaccuracy : "/controls/armament/gunsight/pipper-accuracy-switch",
    pippergunmissile : "/controls/armament/gunsight/gun-missile-switch",
    pippermode : "/controls/armament/gunsight/pipper-mode-select-switch",
    targetsizeknob : "/controls/armament/gunsight/target-size-knob",
    pipperangularcorrection : "/controls/armament/gunsight/pipper-angular-correction-knob",
    pipperbrightness : "/controls/armament/gunsight/pipper-brightness-knob",
    pipperautomanual : "/controls/armament/gunsight/auto-man-switch",
    
    air_gnd_switch : "/controls/armament/panel/air-gnd-switch",
    ir_sar_switch : "/controls/armament/panel/ir-sar-switch",
    gun_missile_switch : "/controls/armament/gunsight/gun-missile-switch",
};

foreach(var name; keys(input)) {
    input[name] = props.globals.getNode(input[name], 1);
}

var gun_sight = {

    canvas_settings: {
        "name": "gunsight",
        "size": [1024, 1024],
        "view": [1024, 1024],
        "mipmapping": 1
    },
    
    new: func(placement) {
        var m = {parents: [gun_sight]};
        m.gunsight = canvas.new(gun_sight.canvas_settings);
        m.gunsight.addPlacement(placement);
        m.gunsight.setColorBackground(0,0,0,0);
        
        m.dR = m.normColor(input.redpath.getValue());
        m.dG = m.normColor(input.greenpath.getValue());
        m.dB = m.normColor(input.bluepath.getValue());
        m.dAf = input.fixed_net_alphapath.getValue();
        m.dAp = input.pipperbrightness.getValue();
        m.fS = input.fontsizepath.getValue();
        m.lW = input.linewidthpath.getValue();

        m.gunsight.setColorBackground(m.dR,m.dG,m.dB,0);
        
        # calculate pixel per degree
        # x and z coords of the center of the hud
        m.gsight_x = -4.08292;
        m.gsight_z = 1.07701;
        m.base_view_x = -3.33;
        m.base_view_z = 1.2813;
        
        m.gsight_height_m = 0.17; # height of hud in meters
        m.gsight_height_px = 920; # actual height of gunsight in pixels
        m.px_per_m = m.gsight_height_px / m.gsight_height_m;
        m.view_offset_x = 0;
        m.view_offset_y = 0;
        
        m.mil = m.calcPixelPerDegree(m.base_view_x, m.base_view_z)[2];
        
        m.center_offset_px = 288;

        # for scaling later
        m.base_distance = input.viewX.getValue() - m.gsight_x;
        m.px_per_meter = 
        m.old_sca = 0;

        # logic
        m.asp_gunsight = gunsight_logic.asp_pfd.new();
        
        ###########
        # FIXED NET
        ###########
        
        # specs:
        # center is even with aircraft point of aim
        # top bar is 40 mils above center, 6 mils wide
        # second bar is 20 mils above center, 6 mils wide
        # center bar has 4 vertical bars, spaced at -40, -20, 20, and 40, 5 mils tall
        # there are 4 horizontal bars, with left edges at
        # 3 horizontal bars, at 10, 20, 30 mils below center, 6 mils long with a 2.5 gap to center - | -
        # alternating 12 mil bars (4) and 6 mil bars (3) thereafter

        #m.fixed_net = m.gunsight.createGroup()
        m.fixed_net = m.gunsight.createGroup();
        m.fixed_net_lines = m.fixed_net.createChild("path","fixed_net")
            .setColor(m.dR,m.dG,m.dB,m.dAf)
            .setStrokeLineWidth(m.lW)
            .setStrokeLineCap("round")
            .move( 0            ,-45 * m.mil  ) # top of verticle line
            .line( 0            , 48 * m.mil  ) # down just past center
            .move(-3    * m.mil ,-43 * m.mil  ) # to first horiz line on top
            .line( 6    * m.mil ,  0          )
            .move(-6    * m.mil , 20 * m.mil  ) # move to the second horiz line
            .line( 6    * m.mil ,  0          )
            .move(-23   * m.mil , 20 * m.mil  ) # far left center horiz loie
            .line( 6    * m.mil , 0           )
            .move( 3    * m.mil , 0           )
            .line( 6    * m.mil , 0           )
            .move( 10   * m.mil , 0           )
            .line( 6    * m.mil , 0           )
            .move( 3    * m.mil , 0           )
            .line( 6    * m.mil , 0           )
            .move(-60   * m.mil ,-3  * m.mil  ) # vertical lines near the center
            .line( 0            ,  6  * m.mil )
            .move( 20   * m.mil , -5  * m.mil )
            .line( 0            ,  4  * m.mil )
            .move( 40   * m.mil , -4  * m.mil )
            .line( 0            ,  4  * m.mil )
            .move( 20   * m.mil , -5  * m.mil )
            .line( 0            ,  6  * m.mil )
            .move(-40   * m.mil ,  4  * m.mil ) # do vertical lines w/ gaps below center, all the way down
            .line( 0            ,  8   * m.mil)
            .move( 0            ,  1   * m.mil)
            .line( 0            ,  8   * m.mil)
            .move( 0            ,  4   * m.mil)
            .line( 0            , 87   * m.mil)
            .move(-6    * m.mil ,-15   * m.mil) # do remainder of center horizontal lines
            .line( 12   * m.mil , 0           )
            .move(-9    * m.mil , -10  * m.mil)
            .line( 6    * m.mil , 0           )
            .move(-9    * m.mil ,-10   * m.mil)
            .line( 12   * m.mil , 0           )
            .move(-9    * m.mil , -10  * m.mil)
            .line( 6    * m.mil , 0           )
            .move(-9    * m.mil ,-10   * m.mil)
            .line( 12   * m.mil , 0           )
            .move(-9    * m.mil , -10  * m.mil)
            .line( 6    * m.mil , 0           )
            .move(-9    * m.mil ,-10   * m.mil)
            .line( 12   * m.mil , 0           )
            .move(-13.5 * m.mil , -10  * m.mil)
            .line( 5    * m.mil , 0           )
            .move( 5    * m.mil , 0           )
            .line( 5    * m.mil , 0           )
            .move(-15   * m.mil , -10  * m.mil)
            .line( 5    * m.mil , 0           )
            .move( 5    * m.mil , 0           )
            .line( 5    * m.mil , 0           )
            .move(-15   * m.mil , -10  * m.mil)
            .line( 5    * m.mil , 0           )
            .move( 5    * m.mil , 0           )
            .line( 5    * m.mil , 0           )
            .move(-27.5 * m.mil , 10   * m.mil) # 45 degree bars
            .line(-55   * m.mil , 55   * m.mil)
            .move(150   * m.mil , 0           )
            .line(-55   * m.mil ,-55   * m.mil)
            .move(-40   * m.mil , 25   * m.mil)
            .line(-6.66 * m.mil , 19* m.mil) # 22.5 degree bars w/ gaps
            .move(-6.66 * m.mil , 19* m.mil)
            .line(-6.66 * m.mil , 19* m.mil)
            .move(79.98 * m.mil , 0           )
            .line(-6.66 * m.mil ,-19* m.mil)
            .move(-6.66 * m.mil ,-19* m.mil)
            .line(-6.66 * m.mil ,-19* m.mil);

        m.fixed_net_inner_arch = m.fixed_net.createChild("path","fixednetarch1")
            .setColor(m.dR,m.dG,m.dB,m.dAf)
            .setStrokeLineWidth(m.lW)
            .setStrokeLineCap("round")
            # 207.34 mils long
            .setStrokeDashArray([19.5 * m.mil,
                                3 * m.mil,
                                12 * m.mil,
                                3 * m.mil,
                                12 * m.mil,
                                3 * m.mil,
                                12 * m.mil,
                                3 * m.mil,
                                12 * m.mil,
                                3 * m.mil,
                                12 * m.mil,
                                18 * m.mil,
                                12 * m.mil,
                                3 * m.mil,
                                12 * m.mil,
                                3 * m.mil,
                                12 * m.mil,
                                3 * m.mil,
                                12 * m.mil,
                                3 * m.mil,
                                12 * m.mil,
                                3 * m.mil,
                                19.5 * m.mil,
                                ])
            .move(-60 * m.mil * math.cos(9 * D2R),-10 * m.mil)
            .arcLargeCCW(60 * m.mil, 60 * m.mil,0,120 * m.mil * math.cos(9 * D2R),0);

        m.fixed_net_outer_arch = m.fixed_net.createChild("path","fixednetarch2")
            .setColor(m.dR,m.dG,m.dB,m.dAf)
            .setStrokeLineWidth(m.lW)
            .setStrokeLineCap("round")
            .setStrokeDashArray([16 * m.mil,
                                5 * m.mil,
                                15 * m.mil,
                                5 * m.mil,
                                15 * m.mil,
                                5 * m.mil,
                                15 * m.mil,
                                26 * m.mil,
                                15 * m.mil,
                                5 * m.mil,
                                15 * m.mil,
                                5 * m.mil,
                                15 * m.mil,
                                5 * m.mil,
                                16 * m.mil,
                                ])
            .move(-100 * m.mil * math.cos(39 * D2R), 100 * m.mil * math.sin(39 * D2R))
            .arcSmallCCW(100 * m.mil, 100 * m.mil, 0, 200 * m.mil * math.cos(39 * D2R),0);

        m.fixed_net.setTranslation(512,512 - m.center_offset_px);
        m.fixed_net.hide();
        
        ###########
        # PIPPER
        ###########
        
        # specs:
        # center is 2 mil dot
        # diamond is 5 mils end to end, 2 mils wide
        
        m.pipper = m.gunsight.createGroup();
        m.pipper_elems = [];
        m.pipper_center = m.pipper.createChild("path", "center")
            .moveTo(-m.mil,0)
            .arcSmallCW(m.mil, m.mil, 0, m.mil * 2, 0)
            .arcSmallCW(m.mil, m.mil, 0,-m.mil * 2, 0)
            .setColor(m.dR,m.dG,m.dB,m.dAp)
            .setColorFill(m.dR, m.dG, m.dB, m.dAp);
         
        for (var i = 0; i < 8; i = i + 1) {
            append(m.pipper_elems, m.pipper.createChild("path", "diamond" ~ i)
                .line(-m.mil * 3.3, m.mil)
                .line(-m.mil * 1.7,-m.mil)
                .line( m.mil * 1.7,-m.mil)
                .line( m.mil * 3.3, m.mil)
                .setStrokeLineCap("round")
                .setColor(m.dR,m.dG,m.dB,m.dAp)
                .setColorFill(m.dR, m.dG, m.dB, m.dAp)
                .setRotation(i * 45 * D2R, 0));
        }
        m.pipper.setTranslation(512,512);
        m.pipper.hide();
        
        ###########
        # listeners
        ###########
        
        setlistener(input.redpath.getPath(), func{ m.updateColor() } );
        setlistener(input.bluepath.getPath(), func{ m.updateColor() } );
        setlistener(input.greenpath.getPath(), func{ m.updateColor() } );
        setlistener(input.pipperbrightness.getPath(), func{ m.updateColor() } );
        setlistener(input.fixed_net_alphapath.getPath(), func{ m.updateColor() } );
        
        setlistener(input.linewidthpath.getPath(),func { m.updateWidth() });
        
		setlistener(input.viewX.getPath(),func { m.updateViewOffset(); });
		setlistener(input.viewY.getPath(),func { m.updateViewOffset(); });
        
        m.pipper_status = 0;
        m.fixed_net_status = 0;
        
        m.updateViewOffset();
        m.last_x = m.view_offset_x;
        m.last_y = m.view_offset_y;
        
        m.update();
        return m;
    },
    
    update: func() {
        if ( input.gunsight_power.getValue() > 33 ) {
            if ( input.pipperpowerswitch.getValue() == 1 and me.pipper_status == 0) {
                me.pipper_status = 1;
                me.pipper.show();
            } elsif ( input.pipperpowerswitch.getValue() == 0 and me.pipper_status == 1 ) {
                me.pipper_status = 0;
                me.pipper.hide();
            }
            
            if ( input.fixednetswitch.getValue() == 1 and me.fixed_net_status == 0 ) {
                me.fixed_net_status = 1;
                me.fixed_net.show();
            } elsif ( input.fixednetswitch.getValue() == 0 and me.fixed_net_status == 1 ) {
                me.fixed_net_status = 0;
                me.fixed_net.hide();
            }
            
            if ( (me.view_offset_x != me.last_x or me.view_offset_y != me.last_y) and me.fixed_net_status == 1 ) {
                me.fixed_net.setTranslation(512 + me.view_offset_x, (512 - me.center_offset_px) + me.view_offset_y);
                me.last_x = me.view_offset_x;
                me.last_y = me.view_offset_y;
            }
            
            if (me.pipper_status == 1) {
                me.calcPipperPos();
            }

        } else {
            if ( me.pipper_status == 1 ) {
                me.pipper_status = 0;
                me.pipper.hide();
            }
            if (me.fixed_net_status == 1 ) {
                me.fixed_net_status = 0;
                me.fixed_net.hide();
            }
        }
        settimer(func() { me.update(); },0.01);
    },

    calcPipperPos: func() {
        me.center_x = 512;
        me.center_y = 512 - me.center_offset_px;

        # movement due to gyro
        me.gyro_x = me.asp_gunsight.getAzimuth() * me.px_per_mil;
        me.gyro_y = me.asp_gunsight.getElevation() * me.px_per_mil;

        me.pipper_x = me.center_x + me.view_offset_x + me.gyro_x;
        me.pipper_y = me.center_y + me.view_offset_y + me.gyro_y;

        # translations
        me.pipper.setTranslation(me.pipper_x, me.pipper_y);

        me.pipper_scale = input.pipperscale.getValue() * me.px_per_mil;
        forindex( var i ; me.pipper_elems ) {
            me.angle = ((180 - (45 * i))+5) * D2R;
            me.pipper_elems[i].setTranslation(me.pipper_scale * math.cos(me.angle), -1 * me.pipper_scale * math.sin(me.angle));
        }

    },
    
    calcPixelPerDegree: func(view_x = 0, view_z = 0) {
        
        # angle from view to center of hud
        # x is forward/back, z is up/down
        # in the view props, y is up/down, z is forward/back
        me.z_delta = (view_z == 0 ? input.viewY.getValue() : view_z) - me.gsight_z;
        me.x_delta = (view_x == 0 ? input.viewZ.getValue() : view_x) - me.gsight_x;
        me.view_dist = math.sqrt(me.z_delta * me.z_delta + me.x_delta * me.x_delta);
        me.angle_to_hud = (90 * D2R) - math.asin(me.x_delta / me.view_dist);
        
        me.z_to_bottom_delta = me.z_delta + (me.gsight_height_m / 2);
        me.hypot_to_bottom = math.sqrt(me.z_to_bottom_delta * me.z_to_bottom_delta + me.x_delta * me.x_delta);
        me.angle_to_bottom = (90 * D2R) - math.asin(me.x_delta / me.hypot_to_bottom);
        
        me.px_per_degree = (me.gsight_height_px / 2) / (math.abs(me.angle_to_bottom - me.angle_to_hud) * R2D);
        me.px_per_moa = me.px_per_degree / 60;
        me.px_per_mil = me.px_per_degree * 0.05625;
        #print(me.px_per_degree);
        #print(me.px_per_moa);
        #print(me.px_per_mil);
        return [me.px_per_degree, me.px_per_moa, me.px_per_mil];
    },
    
    scalePaths: func() {
        me.sca = (input.viewX.getValue() - me.gsight_x) / me.base_distance;
        if (me.old_sca != me.sca) {
            me.fixed_net.setScale(me.sca, me.sca);
            me.pipper.setScale(me.sca, me.sca);
        }
        me.old_sca = me.sca;
    },
    
    updateViewOffset: func() {
        me.view_offset_x = me.px_per_m * input.viewX.getValue();
        me.view_offset_y = -me.px_per_m * (input.viewY.getValue() - me.base_view_z);
    },
    
    updateColor: func() {
        me.dR = me.normColor(input.redpath.getValue());
        me.dB = me.normColor(input.bluepath.getValue());
        me.dG = me.normColor(input.greenpath.getValue());
        me.dA = input.fixed_net_alphapath.getValue();
        me.dAp = input.pipperbrightness.getValue();
        me.fixed_net.setColor(me.dR,me.dG,me.dB,me.dA);
        me.pipper_center.setColorFill(me.dR,me.dG,me.dB,me.dAp);
        me.pipper_center.setColor(me.dR,me.dG,me.dB,me.dAp);
        foreach(var el ; me.pipper_elems) {
            el.setColorFill(me.dR,me.dG,me.dB,me.dAp);
            el.setColor(me.dR,me.dG,me.dB,me.dAp);
        }
        me.gunsight.setColorBackground(me.dR,me.dG,me.dB,0);
    },
    
    updateWidth: func() {
        me.lw = input.linewidthpath.getValue();
        me.fixed_net_lines.setStrokeLineWidth(me.lW);
        me.fixed_net_inner_arch.setStrokeLineWidth(me.lW);
        me.fixed_net_outer_arch.setStrokeLineWidth(me.lW);
        me.pipper_center.setStrokeLineWidth(me.lW);
        foreach(var el ; me.pipper_elems) {
            el.setStrokeLineWidth(me.lW);
        }
    },
    
    normColor: func(val) {
        return math.clamp(val / 255,0,1);
    },
};

var gs = 0;

var init = setlistener("/sim/signals/fdm-initialized", func() {
  removelistener(init); # only call once
  gs = gun_sight.new({"node": "sight"});
});