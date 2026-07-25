
# function ref
var cur_main_func = nil;
var cur_init_func = nil;
var cur_end_func = nil;

var g155_DISPLAY = {

    canvas_settings: {
        "name": "155xlmain",   # The name is optional but allow for easier identification
        "size": [1024, 1024], # Size of the underlying texture (should be a power of 2, required) [Resolution]
        "view": [512, 512],  # Virtual resolution (Defines the coordinate system of the canvas [Dimensions]
        # which will be stretched the size of the texture, required)
        "mipmapping": 1       # Enable mipmapping (optional)
    },
    new: func(placement) {
        var m = {
        parents: [g155_DISPLAY],
        mfd: canvas.new(g155_DISPLAY.canvas_settings)
        };

        m.green = [0.9,1,0];
        m.black = [  0,0,0];

        m.font = "garmin155.ttf";
        m.lgfontsize = 38;

        m.charwidth = 25;
        m.startx = 7;

        m.txt1y = 40;
        m.txt2y = 81;
        m.txt3y = 122;
        m.txt4y = 163;

        m.mfd.addPlacement(placement);
        m.mfd.setColorBackground(m.green);
        m.generictext = m.mfd.createGroup();

        m.hheight = 40;
        m.highlight = m.mfd.createGroup();
        m.hbox = m.highlight.createChild("path","highlightbox")
            .setColor(m.black)
            .setColorFill(m.black)
            .hide();


        m.line1 = m.generictext.createChild("text", "lbl1")
            .setTranslation(m.startx, m.txt1y)
            .setAlignment("left-baseline")
            .setFont(m.font)
            .setFontSize(m.lgfontsize, 1.0)
            .setColor(m.black);
        m.line2 = m.generictext.createChild("text", "lbl1")
            .setTranslation(m.startx, m.txt2y)
            .setAlignment("left-baseline")
            .setFont(m.font)
            .setFontSize(m.lgfontsize, 1.0)
            .setColor(m.black);
        m.line3 = m.generictext.createChild("text", "lbl1")
            .setTranslation(m.startx, m.txt3y)
            .setAlignment("left-baseline")
            .setFont(m.font)
            .setFontSize(m.lgfontsize, 1.0)
            .setColor(m.black);
        m.line4 = m.generictext.createChild("text", "lbl1")
            .setTranslation(m.startx, m.txt4y)
            .setAlignment("left-baseline")
            .setFont(m.font)
            .setFontSize(m.lgfontsize, 1.0)
            .setColor(m.black);
        m.generictext.hide();
        #m.mfd_labels.set("z-index", 100);


        m.boop = m.mfd.createGroup();
        #m.moveme = m.boop.createChild("path","boopme")
        #    .moveTo(7,10)
        #    .line(5,41)
        #    .setColor(0,0,0,1);

        #m.selftest();

        m.b_enter = 0;
        return m;
    },

    selftest_init: func() {
        me.starttime = systime();
        me.line1.setText("");
        me.line2.setText(" GPS 115XL  v 2.04");
        me.line3.setText(" 1998 CHARMIN Corp");
        me.line4.setText("Performing self test");
        me.generictext.show();
    },

    selftest: func() {
        if (systime() - me.starttime > 3) {
            me.database_page_init();
            cur_main_func = mfd_ref.database_page;
        }
        #me.line1.setText(int(systime() - me.starttime));
    },

    #update_labels: func() {
    #    me.lbl1.setText(button_array[0].label);
    #},

    database_page_init: func() {
        me.line1.setText("");
        me.line2.setText(" WORLDWIDE IFR SUA  ");
        me.line3.setText("eff 01-jan-90 (9703)");
        me.line4.setText("exp 31-dec-32");
        me.okbox = me.mfd.createGroup().createChild("text", "ok?")
                    .setTranslation(me._txtboxx(17),me.txt4y)
                    .setAlignment("left-baseline")
                    .setFont(me.font)
                    .setFontSize(me.lgfontsize, 1.0)
                    .setColor(me.green)
                    .setText("ok?")
                    .show();
        me.boxmove(4,17,3);
        me.hbox.show();
    },

    database_page: func() {
        #do nothing for now
        if (me.b_enter) {
            me.b_enter = 0;
            me.hbox.hide();
            me.okbox.hide();
            me.satellite_status_page_init();
            cur_main_func = mfd_ref.satellite_status_page;
        }
    },

    satellite_status_page_init: func() {
        me.line1.setText("  No gps position");
        me.line2.setText("Acquiring   epe____#");
        me.line3.setText("sat 1 2 3 4 5 6 7 8");
        me.line4.setText("sgl _ _ _ _ _ _ _ _");
        me.satsgl = [0,0,0,0,0,0,0,0];
        me.satacquire_last = systime();
        me.satsacquired = 0;
    },

    satellite_status_page: func() {
        #do nothing for now
        me.reformat = "sgl ";
        for (me.i = 0; me.i < 8; me.i = me.i + 1) {
            # should take 60 to 120 seconds
            me.timemod = (systime() - me.satacquire_last) / 100;
            if (me.satsacquired < 5 or me.satsgl[me.i] > 0) {
                if (rand() > 0.9999 - me.timemod and me.satsgl[me.i] < 9) {
                    if (me.satsgl[me.i] == 0) {
                        me.satsacquired = me.satsacquired + 1;
                    }
                    #print(0.9999 - me.timemod);
                    me.satacquire_last = systime();
                    me.satsgl[me.i] = me.satsgl[me.i] + 1;
                }
            }
            if (me.satsgl[me.i] == 0) {
                me.reformat = me.reformat ~ "_ ";
            } else {
                me.reformat = me.reformat ~ me.satsgl[me.i] ~ " ";
            }
        }
        me.line4.setText(me.reformat);
    },

    off_page_init: func() {
        me.generictext.hide();
        me.hbox.hide();
        me.okbox.hide();
    },

    off_page: func() {
        return;
    },

    boxmove: func(row, char, width) {
        #what row (1/2/3/4), what character space it starts on (0 - 19), how many characters
        me.rr = 0;
        if (row == 1) {
            me.rr = 0;
        } elsif (row == 2) {
            me.rr = me.txt1y;
        } elsif (row == 3) {
            me.rr = me.txt2y;
        } elsif (row == 4) {
            me.rr = me.txt3y;
        }
        me.rr = me.rr + 4;
        me.hbox.reset().rect(me._txtboxx(char),me.rr,me.charwidth*width,me.hheight);

    },

    _txtboxx: func(v) {
        #get the starting x value of a text box based on character width
        return (v * me.charwidth) + me.startx;
    },


    # buttons

    button_enter: func() {
        me.b_enter = 1;
    },
};

