var FALSE = 0;
var TRUE = 1;

var electric_power_prop = 1; # ignore for now, for mig-21 do a loop that checks that we have electricity.

var update_timer = nil;

var kdi572display = {

  canvas_settings: {
    "name": "DISPLAY_KDI-572",   # The name is optional but allow for easier identification
    "size": [1024, 1024], # Size of the underlying texture (should be a power of 2, required) [Resolution]
    "view": [1024, 1024],  # Virtual resolution (Defines the coordinate system of the canvas [Dimensions]
    # which will be stretched the size of the texture, required)
    "mipmapping": 1       # Enable mipmapping (optional)
  },
  new: func(placement)
  {
    var m = {
      parents: [kdi572display],
      kdi_572_display: canvas.new(kdi572display.canvas_settings)
    };

    m.kdi_572_display.addPlacement(placement);
    m.kdi_572_display.setColorBackground(0,0,0,0);
    m.displays = m.kdi_572_display.createGroup();

    m.nav1_loc = "/instrumentation/nav[0]/frequencies/selected-mhz";
    m.nav2_loc = "/instrumentation/nav[1]/frequencies/selected-mhz";
    m.nav_hold_loc = "/instrumentation/dme/frequencies/hold";
    m.lastsetting = 0;

    m.prop_knob = props.globals.getNode("/instrumentation/dme/switch-position");
    m.prop_knot = props.globals.getNode("/instrumentation/dme/KDI572-574/kt");
    m.prop_min = props.globals.getNode("/instrumentation/dme/KDI572-574/min");
    m.prop_nm = props.globals.getNode("/instrumentation/dme/KDI572-574/nm");
    m.prop_source = props.globals.getNode("/instrumentation/dme/frequencies/source");
    m.prop_hold = props.globals.getNode(m.nav_hold_loc,1);
    m.prop_power = props.globals.getNode("/instrumentation/dme/power-btn");
    m.prop_nav1 = props.globals.getNode(m.nav1_loc);
    m.prop_nav2 = props.globals.getNode(m.nav2_loc);

    m.fontBig = 100;
    m.fontSmall = 40;


    m.knotDisplay = m.displays.createChild("text", "knotDisplay")
      .setTranslation(420, 95)      # The origin is in the top left corner
      .setAlignment("left-center") # All values from osgText are supported (see $FG_ROOT/Docs/README.osgtext)
      .setFont("DSEG/DSEG7/Modern/DSEG7Modern-BoldItalic.ttf") # Fonts are loaded either from $AIRCRAFT_DIR/Fonts or $FG_ROOT/Fonts
      .setFontSize(m.fontBig, 1.0)        # Set fontsize and optionally character aspect ratio
      .setColor(1,0,0)             # Text color
      .setText("888");
    m.minDisplay = m.displays.createChild("text", "minDisplay")
      .setTranslation(760, 95)      # The origin is in the top left corner
      .setAlignment("left-center") # All values from osgText are supported (see $FG_ROOT/Docs/README.osgtext)
      .setFont("DSEG/DSEG7/Modern/DSEG7Modern-BoldItalic.ttf") # Fonts are loaded either from $AIRCRAFT_DIR/Fonts or $FG_ROOT/Fonts
      .setFontSize(m.fontBig, 1.0)        # Set fontsize and optionally character aspect ratio
      .setColor(1,0,0)             # Text color
      .setText("88");
    m.nmDisplay = m.displays.createChild("text", "nmDisplay")
      .setTranslation(90, 95)      # The origin is in the top left corner
      .setAlignment("left-center") # All values from osgText are supported (see $FG_ROOT/Docs/README.osgtext)
      .setFont("DSEG/DSEG7/Modern/DSEG7Modern-BoldItalic.ttf") # Fonts are loaded either from $AIRCRAFT_DIR/Fonts or $FG_ROOT/Fonts
      .setFontSize(m.fontBig, 1.0)        # Set fontsize and optionally character aspect ratio
      .setColor(1,0,0)             # Text color
      .setText("88.8");
    m.sourceDisplay = m.displays.createChild("text", "srcDisplay")
      .setTranslation(340, 50)      # The origin is in the top left corner
      .setAlignment("left-center") # All values from osgText are supported (see $FG_ROOT/Docs/README.osgtext)
      .setFont("monoMMM_5.ttf") # Fonts are loaded either from $AIRCRAFT_DIR/Fonts or $FG_ROOT/Fonts
      .setFontSize(m.fontSmall, 1.0)        # Set fontsize and optionally character aspect ratio
      .setColor(1,0,0)             # Text color
      .setText("1H2");
#    m.rnvDisplay = m.displays.createChild("text", "rnvDisplay")
#      .setTranslation(685, 50)      # The origin is in the top left corner
#      .setAlignment("left-center") # All values from osgText are supported (see $FG_ROOT/Docs/README.osgtext)
#      .setFont("monoMMM_5.ttf") # Fonts are loaded either from $AIRCRAFT_DIR/Fonts or $FG_ROOT/Fonts
#      .setFontSize(m.fontSmall, 1.0)        # Set fontsize and optionally character aspect ratio
#      .setColor(1,0,0)             # Text color
#      .setText("RNV");
    m.nmStatic = m.displays.createChild("text", "nmStatic")
      .setTranslation(335, 145)      # The origin is in the top left corner
      .setAlignment("left-center") # All values from osgText are supported (see $FG_ROOT/Docs/README.osgtext)
      .setFont("monoMMM_5.ttf") # Fonts are loaded either from $AIRCRAFT_DIR/Fonts or $FG_ROOT/Fonts
      .setFontSize(m.fontSmall, 1.0)        # Set fontsize and optionally character aspect ratio
      .setColor(1,0,0)             # Text color
      .setText("NM");
    m.ktStatic = m.displays.createChild("text", "ktStatic")
      .setTranslation(665, 145)      # The origin is in the top left corner
      .setAlignment("left-center") # All values from osgText are supported (see $FG_ROOT/Docs/README.osgtext)
      .setFont("monoMMM_5.ttf") # Fonts are loaded either from $AIRCRAFT_DIR/Fonts or $FG_ROOT/Fonts
      .setFontSize(m.fontSmall, 1.0)        # Set fontsize and optionally character aspect ratio
      .setColor(1,0,0)             # Text color
      .setText("KT");
    m.minStatic = m.displays.createChild("text", "minStatic")
      .setTranslation(925, 145)      # The origin is in the top left corner
      .setAlignment("left-center") # All values from osgText are supported (see $FG_ROOT/Docs/README.osgtext)
      .setFont("monoMMM_5.ttf") # Fonts are loaded either from $AIRCRAFT_DIR/Fonts or $FG_ROOT/Fonts
      .setFontSize(m.fontSmall, 1.0)        # Set fontsize and optionally character aspect ratio
      .setColor(1,0,0)             # Text color
      .setText("MIN");

    m.prop_knob.setValue(0);
    m.displays.hide();

    return m;
  },

  update_screen: func() {
    var kt = string.replace(me.prop_knot.getValue()," ","");
    if (size(kt) == 1) {
      kt = "00" ~ kt;
    } elsif (size(kt) == 2) {
      kt = "0" ~ kt;
    }
    me.knotDisplay.setText(kt);
    var min = me.prop_min.getValue();
    if (size(min) == 1) {
      min = "0" ~ min;
    }
    me.minDisplay.setText(me.prop_min.getValue());
    var nm = me.prop_nm.getValue();
    if (size(string.replace(nm,".","")) == 2) {
      nm = "0" ~ nm;
    }
    me.nmDisplay.setText(nm);
  }
};

