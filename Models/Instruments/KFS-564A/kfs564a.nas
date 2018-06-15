var FALSE = 0;
var TRUE = 1;
var DOWN = 0;
var UP = 1;

var mil_mode = TRUE;

#possible modes:
# standby - frequency entered in the standby window
# active - frequency entered in the active window
# channel - frequency is selected via channels
# program mode - programming channels.

var OFF = 0;
var STANDBY = 1;
var ACTIVE = 2;
var CHANNEL = 3;
var PROGRAM = 4;
var mode = OFF;
var program_mode = CHANNEL;
var old_mode = STANDBY;

var channels = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
var cur_channel = 1;

var transfer_press_time = 0;
var channel_press_time = 0;
var tfreq = 0;
var chan_button = FALSE;
var chan_timeout = maketimer(5,func(){
  if (mode == CHANNEL) {
    if ( old_mode == CHANNEL or old_mode == PROGRAM ) {
      old_mode = STANDBY;
    }
    mode = old_mode;
    if (active_freq.getValue == 0) {
        active_freq.setValue(tfreq);
    }
    if (channels[cur_channel] != 0){
      standby_freq.setValue(channels[cur_channel]);
    }
    update_bottom(sprintf("%.2f",standby_freq.getValue()));
    update_top(sprintf("%.2f",active_freq.getValue()));
    chan_timeout.stop();
  }
});
chan_timeout.simulatedTime = TRUE;
var blink_timer = maketimer(0.25,func() {
  #program_mode = program_mode == CHANNEL ? ACTIVE : CHANNEL
  if (mode == PROGRAM){
    if ( program_mode == CHANNEL ) {
      KFS_LCD_DISPLAY.topDisplay.toggleVisibility();
      KFS_LCD_DISPLAY.bottomDisplay.show();
    } else {
      KFS_LCD_DISPLAY.bottomDisplay.toggleVisibility();
      KFS_LCD_DISPLAY.topDisplay.show();
    }
  }
});
blink_timer.simulatedTime = TRUE;
var exit_blink = func() {
  KFS_LCD_DISPLAY.topDisplay.show();
  KFS_LCD_DISPLAY.bottomDisplay.show();
  blink_timer.stop();
}


var prog_timeout = maketimer(20,func(){
  if (mode == PROGRAM) {
    if ( old_mode == CHANNEL or old_mode == PROGRAM ) {
      old_mode = STANDBY;
    }
    mode = old_mode;
    update_bottom(sprintf("%.2f",standby_freq.getValue()));
    update_top(sprintf("%.2f",active_freq.getValue()));
    prog_timeout.stop();
    exit_blink();
  }
});
prog_timeout.simulatedTime = TRUE;

var standby_freq = props.globals.getNode("/instrumentation/nav/frequencies/standby-mhz");
var active_freq = props.globals.getNode("/instrumentation/nav/frequencies/selected-mhz");
var volume = props.globals.initNode("/instrumentation/nav/volume",0.0,"DOUBLE",1);
var pwrbtn = props.globals.getNode("/instrumentation/nav/power-btn");

var volume_knob = func(amnt) {
  if ( mode == OFF and volume.getValue() + amnt >= 0 ) {
    if ( chan_button and mil_mode ) {
      mode = ACTIVE;
      pwrbtn.setValue(1);
      active_freq.setValue(110.0);;
      update_top(sprintf("%.2f",active_freq.getValue()));
    } else {
      pwrbtn.setValue(1);
      update_bottom(sprintf("%.2f",standby_freq.getValue()));
      update_top(sprintf("%.2f",active_freq.getValue()));
      mode = STANDBY;
    }
    KFS_LCD_DISPLAY.displays.show();
  } elsif ( volume.getValue() + amnt < 0 ) {
    mode = OFF;
    pwrbtn.setValue(0);
    KFS_LCD_DISPLAY.displays.hide();
    prog_timeout.stop();
    chan_timeout.stop();
    blink_timer.stop();
  }
  volume.setValue(math.clamp(volume.getValue() + amnt,-0.05,1));
}

