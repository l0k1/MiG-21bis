# (c) pinto 2026, gplv2+

# for switches, 0 = left click, 1 = middle click, 2 = release

var LEFT = 0;
var MIDDLE = 1;
var RELEASE = 2;

var OFF = 0;
var STBY = 1;
var NORM = 2;
var EMER = 3;

var mode = OFF;

# none-property variables

var mode1id = [0,0,1,2];
var mode2id = [2,3,0,0];
var mode3id = [1,2,0,0];
var mode4id = [6,7,7,6];
var mode5id = [6,7,7,6];

var digit_entry = [8,8,8,8]; # 8 is used as "no entry yet";

var led_brightness = 63; # min 0 max 63
var display_brightness = 63; #min 0 max 63

var enabled = [1,0,1,1,0,0]; # which modes are enabled. in order: 1,2,3/A,4,5,S

# transponder properties

# the only ones that get transmitted by default txpdr code (that we need to care about) are:
mode3id3_prop = props.globals.getNode("/instrumentation/transponder/inputs/digit");
mode3id2_prop = props.globals.getNode("/instrumentation/transponder/inputs/digit[1]");
mode3id1_prop = props.globals.getNode("/instrumentation/transponder/inputs/digit[2]");
mode3id0_prop = props.globals.getNode("/instrumentation/transponder/inputs/digit[3]");
mode3id_prop = props.globals.getNode("/instrumentation/transponder/transmitted-id");
ident_prop = props.globals.getNode("/instrumentation/transponder/ident");

mode1id_prop = props.globals.getNode("/instrumentation/transponder/mode-1-id",1);
mode2id_prop = props.globals.getNode("/instrumentation/transponder/mode-2-id",1);
mode4id_prop = props.globals.getNode("/instrumentation/transponder/mode-4-id",1);
mode5id_prop = props.globals.getNode("/instrumentation/transponder/mode-5-id",1);

mode4int_prop = props.globals.getNode("/instrumentation/transponder/mode-4-int");

# not transmitted but required by the transponder code
tx_knob_mode_prop = props.globals.getNode("/instrumentation/transponder/inputs/knob-mode");
# 0 = off
# 1 = stby
# 2 = test
# 3 = gnd
# 4 = on
# 5 = alt

# switch and knob properties

dim_prop = props.globals.getNode("/instrumentation/transponder/cbu412/dim",1);
diag_prop = props.globals.getNode("/instrumentation/transponder/cbu412/diag",1);
posid_prop = props.globals.getNode("/instrumentation/transponder/cbu412/posid",1);
zero_prop = props.globals.getNode("/instrumentation/transponder/cbu412/zerohold",1);
ab_prop = props.globals.getNode("/instrumentation/transponder/cbu412/mode4ab",1);
flt_prop = props.globals.getNode("/instrumentation/transponder/cbu412/mode5flt",1);
warn_prop = props.globals.getNode("/instrumentation/transponder/cbu412/warnswitch",1);
ops_prop = props.globals.getNode("/instrumentation/transponder/cbu412/opsmaint",1);
mil_prop = props.globals.getNode("/instrumentation/transponder/cbu412/milciv",1);
power_prop = props.globals.getNode("/instrumentation/transponder/cbu412/powerknob",1);

var led_meta = {
    prop: nil,
    state: 0,
    test: 0,
    get: func()  {return me.prop.getValue();},
    set: func(v) {me.prop.setValue(v);},
    on: func()   {me.state = 1; me.set(get_led_brightness());},
    off: func()  {me.state = 0; me.set(0);},
    test_on: func() {me.set(1);},
    test_off: func() {if(me.state){me.on();}else{me.off();}},
};