var button_press = func(v) {
    if (button_array[v].main_func == nil) { return; }
    if (button_array[v].temp == 0) {
        if (cur_end_func != nil) {
            #print('calling the end func');
            call(cur_end_func, nil, mfd_ref);
        }
        #if (button_array[v].init_func != nil) {
        #    call(button_array[v].init_func, nil, mfd_ref );
        #}
        cur_main_func = button_array[v].main_func;
        cur_init_func = button_array[v].init_func;
        cur_end_func = button_array[v].end_func;
        if (cur_init_func != nil) {
            #print('calling the init func');
            call(cur_init_func, nil, mfd_ref);
        }
    } else if (button_array[v].temp == 1) {
        if (button_array[v].init_func != nil) {
            call(button_array[v].init_func, nil, mfd_ref);
        }
        if (button_array[v].main_func != nil) {
            call(button_array[v].main_func, nil, mfd_ref);
        }
        if (button_array[v].end_func != nil) {
            call(button_array[v].end_func, nil, mfd_ref);
        }
    }
}

var reset_button_array = func() {
    for (i = 0; i < 20; i = i + 1) {
        button_array[i] = button_null;
    }
}

var test_button_array = func() {
    for (i = 0; i < 20; i = i + 1) {
        button_array[i] = button_xxxx;
    }
}

var main_loop = func() {
    if (cur_main_func != nil) {
        call(cur_main_func, nil, mfd_ref );
    }
    settimer(main_loop,0.1);
}

mfd_ref = g155_DISPLAY.new({"node": "155canvasdisplay"});

# button definitions# button stuff
var button_array = [];

var button_arch = {
    label: "",
    main_func: nil,
    init_func: nil,
    end_func:  nil,
    temp:        0,
};

