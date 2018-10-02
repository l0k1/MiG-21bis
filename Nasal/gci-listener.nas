# (c) 2018 pinto
# looks for and listens to gci stations
# will send one gci request per "on" switch
# will show up on screen as what appears to be a chat message,
# but will only show up for that specific player.

# change the format of the BRAA report in the send_msg() function.

# todo:
# will only listen to the closest gci station, or the first non-null station


# gci_prop is a bool.
# must be aliased to a /sim/multiplay/generic/bool node.
# this node must also be synced with the gci database.
# ask pinto about adding a new node for your model(s).

var gci_prop = props.globals.getNode("/instrumentation/gci/request");

# time in seconds to wait for a GCI response, before setting gci_prop to false.
var max_listen_time = 10;

# update rate in seconds
var update_rate = 1;

# mp models to check for gci BRAA messages
var gci_models = [
    "gci",
];

# used variables
var iter = 0;
var last_msg_id = -1;
var model = "";
var dist = 99999999;
var cs_node = props.globals.getNode("/sim/multiplay/callsign");
var msgdata = [];

var main_loop = func() {
    if (gci_prop.getValue() == 1) {
        iter = iter + 1;
        my_callsign = cs_node.getValue();
        dist = 99999999;
        msgdata = [];
        foreach (var mp; props.globals.getNode("/ai/models").getChildren("multiplayer")) {
            model = remove_suffix(remove_suffix(split(".", split("/", source.getNode("sim/model/path").getValue())[-1])[0], "-model"), "-anim");
            dist_to = geo.aircraft_position().distance_to(geo.Coord.new().set_latlon(mp.getNode("position/latitude-deg"),mp.getNode("position/longitude-deg")));
            if (find_match(model,gci_models) == 0) { continue; }
            if (dist_to < dist) {
                foreach (var msg; mp.getChildren("sim/multiplay/generic/string")) {
                    if (find(cs_node.getValue(),msg.getValue()) == -1) { continue; }
                    msgdata = split(":",msg.getValue());
                    if (last_msg_id == msgdata[1]) { 
                        msgdata = [];
                        continue; 
                    } else {
                        dist = dist_to;
                        msgdata[6] = mp.getNode("callsign");
                    }
                }
            }
        }
        
        if (msgdata[2] != nil) {
            send_msg(msgdata);
            gci_prop.setValue(0);
        }
        
        if ( iter / update_rate > max_listen_time ) {
            screen.log.write("No response to the GCI request.", 1.0, 0.2, 0.2);
            gci_prop.setValue(0);
        }
    }
    
    settimer(func() { main_loop(); }, update_rate);
}

main_loop();

var send_msg = func(msg) {
    # msg should be a vector in the form of: 
    # destination callsign, id, bearing (degrees), range (meters), altitude (feet), aspect (degrees), sender callsign
    # if the gci couldnt find anybody, it will send a 'null' string for [2] through [5]
    # altitude is rounded to the nearest 100.
    
    if ( size(msg) != 7 ) {
        return; # message is invalid
    }
    
    output = msg[0] ~ ", " ~ msg[6] ~ ", ";
    
    if ( msg[2] == "null" ) {
        output = output ~ "no contact to report.";
    } else {
        output = output ~ "bandit " ~ msg[2] ~ " at " ~ int(round(msg[3],1000)/1000) ~ "km, ";
        output = output ~ "altitude " ~ int(round(msg[3] * FT2M,100)) ~ "m, ";
        msg[4] = math.abs(msg[4]);
        var aspect = "unknown aspect";
        if (msg[4] > 110) {
            aspect = "dragging";
        } elsif (msg[4] > 70) {
            aspect = "beaming";
        } elsif (msg[4] > 30) {
            aspect = "flanking";
        } else {
            aspect = "hot";
        }
        output = output ~ aspect ~ ".";
    }
    screen.log.write(output, 1.0, 0.2, 0.2);
}

var find_match = func(val,vec) {
    foreach (var a; vec) {
        if (a == val) { return 1; }
    }
    return 0;
}

var remove_suffix = func(s, x) {
    var len = size(x);
    if (substr(s, -len) == x)
        return substr(s, 0, size(s) - len);
    return s;
}