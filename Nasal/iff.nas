# IFF system
# turns a channel number into an iff md5 hash
#
#
# installation instructions:
#
# load this nasal file at the bottom of your set file like normal.
# in your set file, under <instrumentation> <iff>
#
# <channel type="string">
# required. property path to whatever property your using to keep track of your iff channel selection.
# channels can be ints, strings, or floats.
# <iff_mp_string type="int">
# optional, default 4. the generic mp property to send and recieve hashes on. /ai/models/multiplayer[x]/generic/string[iff_mp_string]
# <iff_hash_length type="int">
# optional, default 3. how long the hash string should be. recommended 3 or 4, 1 or 2 are not recommended due to hash collisions. 3 has 46,656 possible combinations.
# <iff_unique_id type="string">
# optional, default "". if you'd like to only have your planes match with a certain subset, set iff_unique_id to "NATO" or "WARSAW" or whatever you'd like.
# <iff_refresh_rate type="int">
# optional, default 120. how quickly the hash will change. this needs to be an int, and synced with other planes.
#
#
# to use:
#
# interrogate(tgt)
# tgt should be a node pointing to the targets /ai/models/multiplayer[x] root
# returns 1 if a match, otherwise 0.
#

var iff_refresh_rate = getprop("/instrumentation/iff/iff_refresh_rate") or 120;
var iff_unique_id = getprop("/instrumentation/iff/iff_unique_id") or "";
var iff_hash_length = getprop("/instrumentation/iff/iff_hash_length") or 3;
var iff_mp_string = getprop("/instrumentation/iff/iff_mp_string") or 4;

var node = {
	channel:		getprop("/instrumentation/iff/channel"),
	hash:			"/sim/multiplay/generic/string["~iff_mp_string~"]",
	callsign:		"/sim/multiplay/callsign",
};

foreach(var name; keys(node)) {
	node[name] = props.globals.getNode(node[name], 1);
}

var iff_hash = {
	new: func() {
		var m = {parents:[iff_hash]};
		m.int_systime = int(systime());
		m.update_time = 0;
		m.time = 0; # time used in hash
		m.timer = nil; # time between loops
		m.callsign = node.callsign.getValue();
		return m;
	},
	
	loop: func() {
		me.int_systime = int(systime());
		me.update_time = int(math.mod(me.int_systime,iff_refresh_rate));
		me.time = me.int_systime - me.update_time;
		node.hash.setValue(_calculate_hash(me.time, me.callsign, node.channel.getValue()));
		#print("update time " ~ (iff_refresh_rate - me.update_time));
		if ( me.timer != nil ) {
			me.timer.restart(iff_refresh_rate - me.update_time);
		} else {
			me.timer = maketimer(iff_refresh_rate - me.update_time,func(){me.loop()});
			me.timer.start();
		}
	},
};

var interrogate = func(tgt) {
	if ( tgt.getChild("callsign").getValue() == nil or tgt.getNode("sim/multiplay/generic/string["~iff_mp_string~"]").getValue() == nil ) {
		return 0;
	}
	var hash1 = _calculate_hash(int(systime()) - int(math.mod(int(systime()),iff_refresh_rate)), tgt.getChild("callsign").getValue(),node.channel.getValue());
	var hash2 = _calculate_hash(int(systime()) - int(math.mod(int(systime()),iff_refresh_rate)) - iff_refresh_rate, tgt.getChild("callsign").getValue(),node.channel.getValue());
	var check_hash = tgt.getNode("sim/multiplay/generic/string["~iff_mp_string~"]").getValue();
	#print("hash1 " ~ hash1);
	#print("hash2 " ~ hash2);
	#print("check_hash " ~ check_hash);
	if ( hash1 == check_hash ) {
		return 1;
	} elsif (hash2 == check_hash) {
		return 1;
	} else {
		return 0;
	}
}

var _calculate_hash = func(time, callsign, channel) {
	#print("time|" ~ time ~ "|");
	#print("callsign|" ~ callsign ~ "|");
	#print("channel|" ~ channel ~ "|");
	#print("hash|"~left(md5(time ~ callsign ~ channel ~ iff_unique_id),iff_hash_length)~"|");
	return left(md5(time ~ callsign ~ channel ~ iff_unique_id),iff_hash_length);
}

var new_hashing = iff_hash.new();
new_hashing.loop();
setlistener("/instrumentation/iff/channel-selection",func(){new_hashing.loop();});