# led properties
var leds = [
  led_warn     = {parents:[led_meta], prop: props.globals.getNode("/instrumentation/transponder/cbu412/led/warn",1)},
  led_m4rep    = {parents:[led_meta], prop: props.globals.getNode("/instrumentation/transponder/cbu412/led/m4rep",1)},
  led_m5rep    = {parents:[led_meta], prop: props.globals.getNode("/instrumentation/transponder/cbu412/led/m5rep",1)},
  led_reply    = {parents:[led_meta], prop: props.globals.getNode("/instrumentation/transponder/cbu412/led/reply",1)},
  led_fail     = {parents:[led_meta], prop: props.globals.getNode("/instrumentation/transponder/cbu412/led/fail",1)},
  led_1        = {parents:[led_meta], prop: props.globals.getNode("/instrumentation/transponder/cbu412/led/l1",1)},
  led_2        = {parents:[led_meta], prop: props.globals.getNode("/instrumentation/transponder/cbu412/led/l2",1)},
  led_3a       = {parents:[led_meta], prop: props.globals.getNode("/instrumentation/transponder/cbu412/led/l3a",1)},
  led_c        = {parents:[led_meta], prop: props.globals.getNode("/instrumentation/transponder/cbu412/led/c",1)},
  led_s        = {parents:[led_meta], prop: props.globals.getNode("/instrumentation/transponder/cbu412/led/s",1)},
  led_sq       = {parents:[led_meta], prop: props.globals.getNode("/instrumentation/transponder/cbu412/led/sq/",1)},
  led_4        = {parents:[led_meta], prop: props.globals.getNode("/instrumentation/transponder/cbu412/led/l4",1)},
  led_5        = {parents:[led_meta], prop: props.globals.getNode("/instrumentation/transponder/cbu412/led/l5",1)},
  led_accleft  = {parents:[led_meta], prop: props.globals.getNode("/instrumentation/transponder/cbu412/led/accleft",1)},
  led_ta       = {parents:[led_meta], prop: props.globals.getNode("/instrumentation/transponder/cbu412/led/ta",1)},
  led_ra       = {parents:[led_meta], prop: props.globals.getNode("/instrumentation/transponder/cbu412/led/ra",1)},
  led_accright = {parents:[led_meta], prop: props.globals.getNode("/instrumentation/transponder/cbu412/led/accright",1)},
  led_left     = {parents:[led_meta], prop: props.globals.getNode("/instrumentation/transponder/cbu412/led/left",1)},
  led_fid      = {parents:[led_meta], prop: props.globals.getNode("/instrumentation/transponder/cbu412/led/fid",1)},
  led_msa      = {parents:[led_meta], prop: props.globals.getNode("/instrumentation/transponder/cbu412/led/msa",1)},
  led_right    = {parents:[led_meta], prop: props.globals.getNode("/instrumentation/transponder/cbu412/led/right",1)},
];

# switch and knob initial values

# trinary switches
dim_prop.setValue(0);
diag_prop.setValue(0);
posid_prop.setValue(0);
zero_prop.setValue(0);
warn_prop.setValue(0);
mil_prop.setValue(0);
# binary switches
ab_prop.setValue(1);
ops_prop.setValue(1);
flt_prop.setValue(0);
# quaternary switch (knob)
power_prop.setValue(0);

var LCDCBU412 = {

  canvas_settings: {
    "name": "LCD_CBU412",   # The name is optional but allow for easier identification
    "size": [1024, 1024], # Size of the underlying texture (should be a power of 2, required) [Resolution]
    "view": [256, 256],  # Virtual resolution (Defines the coordinate system of the canvas [Dimensions]
    # which will be stretched the size of the texture, required)
    "mipmapping": 1       # Enable mipmapping (optional)
  },
  new: func(placement)
  {
    var m = {
      parents: [LCDCBU412],
      LCD_CBU412: canvas.new(LCDCBU412.canvas_settings)
    };

    m.LCD_CBU412.addPlacement(placement);
    m.LCD_CBU412.setColorBackground(0,0,0,0);
    m.display = m.LCD_CBU412.createGroup();


    m.text = m.display.createChild("text", "topDisplay")
      .setTranslation(246, 46)      # The origin is in the top left corner
      .setAlignment("right-center") # All values from osgText are supported (see $FG_ROOT/Docs/README.osgtext)
      .setFont("DSEG/DSEG7/Modern/DSEG7Modern-BoldItalic.ttf") # Fonts are loaded either from $AIRCRAFT_DIR/Fonts or $FG_ROOT/Fonts
      .setFontSize(72, 1.0)        # Set fontsize and optionally character aspect ratio
      .setColor(1,0,0)             # Text color
      .setText("drct");
    m.display.show();
    return m;
  },
  update_msg: func(msg) {
    me.text.setText(msg);
  },
  hide: func() {
    me.display.hide();
  },
  show: func() {
    me.display.show();
  }
};

