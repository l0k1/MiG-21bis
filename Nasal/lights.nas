beacon_switch = props.globals.getNode("controls/switches/beacon", 2);
var beacon = aircraft.light.new( "/sim/model/lights/beacon", [0, 3], "/controls/lighting/beacon" );
strobe_switch = props.globals.getNode("controls/switches/strobe", 2);
var strobe = aircraft.light.new( "/sim/model/lights/strobe", [0, 3], "/controls/lighting/strobe" );