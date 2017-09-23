# AUTOPILOT LOGIC

var modes = {
	"off": 0,
	"cmd": 0,
	"auto": 4,
	"stab": 3,
	"level": 2,
	"low-alt": 1,
};

# called from autopilot_panel.xml
var panel_button = func(pressed) {
	foreach(var light; props.globals.getNode("/instrumentation/autopilot/lights").getChildren()) {
		if (light.getName() != pressed) { 
			light.setValue(0); 
		} elsif (light.getName() == pressed) {
			light.setValue(1);
		}
	}
	if (contains(modes, pressed)) {
		props.globals.getNode("/autopilot/locks/mode").setValue(modes[pressed]);
	}
}