# menu states
var NORMAL = 0;
var MODESEL = 1;
var FLITID = 2;
var MODE1ENTRY = 3;
var MODE2ENTRY = 4;
var MODE3ENTRY = 5;
var MODE4ENTRY = 6;
var MODE5ENTRY = 7;
var NEXTCOD = 8;

var state = NORMAL;

var button_menu = func(s) {
  if (mode == OFF) return;
  if (s != RELEASE) {
    state = MODESEL;
    left_display.update_msg("MODE");
    right_display.update_msg("SEL");
    menumodetimer.start();
  } elsif (menumodetimer.isRunning){
    menumodetimer.stop();
  }
};

var menumodetimer = maketimer(3,func() {
  state = FLITID;
  left_display.update_msg("FLIT");
  right_display.update_msg("ID");
});
menumodetimer.singleShot = 1;

var button_ent = func(s) {
  if (mode == OFF) return;
  if (state == NORMAL and s != RELEASE) {
    state = NEXTCOD;
    left_display.update_msg("NEXT");
    right_display.update_msg("COD");
  } elsif (state == NEXTCOD and s != RELEASE) {
    normal_return();
  } elsif (state == MODESEL and s != RELEASE ) {
    left_display.update_msg("  AC");
    right_display.update_msg("CEPT");
    accept_clear.start();
  } elsif (state == MODE1ENTRY and s != RELEASE) {
    forindex(var i; digit_entry){
      mode1id[i+2] = digit_entry[i];
    }
    left_display.update_msg("  AC");
    right_display.update_msg("CEPT");
    setmode1();
    accept_clear.start();
  }
  if (state == MODE2ENTRY and s != RELEASE) {
    forindex(var i; digit_entry){
      if (digit_entry[i] > 7) {
        return;
      }
    }
    forindex(var i; digit_entry){
      mode2id[i] = digit_entry[i];
    }
    left_display.update_msg("  AC");
    right_display.update_msg("CEPT");
    setmode2();
    accept_clear.start();
  }
  if (state == MODE3ENTRY and s != RELEASE) {
    forindex(var i; digit_entry){
      if (digit_entry[i] > 7) {
        return;
      }
    }
    forindex(var i; digit_entry){
      mode3id[i] = digit_entry[i];
    }
    left_display.update_msg("  AC");
    right_display.update_msg("CEPT");
    setmode3();
    accept_clear.start();
  }
  if (state == MODE4ENTRY and s != RELEASE) {
    forindex(var i; digit_entry){
      if (digit_entry[i] > 7) {
        return;
      }
    }
    forindex(var i; digit_entry){
      mode4id[i] = digit_entry[i];
    }
    left_display.update_msg("  AC");
    right_display.update_msg("CEPT");
    setmode4();
    accept_clear.start();
  }
  if (state == MODE5ENTRY and s != RELEASE) {
    forindex(var i; digit_entry){
      if (digit_entry[i] > 7) {
        return;
      }
    }
    forindex(var i; digit_entry){
      mode5id[i] = digit_entry[i];
    }
    left_display.update_msg("  AC");
    right_display.update_msg("CEPT");
    setmode5();
    accept_clear.start();
  }
};

var accept_clear = maketimer(1,func(){
  state = NORMAL;
  getmode3();
  left_display.update_msg("  " ~ mode1id[2] ~ mode1id[3]);
  left_display.show();
  right_display.update_msg(mode3id[0] ~ mode3id[1] ~ mode3id[2] ~ mode3id[3]);
  right_display.show();
});
accept_clear.singleShot = 1;


var button_acas = func(s) {
  if (mode == OFF) return;

};

