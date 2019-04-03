#props tied in to sounds
var disconnect_prop = props.globals.getNode("/sounds/pylon_disconnect");
var distant_explosion_prop = props.globals.getNode("/sounds/distant_explosion");

#timers to reset props
var disconnect_timer = maketimer(0.05, func() {disconnect_prop.setValue(0);});
disconnect_timer.singleShot = 1;
var distant_explosion_timer = maketimer(0.05, func() {distant_explosion_prop.setValue(0);});
distant_explosion_timer.singleShot = 1;

#functions to call
var disconnect = func() {
	if (disconnect_prop.getValue() == 0) {
		disconnect_prop.setValue(1);
		disconnect_timer.start();
	}
}

var boom = func(distance) {
	# distance should be in meters
	# mixing settimer and maketimer in one file?! sacre bleu!
	settimer(func(){_explosion();}, distance/343);
}

var _explosion = func() {
	if (distant_explosion_prop.getValue() == 0) {
		distant_explosion_prop.setValue(1);
		distant_explosion_timer.start();
	}
}