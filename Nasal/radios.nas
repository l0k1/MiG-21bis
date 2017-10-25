
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
	var freq = getprop("/instrumentation/adf-radio/preset[" ~ selection ~ "]");
	setprop("/instrumentation/adf[0]/frequencies/selected-khz",freq);
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
setlistener("/instrumentation/adf/inbound-outbound-switch",func(){update_adf_radio();});

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

# inner/outer switch loop

var inner_outer_adf_finder = func() {
	var switch_state = getprop("/instrumentation/adf/inbound-outbound-switch");
	var freq = getprop("/instrumentation/adf-radio/preset[" ~ getprop("/instrumentation/adf-radio/selection") ~ "]");
	if (getprop("/instrumentation/adf/inbound-outbound-switch") == 1 ) {
		var my_geo = geo.aircraft_position();

		#get all nearby ndb's
		var ndb_close_distance = 120;
		var dist = 0;
		var ndb_geo = geo.Coord.new();
		var search_ndbs = findNavaidsWithinRange(ndb_close_distance,"ndb");

		if ( search_ndbs != nil ) {
			#print("first search turned up something");
			var best_ndb = 0;

			#print("searching for freq: " ~ freq * 100);

			foreach (var ndb; search_ndbs) {
				#print("ndb.freq: " ~ ndb.frequency);
				if ( ndb.frequency == freq * 100 ) {
					ndb_geo.set_latlon(ndb.lat,ndb.lon,ndb.elevation);
					dist = my_geo.distance_to(ndb_geo) * M2NM;
					#print("dist: " ~ dist);
					if (dist < ndb_close_distance) {
						dist = ndb_close_distance;
						best_ndb = ndb;
					}
				}
			}

			#print("now...");
			#if (best_ndb != 0 ) {
			#	print("size: " ~ size(best_ndb.id));
			#}
			
			if ( best_ndb != 0 and size(best_ndb.id) == 2 ) {
				#print("we found a valid navaid");
				var new_ndb_id = left(best_ndb.id,1);
				ndb_geo.set_latlon(best_ndb.lat,best_ndb.lon,best_ndb.elevation);
				search_ndbs = findNavaidsByID(ndb_geo,new_ndb_id,"ndb");

				if ( search_ndbs != nil ) {
					#print("closest ndb: " ~ search_ndbs[0].id);
					var this_new_distance = ndb_geo.distance_to(geo.Coord.new().set_latlon(search_ndbs[0].lat,search_ndbs[0].lon,search_ndbs[0].elevation)) * M2NM;
					#print("distance to new ndb: " ~ this_new_distance);
					if (  this_new_distance < 10 ) {
						setprop("/instrumentation/adf[0]/frequencies/selected-khz",search_ndbs[0].frequency/100);
					}
				}

			}
		}
	} else {
		setprop("/instrumentation/adf[0]/frequencies/selected-khz",freq);
	}
	settimer(func(){inner_outer_adf_finder();},1);
}

inner_outer_adf_finder();