var button_clr = func(s) {
  if (mode == OFF) return;
  if (s != RELEASE) {
    clear_button_timer.start();
  } elsif (clear_button_timer.isRunning) {
    clear_button_timer.stop();
  }
  if (state == MODE3ENTRY and s != RELEASE) {
    #print('should be clearning');
    var entrytoclear = 3;
    var msg = "";
    var i = 0;
    forindex(i;digit_entry){
      if (digit_entry[i] == 8) {
        entrytoclear = i - 1;
        break;
      }
    }
    if (entrytoclear >= 0 and entrytoclear <= 3) { digit_entry[entrytoclear] = 8; }
    forindex(i; digit_entry){
      if (digit_entry[i] == 8) {
        msg = " " ~ msg;
      } else {
        msg = msg ~ digit_entry[i];
      }
    }
    right_display.update_msg(msg);
  }
};

var clear_button_timer = maketimer(1,func() {
  normal_return();
});
clear_button_timer.singleShot = 1;

var button_number = func(n, s) {
  if (mode == OFF) return;
  if (s == RELEASE) return;
  if (state == NORMAL) {
    if (n == 1) {
      # mode 1 entry
      state = MODE1ENTRY;
      digit_entry = [8,8];
      right_display.update_msg("DRCT");
      left_display.update_msg("");
    } elsif (n == 2) {
      # mode 2 entry
      state = MODE2ENTRY;
      digit_entry = [8,8,8,8];
      left_display.update_msg("DRCT");
      right_display.update_msg("");
    } elsif (n == 3) {
      # mode 3 entry
      state = MODE3ENTRY;
      digit_entry = [8,8,8,8];
      left_display.update_msg("DRCT");
      right_display.update_msg("");
    } elsif (n == 4) {
      # mode 4 entry
      state = MODE4ENTRY;
      digit_entry = [8,8,8,8];
      left_display.update_msg("DRCT");
      right_display.update_msg("");
    } elsif (n == 5) {
      # mode 5 entry
      state = MODE5ENTRY;
      digit_entry = [8,8,8,8];
      left_display.update_msg("DRCT");
      right_display.update_msg("");
    }
  } elsif (state == MODESEL) {
    if (n < 6) {
      enabled[n - 1] = enabled[n - 1] * -1 + 1;
    } elsif (n == 7) {
      enabled[5] = enabled[5] * -1 + 1;
      print(enabled[5]);
    }
    update_all_mode_ids();
    set_tx_knob_state();
    update_mode_leds();
  } elsif (state == MODE1ENTRY) {
    var msg = "  ";
    var i = 0;
    forindex(i;digit_entry){
      if (digit_entry[i] == 8) {
        break;
      }
    }
    if (i > 1) { return; }
    if (i == 0) {
      digit_entry[i] = n;
    } elsif (i == 1 and n < 4) {
      digit_entry[i] = n;
    }
    forindex(i; digit_entry){
      if (digit_entry[i] == 8) {
        msg = " " ~ msg;
      } else {
        msg = msg ~ digit_entry[i];
      }
    }
    right_display.update_msg(msg);
  } elsif (state == MODE2ENTRY or state == MODE3ENTRY or state == MODE4ENTRY or state == MODE5ENTRY) {
    var msg = "";
    var i = 0;
    forindex(i;digit_entry){
      if (digit_entry[i] == 8) {
        digit_entry[i] = n;
        break;
      }
    }
    if (i > 3) {return;}
    forindex(i; digit_entry){
      if (digit_entry[i] == 8) {
        msg = " " ~ msg;
      } else {
        msg = msg ~ digit_entry[i];
      }
    }
    right_display.update_msg(msg);
  } elsif (state == NEXTCOD) {
    if (n == 2) {
      var msg = "";
      forindex(var i; mode2id) {
        msg = msg ~ mode2id[i];
      }
      right_display.update_msg(msg);
    } elsif (n == 4) {
      var msg = "";
      forindex(var i; mode4id) {
        msg = msg ~ mode4id[i];
      }
      right_display.update_msg(msg);
    } elsif (n == 5) {
      var msg = "";
      forindex(var i; mode5id) {
        msg = msg ~ mode5id[i];
      }
      right_display.update_msg(msg);
    }
  }
};

var led_decrease = maketimer(0.1,func(){
  led_brightness = led_brightness == 0 ? 0 : led_brightness - 1;
  update_leds();
});