var change_freq = func(amnt) {
  if (mode == STANDBY) {
    standby_freq.setValue(math.periodic(108,118,standby_freq.getValue() + amnt));
    update_bottom(sprintf("%.2f",standby_freq.getValue()));
  } elsif (mode == ACTIVE) {
    active_freq.setValue(math.periodic(108,118,active_freq.getValue() + amnt));
    update_top(sprintf("%.2f",active_freq.getValue()));
  } elsif (mode == CHANNEL) {
    var index = math.periodic(1,21,cur_channel + (amnt > 0 ? 1 : -1));
    while(TRUE) {
      if ( index == cur_channel ){
        break;
      }
      if ( channels[index] ) {
        cur_channel = index;
        break;
      }
      index = math.periodic(1,21,index + (amnt > 0 ? 1 : -1));
    }
    if ( cur_channel < 10 ) {
      update_top("CH" ~ sprintf("%3i",cur_channel));
    } else {
      update_top("CH" ~ sprintf("%3i",cur_channel));
    }
    if ( mil_mode ) {
      if ( cur_channel == 1 and channels[cur_channel] == 0 ) {
        chan_timeout.restart(5);
      } else {
        active_freq.setValue(channels[cur_channel]);
      }
    } else {
      chan_timeout.restart(5);
    }
    update_bottom(sprintf("%.2f",channels[cur_channel]));
  } elsif (mode == PROGRAM) {
    if (!mil_mode) {
      prog_timeout.restart(20);
    }
    if (program_mode == CHANNEL) {
      cur_channel = math.periodic(1,21,cur_channel + (amnt > 0 ? 1 : -1));
    } elsif (program_mode == ACTIVE) {
      if (channels[cur_channel] == 0) {
        if (amnt > 0) {
          channels[cur_channel] = 108;
        } else {
          channels[cur_channel] = 117.95;
        }
      } else {
        channels[cur_channel] = channels[cur_channel] + amnt;
        if (channels[cur_channel] < 108 or channels[cur_channel] > 117.95) {
          channels[cur_channel] = 0;
        }
      }
    }
    if ( cur_channel < 10 ) {
      update_top("CH" ~ sprintf("%3i",cur_channel));
    } else {
      update_top("CH" ~ sprintf("%3i",cur_channel));
    }
    update_bottom(sprintf("%.2f",channels[cur_channel]));
  }
}

var transfer_button = func(dir) {
  if ( mode == OFF ) {
    return;
  }
  if (dir == UP) {
    #print("trans up");
    if (mode == ACTIVE) {
      #print("mode is now standby");
      mode = STANDBY;
    } elsif ( mode == STANDBY and systime() - transfer_press_time < 2 ) {
      #print("switching freqs");
      tfreq = standby_freq.getValue();
      standby_freq.setValue(active_freq.getValue());
      active_freq.setValue(tfreq);
      update_bottom(sprintf("%.2f",standby_freq.getValue()));
      update_top(sprintf("%.2f",active_freq.getValue()));
    } elsif ( (mode == STANDBY or (mode==CHANNEL and mil_mode)) and systime() - transfer_press_time > 2 ) {
      #print("mode is now active");
      mode = ACTIVE;
      update_bottom(sprintf("%.2f",standby_freq.getValue()));
      update_top(sprintf("%.2f",active_freq.getValue()));
    } elsif ( mode == PROGRAM ) {
      #print("modifying program mode");
      if (!mil_mode) {
        prog_timeout.restart(20);
      }
      program_mode = program_mode == CHANNEL ? ACTIVE : CHANNEL;
    } elsif ( mode == CHANNEL ){
    #print("trans down - mode was channel");
      standby_freq.setValue(active_freq.getValue());
      active_freq.setValue(channels[cur_channel]);
      update_bottom(sprintf("%.2f",standby_freq.getValue()));
      update_top(sprintf("%.2f",active_freq.getValue()));
      chan_timeout.stop();
      mode = STANDBY;
    }
  } else {
  #print("trans down");
    transfer_press_time = systime();
  #print("transfer press time set to " ~ transfer_press_time);
  }
}