var display = kdi572display.new({"node": "kdi572screen"});

var knob_listener = setlistener(display.prop_knob, func() {
  v = display.prop_knob.getValue();
  if (v == 0) {
    update_timer.stop();
    display.displays.hide();
    display.prop_power.setValue(0);
  } elsif (v == 1) {
    update_timer.start();
    display.displays.show();
    display.prop_power.setValue(1);
    display.prop_source.setValue(display.nav1_loc);
    display.sourceDisplay.setText("1  ");
  } elsif (v == 2) {
    update_timer.start();
    display.displays.show();
    display.prop_power.setValue(1);
    if (display.lastsetting == 1) {
      display.prop_hold.setValue(display.prop_nav1.getValue());
      display.prop_source.setValue(display.nav_hold_loc);
    } elsif (display.lastsetting == 3) {
      display.prop_hold.setValue(display.prop_nav2.getValue());
      display.prop_source.setValue(display.nav_hold_loc);
    }
    display.sourceDisplay.setText(" H ");
  } elsif (v == 3) {
    update_timer.start();
    display.displays.show();
    display.prop_power.setValue(1);
    display.prop_source.setValue(display.nav2_loc);
    display.sourceDisplay.setText("  2");
  }
  display.lastsetting = v;
});

update_timer = maketimer(0.1,func() {display.update_screen()});

var init = setlistener("/sim/signals/fdm-initialized", func() {
  removelistener(init); # only call once
  display.update_screen();
});