var led_increase = maketimer(0.1,func(){
  led_brightness = led_brightness == 63 ? 63 : led_brightness + 1;
  update_leds();
});

var switch_dim = func(s) {
  p = dim_prop.getValue();
  if (s == LEFT) {
    p = p + 1;
  } elsif (s == MIDDLE) {
    p = -1;
  } elsif (s == RELEASE) {
    if (p == 1) {
      p = 0;
    }
  }
  dim_prop.setValue(p);
  if (p == 1) {
    if (!led_increase.isRunning){
      led_increase.start();
    }
  } elsif (p == 0) {
    led_increase.stop();
    led_decrease.stop();
  } elsif (p == -1) {
    if (!led_decrease.isRunning){
      led_decrease.start();
    }
  }
};

var switch_diag = func(s) {
  p = diag_prop.getValue();
  if (s == LEFT) {
    p = 1;
  } elsif (s == MIDDLE) {
    p = p - 1;
  } elsif (s == RELEASE) {
    if (p == -1) {
      p = 0;
    }
  }
  diag_prop.setValue(p);
  if (mode != OFF) {
    if (p == -1) {
      # test mode on
      forindex(i;leds) {
        leds[i].test_on();
      };
    } elsif (p == 0) {
      forindex(i;leds) {
        leds[i].test_off();
      };
    }
  }

  update_leds();
};

var switch_posid = func(s) {
  # has no function in FG's current implementation
  # otherwise would send an ID with PTT.
  if (s == LEFT) {
    posid_prop.setValue(1);
  } elsif (s == MIDDLE) {
    posid_prop.setValue(posid_prop.getValue() - 1);
  } elsif (s == RELEASE) {
    if (posid_prop.getValue() == -1) {
      posid_prop.setValue(0);
    }
  }
};

var switch_zero = func(s) {
  if (s == LEFT) {
    zero_prop.setValue(1);
  } elsif (s == MIDDLE) {
    zero_prop.setValue(zero_prop.getValue() - 1);
  } elsif (s == RELEASE) {
    if (zero_prop.getValue() == -1) {
      zero_prop.setValue(0);
    }
  }
};

var switch_ab = func(s) {
  if (s != RELEASE) {
    ab_prop.setValue(ab_prop.getValue() * -1 + 1);
  }
};

var switch_flt = func(s) {
  if (s != RELEASE) {
    flt_prop.setValue(1);
  } else {
    flt_prop.setValue(0);
  }
};

var switch_warn = func(s) {
  p = warn_prop.getValue();
  if (s == LEFT) {
    p = p == 1 ? 1 : p + 1;
  } elsif (s == MIDDLE) {
    p = p == -1 ? -1 : p - 1;
  }
  warn_prop.setValue(p);
};

var switch_ops = func (s) {
  if (s != RELEASE) {
    ops_prop.setValue(ops_prop.getValue() * -1 + 1);
  }
};

var switch_mil = func (s) {
  p = mil_prop.getValue();
  if (s == LEFT) {
    p = p == 1 ? 1 : p + 1;
  } elsif (s == MIDDLE) {
    p = p == -1 ? -1 : p - 1;
  }
  mil_prop.setValue(p);
};

var knob_power = func(s) {
  p = power_prop.getValue();
  if (s == LEFT) {
    p = p == 3 ? 3 : p + 1;
  } elsif (s == MIDDLE) {
    p = p == 0 ? 0 : p - 1;
  }
  power_prop.setValue(p);
  if (mode == OFF and p > 0) {
    # transponder switching from off to on
    transponder_on();
  } elsif (mode > OFF and p == 0) {
    # transponder switching from on to off
    transponder_off();
  }
  if (p == 0) {
    tx_knob_mode_prop.setValue(0);
  } elsif (p == 1) {
    tx_knob_mode_prop.setValue(1);
    forindex(i;leds) {
      leds[i].off();
    };
  } elsif (p > 1) {
    tx_knob_mode_prop.setValue(3);
    update_mode_leds();
  }
  mode = p;
  set_tx_knob_state();
};

