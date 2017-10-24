
### VOR/ILS radio frequency handling using preset channels and a letdown/navig/landing switch
	
# /instrumentation/nav[0]/nav-mode-switch:
#    0 = letdown mode - VOR
#    1 = navig mode   - VOR
#    2 = landing mode - ILS

# this function is as "var"-less as possible, which is why it's sort of ugly.
# basically, check where the switch is, and assign nav[0] selected frequency 
# to the frequency represented by the preset channel on the radio panel. 
var update_nav_radio = func() {
	if ( getprop("/instrumentation/nav[0]/nav-mode-switch") == 2 ) {
		setprop("/instrumentation/nav[0]/frequencies/selected-mhz",getprop("/instrumentation/ils-radio/preset[" ~ getprop("/instrumentation/ils-radio/selection") ~ "]"));
	} else {
		setprop("/instrumentation/nav[0]/frequencies/selected-mhz",getprop("/instrumentation/vor-radio/preset[" ~ getprop("/instrumentation/vor-radio/selection") ~ "]"));
	}
}
	
update_nav_radio();
setlistener("/instrumentation/nav[0]/nav-mode-switch",func(){update_nav_radio();});
setlistener("/instrumentation/nav[0]/radio-tune-update",func(){update_nav_radio();});
setlistener("/instrumentation/vor-radio/selection",func(){update_nav_radio();});
setlistener("/instrumentation/ils-radio/selection",func(){update_nav_radio();});

### comm radio frequency handling using preset channels

var update_comm_radio = func() {
	setprop("/instrumentation/comm[0]/frequencies/selected-mhz",getprop("/instrumentation/comm-radio/preset[" ~ getprop("/instrumentation/comm-radio/selection") ~ "]"));
}
	
update_comm_radio();
setlistener("/instrumentation/comm[0]/radio-tune-update",func(){update_comm_radio();});
setlistener("/instrumentation/comm-radio/selection",func(){update_comm_radio();});

### adf/ndb radio frequency handling

var update_adf_radio = func() {
	var selection = getprop("/instrumentation/adf-radio/selection");
	setprop("/instrumentation/adf[0]/frequencies/selected-khz",getprop("/instrumentation/adf-radio/preset[" ~ selection ~ "]"));
	for (var i = 0; i < 9; i = i + 1 ) {
		if ( i != selection ) {
			setprop("/instrumentation/adf-radio/animation/select["~i~"]",0)
		} else {
			setprop("/instrumentation/adf-radio/animation/select["~i~"]",1)
		}
	}
}
	
update_adf_radio();
setlistener("/instrumentation/adf[0]/radio-tune-update",func(){update_adf_radio();});
setlistener("/instrumentation/adf-radio/selection",func(){update_adf_radio();});

# comm radio volume propogation
setlistener("/instrumentation/comm-radio/volume",func(){volume_propogate();});
setlistener("/instrumentation/comm-radio/rset_comp_switch",func(){volume_propogate();});

var volume_propogate = func{
	if (getprop("/instrumentation/comm-radio/rset_comp_switch") == 0) {
		setprop("/instrumentation/comm[0]/volume",getprop("/instrumentation/comm-radio/volume"));
		setprop("/instrumentation/adf[0]/volume-norm",0);
	} else {
		setprop("/instrumentation/adf[0]/volume-norm",getprop("/instrumentation/comm-radio/volume"));
		setprop("/instrumentation/comm[0]/volume",0);
	}
}

setprop("/instrumentation/comm[0]/volume",0);
setprop("/instrumentation/adf[0]/volume-norm",0);
setprop("/instrumentation/comm-radio/volume",0);


### ADF inbnd/outbound switch

# how this works in FG:
# when the inbnd/outbnd switch is hit
# the function looks at what adf we are tuned to and finds the closest airport within 5nm
# then it finds the closest adf (max 5nm from airport)
# it then tunes the adf to that new freq
# if going from inbd to outbd, look farther
# if going from outbd to inbd, look closer

# assume switch is /instrumentation/adf/inbound-outbound-switch
# 0 is outbound, 1 is inbound
var adf_inbd_outbnd = func() {
	if ( getprop("/instrumentation/adf/in-range") == 1 ) {
		var freq = getprop("/instrumentation/adf[0]/frequencies/selected-khz") / 1000;
		var ndb = findNavaidByFrequency(freq);
		if ( ndb != nil ) {
			var ndb_geo = geo.Coord.new().set_latlon(ndb.lat, ndb.lon);
			var apts = findAirportsWithinRange(ndb,5);
			if ( apts != nil ) {
				var dist_closest = 10;
				var apt_closest = apts[0];
				foreach (var apt; apts) {
					if ( apt.range_nm < dist_closest ) {
						dist_closest = apt.range_nm;
						apt_closest = apt;
					}
				}
				var apt_geo = geo.Coord.new().set_latlon(apt_closest.lat, apt_closest.lon);
				var dist = ndb_geo.distance_to(apt_geo);
				var ndbs_in_range = findNavaidsWithinRange(apt_closest,5,"ndb");
				var ndb_change = ndbs_in_range[0];
				var ndb_new_geo = geo.Coord.new();
				var dist_to_cur_ndb = 10;
				var switch_pos = getprop("/instrumentation/adf/inbound-outbound-switch");
				foreach ( var new_ndb; ndbs_in_range ) {
					ndb_new_geo.set_latlon(new_ndb.lat, new_ndb.lon);
					if ( switch_pos == 0 ) {
						if ( apt_geo.distance_to(ndb_new_geo) > dist and ndb_geo.distance_to(ndb_new_geo) < dist_to_cur_ndb ) {
							ndb_change = new_ndb;
							dist_to_cur_ndb = ndb_geo.distance_to(ndb_new_geo);
						}
					} else {
						if ( apt_geo.distance_to(ndb_new_geo) < dist and ndb_geo.distance_to(ndb_new_geo) < dist_to_cur_ndb ) {
							ndb_change = new_ndb;
							dist_to_cur_ndb = ndb_geo.distance_to(ndb_new_geo);
						}
					}
				}
				setprop("/instrumentation/adf[0]/frequencies/selected-khz",ndb_change.frequency);
			}
		}
	}
}

setlistener("/instrumentation/adf/inbound-outbound-switch",func() {adf_inbd_outbnd();});

var navaid = findNavaidByFrequency(11.17);
print("ID: ", navaid.id); # prints info about the navaid
print("Name: ", navaid.name);
print("Latitude: ", navaid.lat);
print("Longitude: ", navaid.lon);
print("Elevation (AMSL): ", navaid.elevation, " m");
print("Type: ", navaid.type);
print("Frequency: ", sprintf("%.3f", navaid.frequency / 1000), " Mhz");
print("Range: ", navaid.range_nm, " nm");
if(navaid.course) print("Course: ", navaid.course);

var pos = airportinfo("KSFO");
var apts = findAirportsWithinRange(pos, 10);
foreach(var apt; apts){
    print(apt.name, " (", apt.id, ")");
}
			
var pos = airportinfo("KSFO");
var navs = findNavaidsWithinRange(pos, 10);
foreach(var nav; navs){
    print(nav.name, " (ID: ", nav.id, ")");
}