# button definitions
var button_null   = {parents:[button_arch]};
var button_enter   = {parents:[button_arch], label: "ENTER", main_func: mfd_ref.button_enter};
#var button_test   = {parents:[button_arch], label: "TEST", main_func: mfd_ref.screen_testfunc};
#var button_xxxx   = {parents:[button_arch], label: "XXXX"};
#var button_status = {parents:[button_arch], label: "STAT", main_func: mfd_ref.screen_status, init_func: mfd_ref.screen_status_init, end_func: mfd_ref.screen_status_rem};
#var button_sar    = {parents:[button_arch], label: "TSAR", main_func: mfd_ref.screen_sar,    init_func: mfd_ref.screen_sar_init,    end_func: mfd_ref.screen_sar_rem   };
#var button_fuel   = {parents:[button_arch], label: "FUEL", main_func: mfd_ref.screen_fuel,   init_func: mfd_ref.screen_fuel_init,   end_func: mfd_ref.screen_fuel_rem  };
#var button_vsi    = {parents:[button_arch], label: "VSI ", main_func: mfd_ref.screen_vsi,    init_func: mfd_ref.screen_vsi_init,    end_func: mfd_ref.screen_vsi_rem   };
#var button_nav    = {parents:[button_arch], label: "NAV",  main_func: mfd_ref.screen_nav,    init_func: mfd_ref.screen_nav_init,    end_func: mfd_ref.screen_nav_rem   };
#var button_eng    = {parents:[button_arch], label: "ENG",  main_func: mfd_ref.screen_eng,    init_func: mfd_ref.screen_eng_init,    end_func: mfd_ref.screen_eng_rem   };
#    var button_sar_dist_dec     = {parents:[button_arch], label:"DISV", main_func: mfd_ref.screen_sar_dec_dist,        temp: 1};
#    var button_sar_dist_inc     = {parents:[button_arch], label:"DISΛ", main_func: mfd_ref.screen_sar_inc_dist,        temp: 1};
#    var button_sar_slew_left    = {parents:[button_arch], label:"SLW<", main_func: mfd_ref.screen_sar_slew_left,       temp: 1};
#    var button_sar_slew_right   = {parents:[button_arch], label:"SLW>", main_func: mfd_ref.screen_sar_slew_right,      temp: 1};
#    var button_sar_slew_up      = {parents:[button_arch], label:"SLWΛ", main_func: mfd_ref.screen_sar_slew_up,         temp: 1};
#    var button_sar_slew_down    = {parents:[button_arch], label:"SLWV", main_func: mfd_ref.screen_sar_slew_down,       temp: 1};
#    var button_sar_slew_ctr     = {parents:[button_arch], label:"SLWC", main_func: mfd_ref.screen_sar_slew_center,     temp: 1};
#    var button_sar_zoom_in      = {parents:[button_arch], label:"ZM +", main_func: mfd_ref.screen_sar_zoom_in,         temp: 1};
#    var button_sar_zoom_out     = {parents:[button_arch], label:"ZM -", main_func: mfd_ref.screen_sar_zoom_out,        temp: 1};
#    var button_sar_gain_inc     = {parents:[button_arch], label:"GN +", main_func: mfd_ref.screen_sar_gain_inc,        temp: 1};
#    var button_sar_gain_dec     = {parents:[button_arch], label:"GN -", main_func: mfd_ref.screen_sar_gain_dec,        temp: 1};
#    var button_sar_pause        = {parents:[button_arch], label:"PAUS", main_func: mfd_ref.screen_sar_pause_draw,      temp: 1};
#    var button_ap_heading_up    = {parents:[button_arch], label:"HG+ ", main_func: mfd_ref.screen_vsi_ap_up_little,    temp: 1};
#    var button_ap_heading_upp   = {parents:[button_arch], label:"HG++", main_func: mfd_ref.screen_vsi_ap_up_lot,       temp: 1};
#    var button_ap_heading_dn    = {parents:[button_arch], label:"HG- ", main_func: mfd_ref.screen_vsi_ap_dn_little,    temp: 1};
#    var button_ap_heading_dnn   = {parents:[button_arch], label:"HG--", main_func: mfd_ref.screen_vsi_ap_dn_lot,       temp: 1};
#    var button_ap_heading_mth   = {parents:[button_arch], label:"HG C", main_func: mfd_ref.screen_vsi_ap_match,        temp: 1};
#    var button_qnh_toggle       = {parents:[button_arch], label:"QNTG", main_func: mfd_ref.screen_vsi_qnh_toggle,      temp: 1};
#    var button_qnh_up_little    = {parents:[button_arch], label:"QN+ ", main_func: mfd_ref.screen_vsi_qnh_up_little,   temp: 1};
#    var button_qnh_down_little  = {parents:[button_arch], label:"QN- ", main_func: mfd_ref.screen_vsi_qnh_down_little, temp: 1};
#    var button_qnh_up_lot       = {parents:[button_arch], label:"QN++", main_func: mfd_ref.screen_vsi_qnh_up_lot,      temp: 1};
#    var button_qnh_down_lot     = {parents:[button_arch], label:"QN--", main_func: mfd_ref.screen_vsi_qnh_down_lot,    temp: 1};
#    var button_eng_perfmix      = {parents:[button_arch], label:"PMIX", main_func: mfd_ref.screen_eng_perf_mix,        temp: 1};
#    var button_eng_idealmix     = {parents:[button_arch], label:"IMIX", main_func: mfd_ref.screen_eng_ideal_mix,       temp: 1};
#    var button_eng_ecomix       = {parents:[button_arch], label:"EMIX", main_func: mfd_ref.screen_eng_eco_mix,         temp: 1};
#    var button_eng_killmix      = {parents:[button_arch], label:"KILL", main_func: mfd_ref.screen_eng_kill,            temp: 1};
#    var button_eng_kill_confirm = {parents:[button_arch], label:"CONF", main_func: mfd_ref.screen_eng_kill_confirm,    temp: 1};
#    var button_eng_kill_cancel  = {parents:[button_arch], label:"CNCL", main_func: mfd_ref.screen_eng_kill_cancel,     temp: 1};

#for (i = 0; i < 20; i = i + 1) {
#    append(button_array, button_null);
#}

var init = setlistener("/sim/signals/fdm-initialized", func() {
    removelistener(init); # only call once

#    mfd_ref.screen_sar_init();
#    mfd_ref.screen_sar_rem();
#    mfd_ref.screen_status_init();
#    cur_init_func = mfd_ref.screen_status_init;
    mfd_ref.off_page_init();
    cur_main_func = mfd_ref.off_page;
#    cur_end_func = mfd_ref.screen_status_rem;
    main_loop();
});