var channel_button = func(dir) {
  if ( mode == OFF ) {
  #print("channel mode is OFF");
    return;
  }
  if (dir == UP) {
  #print("channel up");
    if ( old_mode == CHANNEL or old_mode == PROGRAM ) {
      old_mode = STANDBY;
    }
    if (systime() - channel_press_time < 2 and mode != CHANNEL and mode != PROGRAM) {
    #print("setting mode to channel");
      old_mode = mode;
      mode = CHANNEL;
      tfreq = active_freq.getValue();
      if (channels[cur_channel] == 0) {
        cur_channel = 1;
      }
      if ( cur_channel < 10 ) {
        update_top("CH" ~ sprintf("%3i",cur_channel));
      } else {
        update_top("CH" ~ sprintf("%3i",cur_channel));
      }
      if (mil_mode) {
        if ( cur_channel == 1 and channels[cur_channel] == 0 ) {
          chan_timeout.restart(5);
        } else {
          active_freq.setValue(channels[cur_channel]);
        }
      } else {
        chan_timeout.restart(5);
      }
      update_bottom(sprintf("%.2f",channels[cur_channel]));
    } elsif (systime() - channel_press_time > 2) {
    #print("changing mode to program");
      old_mode = mode;
      program_mode = CHANNEL;
      if (!mil_mode) {
        prog_timeout.restart(20);
      }
      blink_timer.restart(0.25);
      mode = PROGRAM;
      cur_channel = 1;
      update_top("CH" ~ sprintf("%3i",cur_channel));
      update_bottom(sprintf("%.2f",channels[cur_channel]));
    } elsif (mode == PROGRAM) {
    #print("exiting program mode");
      prog_timeout.stop();
      exit_blink();
      mode = old_mode;
      update_bottom(sprintf("%.2f",standby_freq.getValue()));
      update_top(sprintf("%.2f",active_freq.getValue()));
    } elsif ( mode == CHANNEL ) {
    #print("exiting chanel mode");
      chan_timeout.stop();
      mode = old_mode;
      if (mil_mode) {
        active_freq.setValue(tfreq);
      }
      update_bottom(sprintf("%.2f",standby_freq.getValue()));
      update_top(sprintf("%.2f",active_freq.getValue()));
    }
  } else {
    channel_press_time = systime();
  #print("press time: " ~ channel_press_time);
  }
}

var LCDKFS564A = {

  canvas_settings: {
    "name": "LCD_KFS564A",   # The name is optional but allow for easier identification
    "size": [1024, 1024], # Size of the underlying texture (should be a power of 2, required) [Resolution]
    "view": [1024, 1024],  # Virtual resolution (Defines the coordinate system of the canvas [Dimensions]
    # which will be stretched the size of the texture, required)
    "mipmapping": 1       # Enable mipmapping (optional)
  },
  new: func(placement)
  {
    var m = {
      parents: [LCDKFS564A],
      LCD_KFS564A: canvas.new(LCDKFS564A.canvas_settings)
    };

    m.LCD_KFS564A.addPlacement(placement);
    m.LCD_KFS564A.setColorBackground(0,0,0,0);
    m.displays = m.LCD_KFS564A.createGroup();


    m.topDisplay = m.displays.createChild("text", "topDisplay")
      .setTranslation(400, 155)      # The origin is in the top left corner
      .setAlignment("right-center") # All values from osgText are supported (see $FG_ROOT/Docs/README.osgtext)
      .setFont("DSEG/DSEG7/Modern/DSEG7Modern-BoldItalic.ttf") # Fonts are loaded either from $AIRCRAFT_DIR/Fonts or $FG_ROOT/Fonts
      .setFontSize(68, 1.0)        # Set fontsize and optionally character aspect ratio
      .setColor(1,0,0);            # Text color
    m.bottomDisplay = m.displays.createChild("text", "bottomDisplay")
      .setTranslation(400, 240)      # The origin is in the top left corner
      .setAlignment("right-center") # All values from osgText are supported (see $FG_ROOT/Docs/README.osgtext)
      .setFont("DSEG/DSEG7/Modern/DSEG7Modern-BoldItalic.ttf") # Fonts are loaded either from $AIRCRAFT_DIR/Fonts or $FG_ROOT/Fonts
      .setFontSize(68, 1.0)        # Set fontsize and optionally character aspect ratio
      .setColor(1,0,0);            # Text color

    return m;
  }
};

var update_top = func(val) {
#print("top val " ~ val);
  KFS_LCD_DISPLAY.topDisplay.setText(val);
}

var update_bottom = func(val) {
#print("bottom val " ~ val);
  if ( val == 0 ) { val = "---.--" };
  KFS_LCD_DISPLAY.bottomDisplay.setText(val);
}


var KFS_LCD_DISPLAY = 0;
var init = setlistener("/sim/signals/fdm-initialized", func() {
  removelistener(init); # only call once
  KFS_LCD_DISPLAY = LCDKFS564A.new({"node": "kfs564aLCD"});
  volume_knob(-0.05);
  update_bottom(sprintf("%.2f",standby_freq.getValue()));
  update_top(sprintf("%.2f",active_freq.getValue()));
});
