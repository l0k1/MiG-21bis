io.include("Aircraft/Generic/Systems/failures.nas");

var reset_failures = func() {
	if (!(getprop("fdm/jsbsim/gear/unit/WOW") and getprop("fdm/jsbsim/gear/unit[1]/WOW") and getprop("fdm/jsbsim/gear/unit[2]/WOW"))) {
		screen.log.write("Cannot reset airframe while flying.");
	} else {
		screen.log.write("Airframe damage reset.");
		crashandstress.repair();
		setprop("/fdm/jsbsim/propulsion/engine[0]/damage-norm",0);
	}
};

var set_value = func(path, value) {

    var default = getprop(path);

    return {
        parents: [FailureMgr.FailureActuator],
        set_failure_level: func(level) setprop(path, level > 0 ? value : default),
        get_failure_level: func { getprop(path) == default ? 0 : 1 }
    }
};


# random failure code:

var prop = "/instrumentation/gunsight";
var gunsight_trigger = MtbfTrigger.new(12000);
var gunsight_actuator = compat_failure_modes.set_unserviceable(prop);
FailureMgr.add_failure_mode(prop, "Gunsight", gunsight_actuator);
FailureMgr.set_trigger(prop, gunsight_trigger);
gunsight_trigger.arm();