var set_tx_knob_state = func() {
  if (mode == OFF) {
    tx_knob_mode_prop.setValue(0);
  } elsif (mode == STBY) {
    tx_knob_mode_prop.setValue(1);
  } elsif (mode > STBY and enabled[2]) {
    tx_knob_mode_prop.setValue(4);
  } elsif (mode > STBY and enabled[2] and enabled[5]) {
    tx_knob_mode_prop.setValue(5);
  }
}

var transponder_on = func() {
  getmode3();
  left_display.update_msg("  " ~ mode1id[2] ~ mode1id[3]);
  left_display.show();
  right_display.update_msg(mode3id[0] ~ mode3id[1] ~ mode3id[2] ~ mode3id[3]);
  right_display.show();
}


var transponder_off = func() {
  left_display.hide();
  right_display.hide();
  forindex(i;leds) {
    leds[i].off();
  };
};

var update_leds = func() {
  forindex(i;leds) {
    if (leds[i].state) {
      leds[i].set(get_led_brightness());
    }
  };
};

var normal_return = func() {
  state = NORMAL;
  getmode3();
  left_display.update_msg("  " ~ mode1id[2] ~ mode1id[3]);
  left_display.show();
  right_display.update_msg(mode3id[0] ~ mode3id[1] ~ mode3id[2] ~ mode3id[3]);
  right_display.show();
}

var get_led_brightness = func() { return led_brightness / 63; };
var get_display_brightness = func() { return display_brightness / 63; };

left_display = LCDCBU412.new({"node": "Display_Left"});
right_display = LCDCBU412.new({"node": "Display_Right"});

var setmode1 = func() {
  if (enabled[0]) {
    mode1id_prop.setValue(str(mode1id[2]) ~ str(mode1id[3]));
  } else {
    mode1id_prop.setValue("-9999");
  }
}

var setmode2 = func() {
  if (enabled[1]) {
    var msg = "";
    forindex(var i; mode2id) {
      msg = msg ~ mode2id[i];
    }
    mode2id_prop.setValue(msg);
  } else {
    mode2id_prop.setValue("-9999");
  }
}

var getmode3 = func() {
  mode3id[0] = mode3id0_prop.getValue();
  mode3id[1] = mode3id1_prop.getValue();
  mode3id[2] = mode3id2_prop.getValue();
  mode3id[3] = mode3id3_prop.getValue();
}

var setmode3 = func() {
  mode3id0_prop.setValue(mode3id[0]);
  mode3id1_prop.setValue(mode3id[1]);
  mode3id2_prop.setValue(mode3id[2]);
  mode3id3_prop.setValue(mode3id[3]);
}

var setmode4 = func() {
  if (enabled[3]) {
    var msg = "";
    forindex(var i; mode4id) {
      msg = msg ~ mode4id[i];
    }
    mode4id_prop.setValue(msg);
  } else {
    mode4id_prop.setValue("-9999");
  }
  mode4int_prop.setValue(int(msg));
}

var setmode5 = func() {
  if (enabled[4]) {
    var msg = "";
    forindex(var i; mode5id) {
      msg = msg ~ mode5id[i];
    }
    mode5id_prop.setValue(msg);
  } else {
    mode5id_prop.setValue("-9999");
  }
}

var update_mode_leds = func() {
  if (enabled[0]) {
    led_1.on();
  } else {
    led_1.off();
  }
  if (enabled[1]) {
    led_2.on();
  } else {
    led_2.off();
  }
  if (enabled[2]) {
    led_3a.on();
    led_c.on();
  } else {
    led_3a.off();
    led_c.off();
  }
  if (enabled[3]) {
    led_4.on();
  } else {
    led_4.off();
  }
  if (enabled[4]) {
    led_5.on();
  } else {
    led_5.off();
  }
  if (enabled[5]) {
    led_s.on();
  } else {
    led_s.off();
  }
}

var update_all_mode_ids = func() {
  setmode1();
  setmode2();
  setmode3();
  setmode4();
  setmode5();
}

var txid_listener = setlistener(mode3id_prop,func(p) {
  if (isint(p)){
    if (p >= 0) {
      getmode3();
    }
  }
},nil,0);

transponder_off();
