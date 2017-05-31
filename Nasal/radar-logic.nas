#to update - radarRange
#todo: update radar_bottom_limit, ... etc.

var FALSE = 0;
var TRUE = 1;

var deg2rads = math.pi/180.0;
var rad2deg = 180.0/math.pi;
var kts2kmh = 1.852;
var feet2meter = 0.3048;
 
var radarRange = 60000;
var radarPowerRange = 30000;
var radarPowerRCS = 4;

var containsVector = func (vec, item) {
  foreach(test; vec) {
    if (test == item) {
      return TRUE;
    }
  }
  return FALSE;
}

var getClock = func (bearing) {
    var clock = int(((geo.normdeg(bearing)-15)/30)+1);
    if (clock == 0) {
      return 12;
    } else {
      return clock;
    }
}

var self = nil;
var myAlt = nil;
var myPitch = nil;
var myRoll = nil;
var myHeading = nil;

var selection = nil;
var selection_updated = FALSE;
var tracks_index = 0;
var tracks = [];
var callsign_struct = {};
var rwr = [];

var lockLog  = events.LogBuffer.new(echo: 0);#compatible with older FG?
var lockLast = nil;

var AIR = 0;
var MARINE = 1;
var SURFACE = 2;
var ORDNANCE = 3;

var RADAR_BOTTOM_LIMIT = -30;
var RADAR_TOP_LIMIT = 30;
var RADAR_LEFT_LIMIT = -30;
var RADAR_RIGHT_LIMIT = 30;

var ir_sar_switch = "/controls/armament/panel/ir-sar-switch";

input = {
        radar_serv:       "/instrumentation/radar/serviceable",
        hdgReal:          "/orientation/heading-deg",
        pitch:            "/orientation/pitch-deg",
        roll:             "/orientation/roll-deg",
        ai_models:        "/ai/models",
        lookThrough:      "/instrumentation/radar/look-through-terrain",
        dopplerOn:        "/instrumentation/radar/doppler-enabled",
        dopplerSpeed:     "/instrumentation/radar/min-doppler-speed-kt",
		    radarMode:        "/controls/radar/mode"
};

foreach(var name; keys(input)) {
    input[name] = props.globals.getNode(input[name], 1);
}

var findRadarTracks = func () {
  self      =  geo.aircraft_position();
  myPitch   =  input.pitch.getValue()*deg2rads;
  myRoll    =  input.roll.getValue()*deg2rads;
  myAlt     =  self.alt();
  myHeading =  input.hdgReal.getValue();
  
  tracks = [];

  if(input.radar_serv.getValue() > FALSE) {

    #do the MP planes
    var players = [];
    foreach(item; multiplayer.model.list) {
      append(players, item.node);
    }
    var AIplanes = input.ai_models.getChildren("aircraft");
    var tankers = input.ai_models.getChildren("tanker");
    var ships = input.ai_models.getChildren("ship");
    var vehicles = input.ai_models.getChildren("groundvehicle");
    if(selection != nil and selection.isValid() == FALSE) {
      #print("not valid");
      paint(selection.getNode(), FALSE);
      selection = nil;
    }


    processTracks(players, FALSE, FALSE, TRUE);    
    processTracks(tankers, FALSE, FALSE, FALSE, AIR);
    processTracks(ships, FALSE, FALSE, FALSE, MARINE);
#debug.benchmark("radar process AI tracks", func {    
    processTracks(AIplanes, FALSE, FALSE, FALSE, AIR);
#});
    processTracks(vehicles, FALSE, FALSE, FALSE, SURFACE);
    processCallsigns(players);

  } else {
    # Do not supply target info to the missiles if radar is off.
    if(selection != nil) {
      paint(selection.getNode(), FALSE);
    }
    selection = nil;
  }
  var carriers = input.ai_models.getChildren("carrier");
  processTracks(carriers, TRUE, FALSE, FALSE, MARINE);

  if(selection != nil) {
    #append(selection, "lock");
  }
}

var processCallsigns = func (players) {
  callsign_struct = {};
  foreach (var player; players) {
    if(player.getChild("valid") != nil and player.getChild("valid").getValue() == TRUE and player.getChild("callsign") != nil and player.getChild("callsign").getValue() != "" and player.getChild("callsign").getValue() != nil) {
      var callsign = player.getChild("callsign").getValue();
      callsign_struct[callsign] = player;
    }
  }
}


var processTracks = func (vector, carrier, missile = 0, mp = 0, type = -1) {
	#print("processing tracks");
  foreach (var track; vector) {
    if(track != nil and track.getChild("valid") != nil and track.getChild("valid").getValue() == TRUE) {#only the tracks that are valid are sent here
	  #print("track is valid: " ~ track.getChild("callsign").getValue());
#debug.benchmark("radar trackitemcalc", func {
      trackInfo = trackItemCalc(track, radarRange, carrier, mp, type);
#debug.benchmark("radar process", func {
      if(trackInfo != nil) {
		#print("valid trackinfo");
        var distance = trackInfo.get_range()*NM2M;

        # find and remember the type of the track
        var typeNode = track.getChild("model-shorter");
        var model = nil;
        if (typeNode != nil) {
          model = typeNode.getValue();
        } else {
          var pathNode = track.getNode("sim/model/path");
          if (pathNode != nil) {
            var path = pathNode.getValue();

            model = split(".", split("/", path)[-1])[0];

            model = remove_suffix(model, "-model");
            model = remove_suffix(model, "-anim");
            track.addChild("model-shorter").setValue(model);

            var funcHash = {
              #init: func (listener, trck) {
              #  me.listenerID = listener;
              #  me.trackme = trck;
              #},
              callme1: func {
                if(funcHash.trackme.getChild("valid").getValue() == FALSE) {
                  var child = funcHash.trackme.removeChild("model-shorter",0);#index 0 must be specified!
                  if (child != nil) {#for some reason this can be called two times, even if listener removed, therefore this check.
                    removelistener(funcHash.listenerID1);
                    removelistener(funcHash.listenerID2);
                  }
                }
              },
              callme2: func {
                if(funcHash.trackme.getNode("sim/model/path") == nil or funcHash.trackme.getNode("sim/model/path").getValue() != me.oldpath) {
                  var child = funcHash.trackme.removeChild("model-shorter",0);
                  if (child != nil) {#for some reason this can be called two times, even if listener removed, therefore this check.
                    removelistener(funcHash.listenerID1);
                    removelistener(funcHash.listenerID2);
                  }
                }
              }
            };
            
            funcHash.trackme = track;
            funcHash.oldpath = path;
            funcHash.listenerID1 = setlistener(track.getChild("valid"), func {call(func funcHash.callme1(), nil, funcHash, funcHash, var err =[]);}, 0, 1);
            funcHash.listenerID2 = setlistener(pathNode,                func {call(func funcHash.callme2(), nil, funcHash, funcHash, var err =[]);}, 0, 1);
          }
        }
		#print("this *should* print");
        var unique = track.getChild("unique");
        if (unique == nil) {
          unique = track.addChild("unique");
          unique.setDoubleValue(rand());
        }

        append(tracks, trackInfo);
		#print("size of tracks: " ~ size(tracks));
        if(selection == nil) {
        #  #this is first tracks in radar field, so will be default selection
        #  selection = trackInfo;
        #  selection_updated = TRUE;
          #paint(selection.getNode(), TRUE);
        #} elsif (track.getChild("name") != nil and track.getChild("name").getValue() == "RB-24J") {
          #for testing that selection view follows missiles
        #  selection = trackInfo;
        #  selection_updated = TRUE;
        } elsif (selection != nil and selection.getUnique() == unique.getValue()) {
          # this track is already selected, updating it
          #print("updating target");
          selection = trackInfo;
		  setprop("instrumentation/gunsight/distance-to-lock",selection.get_range());
          #paint(selection.getNode(), TRUE);
          selection_updated = TRUE;
        } else {
          #print("end2 "~selection.getUnique()~"=="~unique.getValue());
          paint(trackInfo.getNode(), FALSE);
        }
      } else {
        #print("end");
        paint(track, FALSE);
      }
#});      
    }#end of valid check
  }#end of foreach
}#end of processTracks

var paint = func (node, painted) {
  if (node == nil) {
    return;
  }
  var attr = node.getChild("painted");
  if (attr == nil) {
    attr = node.addChild("painted");
  }
  attr.setBoolValue(painted);
 # if(painted == TRUE) { 
    #print("painted "~attr.getPath()~" "~painted);
  #}
}

var remove_suffix = func(s, x) {
    var len = size(x);
    if (substr(s, -len) == x)
        return substr(s, 0, size(s) - len);
    return s;
}

# trackInfo
#
# 0 - x position
# 1 - y position
# 2 - direct distance in meter
# 3 - distance in radar screen plane
# 4 - horizontal angle from aircraft in rad
# 5 - identifier
# 6 - node
# 7 - not targetable

var trackItemCalc = func (track, range, carrier, mp, type) {
  var pos = track.getNode("position");
  var x = pos.getNode("global-x").getValue();
  var y = pos.getNode("global-y").getValue();
  var z = pos.getNode("global-z").getValue();
  if(x == nil or y == nil or z == nil) {
	print("trackItemCalc is returning nil FUUUUUUUUUUUUUU");
    return nil;
  }
  var aircraftPos = geo.Coord.new().set_xyz(x, y, z);
  var item = trackCalc(aircraftPos, range, carrier, mp, type, track);
  
  return item;
}

var trackCalc = func (aircraftPos, range, carrier, mp, type, node) {
  var distance = nil;
  var distanceDirect = nil;
  #print("inside trackCalc");
  call(func {distance = self.distance_to(aircraftPos); distanceDirect = self.direct_distance_to(aircraftPos);}, nil, var err = []);
  #print("distance: " ~ distance);
  #print("range: " ~ range);
  if ((size(err))or(distance==nil)) {
    # Oops, have errors. Bogus position data (and distance==nil).
    #print("Received invalid position data: dist "~distance);
    #target_circle[track_index+maxTargetsMP].hide();
    #print(i~" invalid pos.");
  } elsif (distanceDirect < range) {#is max radar range
	#print("in elsif");
    # Node with valid position data (and "distance!=nil").
    #distance = distance*kts2kmh*1000;
    var aircraftAlt = aircraftPos.alt(); #altitude in meters

    #aircraftAlt = aircraftPos.x();
    #myAlt = self.x();
    #distance = math.sqrt(pow2(aircraftPos.z() - self.z()) + pow2(aircraftPos.y() - self.y()));

    #ground angle
    var yg_rad = math.atan2(aircraftAlt-myAlt, distance) - myPitch; 
    var xg_rad = (self.course_to(aircraftPos) - myHeading) * deg2rads;

    while (xg_rad > math.pi) {
      xg_rad = xg_rad - 2*math.pi;
    }
    while (xg_rad < -math.pi) {
      xg_rad = xg_rad + 2*math.pi;
    }
    while (yg_rad > math.pi) {
      yg_rad = yg_rad - 2*math.pi;
    }
    while (yg_rad < -math.pi) {
      yg_rad = yg_rad + 2*math.pi;
    }

    #aircraft angle
    var ya_rad = xg_rad * math.sin(myRoll) + yg_rad * math.cos(myRoll);
    var xa_rad = xg_rad * math.cos(myRoll) - yg_rad * math.sin(myRoll);

    while (xa_rad < -math.pi) {
      xa_rad = xa_rad + 2*math.pi;
    }
    while (xa_rad > math.pi) {
      xa_rad = xa_rad - 2*math.pi;
    }
    while (ya_rad > math.pi) {
      ya_rad = ya_rad - 2*math.pi;
    }
    while (ya_rad < -math.pi) {
      ya_rad = ya_rad + 2*math.pi;
    }
	#print("ready to see if in cone");
    if(ya_rad > RADAR_BOTTOM_LIMIT * D2R and ya_rad < RADAR_TOP_LIMIT * D2R and xa_rad > RADAR_LEFT_LIMIT * D2R and xa_rad < RADAR_RIGHT_LIMIT * D2R) {
	  #print("xa_rad_corr: " ~ xa_rad_corr);
	  #print("xa_rad_corr_deg: " ~ xa_rad_corr * R2D);
	  #print("ya_rad_deg: " ~ ya_rad * R2D);
      #is within the radar cone
      # AJ37 manual: 61.5 deg sideways.

      if (mp == TRUE) {
        # is multiplayer
        if (isNotBehindTerrain(aircraftPos) == FALSE) {
          #hidden behind terrain
          return nil;
        }
        if (doppler(aircraftPos, node) == TRUE) {
          # doppler picks it up, must be an aircraft
          type = AIR;
        } elsif (aircraftAlt > 1) {
          # doppler does not see it, and is not on sea, must be ground target
          type = SURFACE;
        } else {
          type = MARINE;
        }
      }

      var distanceRadar = distance/math.cos(myPitch);
      var hud_pos_x = 0;#canvas_HUD.pixelPerDegreeX * xa_rad * rad2deg;
      var hud_pos_y = 0;#canvas_HUD.centerOffset + canvas_HUD.pixelPerDegreeY * -ya_rad * rad2deg;

      var contact = Contact.new(node, type);
      contact.setPolar(distanceRadar, xa_rad, ya_rad, xg_rad);
      contact.setCartesian(hud_pos_x, hud_pos_y);
      if ((rand() < 0.05?rcs.isInRadarRange(contact, radarPowerRange * M2NM, radarPowerRCS) == TRUE:rcs.wasInRadarRange(contact, radarPowerRange * M2NM, radarPowerRCS))) {# 40 / 3.2
          return contact;
      }

    } elsif (carrier == TRUE) {
      # need to return carrier even if out of radar cone, due to carrierNear calc
      var contact = Contact.new(node, type);
      contact.setPolar(900000, xa_rad, 0);
      contact.setCartesian(900000, 900000);# 900000 used in hud to know if out of radar cone.
      return contact;
    }
  }
  return nil;
}

#
# The following 6 methods is from Mirage 2000-5
#
var isNotBehindTerrain = func(SelectCoord) {
    if (getprop("mig21/advanced-radar") == TRUE) {
      var myPos = geo.aircraft_position();

      var xyz = {"x":myPos.x(),                  "y":myPos.y(),                 "z":myPos.z()};
      var dir = {"x":SelectCoord.x()-myPos.x(),  "y":SelectCoord.y()-myPos.y(), "z":SelectCoord.z()-myPos.z()};

      # Check for terrain between own aircraft and other:
      v = get_cart_ground_intersection(xyz, dir);
      if (v == nil) {
        return 1;
        #printf("No terrain, planes has clear view of each other");
      } else {
        var terrain = geo.Coord.new();
        terrain.set_latlon(v.lat, v.lon, v.elevation);
        var maxDist = myPos.direct_distance_to(SelectCoord);
        var terrainDist = myPos.direct_distance_to(terrain);
        if (terrainDist < maxDist) {
          #print("terrain found between the planes");
          return 0;
        } else {
          return 1;
          #print("The planes has clear view of each other");
        }
      }
    } else {
      var isVisible = 0;
      var MyCoord = geo.aircraft_position();
      
      # Because there is no terrain on earth that can be between these 2
      if(MyCoord.alt() < 8900 and SelectCoord.alt() < 8900 and input.lookThrough.getValue() == FALSE)
      {
          # Temporary variable
          # A (our plane) coord in meters
          var a = MyCoord.x();
          var b = MyCoord.y();
          var c = MyCoord.z();
          # B (target) coord in meters
          var d = SelectCoord.x();
          var e = SelectCoord.y();
          var f = SelectCoord.z();
          var difa = d - a;
          var difb = e - b;
          var difc = f - c;
  		
  		#print("a,b,c | " ~ a ~ "," ~ b ~ "," ~ c);
  		#print("d,e,f | " ~ d ~ "," ~ e ~ "," ~ f);
  		
          # direct Distance in meters
          var myDistance = math.sqrt( math.pow((d-a),2) + math.pow((e-b),2) + math.pow((f-c),2)); #calculating distance ourselves to avoid another call to geo.nas (read: speed, probably).
          #print("myDistance: " ~ myDistance);
  		    var Aprime = geo.Coord.new();
          
          # Here is to limit FPS drop on very long distance
          var L = 500;
          if(myDistance > 50000)
          {
              L = myDistance / 15;
          }
          var maxLoops = int(myDistance / L);
          
          isVisible = 1;
          # This loop will make travel a point between us and the target and check if there is terrain
          for(var i = 1 ; i <= maxLoops ; i += 1)
          {
            #calculate intermediate step
            #basically dividing the line into maxLoops number of steps, and checking at each step
            #to ascii-art explain it:
            #  |us|----------|step 1|-----------|step 2|--------|step 3|----------|them|
            #there will be as many steps as there is i
            #every step will be equidistant

            #also, if i == 0 then the first step will be our plane

            var x = ((difa/(maxLoops+1))*i)+a;
            var y = ((difb/(maxLoops+1))*i)+b;
            var z = ((difc/(maxLoops+1))*i)+c;
            #print("i:" ~ i ~ "|x,y,z | " ~ x ~ "," ~ y ~ "," ~ z);
            Aprime.set_xyz(x,y,z);
            var AprimeTerrainAlt = geo.elevation(Aprime.lat(), Aprime.lon());
            if(AprimeTerrainAlt == nil)
            {
              AprimeTerrainAlt = 0;
            }

            if(AprimeTerrainAlt > Aprime.alt())
            {
              return 0;
            }
          }
      }
      else
      {
          isVisible = 1;
      }
      return isVisible;
    }
}

# will return true if absolute closure speed of target is greater than 50kt
#
var doppler = func(t_coord, t_node) {
    # Test to check if the target can hide below us
    # Or Hide using anti doppler movements

    if (input.dopplerOn.getValue() == FALSE or 
        (t_node.getNode("velocities/true-airspeed-kt") != nil and t_node.getNode("velocities/true-airspeed-kt").getValue() != nil and t_node.getNode("velocities/true-airspeed-kt").getValue() > 250)
        ) {
      return TRUE;
    }

    var DopplerSpeedLimit = input.dopplerSpeed.getValue();
    var InDoppler = 0;
    var groundNotbehind = isGroundNotBehind(t_coord, t_node);

    if(groundNotbehind)
    {
        InDoppler = 1;
    } elsif(abs(get_closure_rate_from_Coord(t_coord, t_node)) > DopplerSpeedLimit)
    {
        InDoppler = 1;
    }
    return InDoppler;
}

var isGroundNotBehind = func(t_coord, t_node){
    var myPitch = get_Elevation_from_Coord(t_coord);
    var GroundNotBehind = 1; # sky is behind the target (this don't work on a valley)
    if(myPitch < 0)
    {
        # the aircraft is below us, the ground could be below
        # Based on earth curve. Do not work with mountains
        # The script will calculate what is the ground distance for the line (us-target) to reach the ground,
        # If the earth was flat. Then the script will compare this distance to the horizon distance
        # If our distance is greater than horizon, then sky behind
        # If not, we cannot see the target unless we have a doppler radar
        var distHorizon = geo.aircraft_position().alt() / math.tan(abs(myPitch * D2R)) * M2NM;
        var horizon = get_horizon( geo.aircraft_position().alt() *M2FT, t_node);
        var TempBool = (distHorizon > horizon);
        GroundNotBehind = (distHorizon > horizon);
    }
    return GroundNotBehind;
}

var get_Elevation_from_Coord = func(t_coord) {
    # fix later: Nasal runtime error: floating point error in math.asin() when logged in as observer:
    var myPitch = math.asin((t_coord.alt() - geo.aircraft_position().alt()) / t_coord.direct_distance_to(geo.aircraft_position())) * R2D;
    return myPitch;
}

var get_horizon = func(own_alt, t_node){
    var tgt_alt = t_node.getNode("position/altitude-ft").getValue();
    if(debug.isnan(tgt_alt))
    {
        return(0);
    }
    if(tgt_alt < 0 or tgt_alt == nil)
    {
        tgt_alt = 0;
    }
    if(own_alt < 0 or own_alt == nil)
    {
        own_alt = 0;
    }
    # Return the Horizon in NM
    return (2.2 * ( math.sqrt(own_alt * FT2M) + math.sqrt(tgt_alt * FT2M)));# don't understand the 2.2 conversion to NM here..
}

var get_closure_rate_from_Coord = func(t_coord, t_node) {
    var MyAircraftCoord = geo.aircraft_position();

    if(t_node.getNode("orientation/true-heading-deg") == nil) {
      return 0;
    }

    # First step : find the target heading.
    var myHeading = t_node.getNode("orientation/true-heading-deg").getValue();
    
    # Second What would be the aircraft heading to go to us
    var myCoord = t_coord;
    var projectionHeading = myCoord.course_to(MyAircraftCoord);
    
    if (myHeading == nil or projectionHeading == nil) {
      return 0;
    }

    # Calculate the angle difference
    var myAngle = myHeading - projectionHeading; #Should work even with negative values
    
    # take the "ground speed"
    # velocities/true-air-speed-kt
    var mySpeed = t_node.getNode("velocities/true-airspeed-kt").getValue();
    var myProjetedHorizontalSpeed = mySpeed*math.cos(myAngle*D2R); #in KTS
    
    #print("Projetted Horizontal Speed:"~ myProjetedHorizontalSpeed);
    
    # Now getting the pitch deviation
    var myPitchToAircraft = - t_node.getNode("radar/elevation-deg").getValue();
    #print("My pitch to Aircraft:"~myPitchToAircraft);
    
    # Get V speed
    if(t_node.getNode("velocities/vertical-speed-fps").getValue() == nil)
    {
        return 0;
    }
    var myVspeed = t_node.getNode("velocities/vertical-speed-fps").getValue()*FPS2KT;
    # This speed is absolutely vertical. So need to remove pi/2
    
    var myProjetedVerticalSpeed = myVspeed * math.cos(myPitchToAircraft-90*D2R);
    
    # Control Print
    #print("myVspeed = " ~myVspeed);
    #print("Total Closure Rate:" ~ (myProjetedHorizontalSpeed+myProjetedVerticalSpeed));
    
    # Total Calculation
    var cr = myProjetedHorizontalSpeed+myProjetedVerticalSpeed;
    
    # Setting Essential properties
    #var rng = me. get_range_from_Coord(MyAircraftCoord);
    #var newTime= ElapsedSec.getValue();
    #if(me.get_Validity())
    #{
    #    setprop(me.InstrString ~ "/" ~ me.shortstring ~ "/closure-last-range-nm", rng);
    #    setprop(me.InstrString ~ "/" ~ me.shortstring ~ "/closure-rate-kts", cr);
    #}
    
    return cr;
}

var lockTarget = func() {
	if ( getprop(ir_sar_switch) == 2 ) {
		var c_dist = 999999;
		var c_most = nil;
		var i = -1;
		var lowerBar = (getprop("/controls/radar/lock-bars-pos")/950) * radarRange;
		var upperBar = ((getprop("/controls/radar/lock-bars-pos")+getprop("controls/radar/lock-bars-scale")) / 950) * radarRange;
		var centerBar = (upperBar + lowerBar) / 2;
		foreach(var track; tracks) {
			i += 1;
			var dist_rad = track.get_polar();
			#print("distance: " ~ dist_rad[0]);
			#print("x_ang: " ~ (dist_rad[1] * R2D));
			#print("y_ang: " ~ (dist_rad[3] * R2D));
			#print("lowerBar: " ~ lowerBar);
			#print("upperBar: " ~ upperBar);
			#print("centerBar: " ~ centerBar);
			if ( dist_rad[0] != 900000 and dist_rad[0] > lowerBar and dist_rad[0] < upperBar and math.abs(dist_rad[1] * R2D) < 5 and math.abs(dist_rad[3] * R2D) < 5) { # if the target is between lowerbar and upperbar on the radar, and is no more than 5* off centerline in all directions (left, up, right, down)
				if ( math.abs(dist_rad[0] - centerBar) < c_dist ) {
					c_dist = dist_rad[0];
					c_most = track;
				}
			}
		}
		if ( c_most != nil ) {
			input.radarMode.setValue("locked-init");
			selection = c_most;
			paint(c_most.getNode(), TRUE);
			tracks_index = i;
			armament.contact = selection;
			#print(selection.get_callsign());
		}
	}
}

var ir_seekTarget= func() {
	if ( getprop(ir_sar_switch) == 0 ) {
		#print("checking for IR target");
		var c_dist = 999999;
		var c_most = nil;
		var i = -1;
		var ir_seek_limit = 10000; # ir seek can't see past 5km (for now)
		foreach(var track; tracks) {
			i += 1;
			var dist_rad = track.get_polar();
			#print("distance: " ~ dist_rad[0]);
			#print("x_ang: " ~ (dist_rad[1] * R2D));
			#print("y_ang: " ~ (dist_rad[2] * R2D));
			if ( dist_rad[0] != 900000 and dist_rad[0] < ir_seek_limit and math.abs(dist_rad[1] * R2D) < 5 and dist_rad[2] * R2D < 3 and dist_rad[2] > -7 * R2D) { # target distance < seek range, no more than 5* left/right, 3* up and 7* down
				if ( dist_rad[0] < c_dist ) {
					c_dist = dist_rad[0];
					c_most = track;
				}
			}
		}
		if ( c_most != nil and c_most != selection ) {
			#input.radarMode.setValue("locked-init");
			selection = c_most;
			paint(c_most.getNode(), TRUE);
			tracks_index = i;
			armament.contact = selection;
			#print("found target: " ~ selection.get_Callsign());
		} elsif ( c_most == nil ) {
			#print("unlocking 1");
			unlockTarget();
		}
		settimer( func { ir_seekTarget(); }, 0.1);
	}
}

var unlockTarget = func() {
	if ( selection != nil ) {
		#print("unlocking target");
		paint(selection.getNode(), FALSE);
		selection = nil;
		armament.contact = nil;
		if ( input.radarMode.getValue() == "locked" or input.radarMode.getValue() == "locked-init" ) {
			input.radarMode.setValue("normal-init");
		}
	}
}

setlistener( ir_sar_switch, func { ir_seekTarget_init(); } );
					
ir_seekTarget_init = func() {
	if ( getprop(ir_sar_switch) == 0 ) {
		ir_seekTarget();
	}
}

#targetting logic for the Viggen, saved for posterity.			
#var nextTarget = func () {
#  var max_index = size(tracks)-1;
#  if(max_index > -1) {
#    if(tracks_index < max_index) {
#      tracks_index += 1;
#    } else {
#      tracks_index = 0;
#    }
#    selection = tracks[tracks_index];
#    paint(selection.getNode(), TRUE);
#  } else {
#    tracks_index = -1;
#    if (selection != nil) {
#      paint(selection.getNode(), FALSE);
#    }
#  }
#}

#var centerTarget = func () {
#  var centerMost = nil;
#  var centerDist = 99999;
#  var centerIndex = -1;
#  var i = -1;
#  foreach(var track; tracks) {
#    i += 1;
#    if(track.get_cartesian()[0] != 900000) {
#      var dist = math.abs(track.get_cartesian()[0]) + math.abs(track.get_cartesian()[1]);
#      if(dist < centerDist) {
#        centerDist = dist;
#        centerMost = track;
#        centerIndex = i;
#      }
#    }
#  }
#  if (centerMost != nil) {
#    selection = centerMost;
#    paint(selection.getNode(), TRUE);
#    tracks_index = centerIndex;
#  }
#}

#loop
var loop = func () {
  findRadarTracks();
  settimer(loop, 0.05);
}

var getCallsign = func (callsign) {
  var node = callsign_struct[callsign];
  return node;
}

var lsnr = setlistener("/sim/signals/fdm-initialized", loop);



var Contact = {
    # For now only used in guided missiles, to make it compatible with Mirage 2000-5.
    new: func(c, class) {
        var obj             = { parents : [Contact]};
#debug.benchmark("radar process1", func {
        obj.rdrProp         = c.getNode("radar");
        obj.oriProp         = c.getNode("orientation");
        obj.velProp         = c.getNode("velocities");
        obj.posProp         = c.getNode("position");
        obj.heading         = obj.oriProp.getNode("true-heading-deg");
#});
#debug.benchmark("radar process2", func {
        obj.alt             = obj.posProp.getNode("altitude-ft");
        obj.lat             = obj.posProp.getNode("latitude-deg");
        obj.lon             = obj.posProp.getNode("longitude-deg");
#});
#debug.benchmark("radar process3", func {
        #As it is a geo.Coord object, we have to update lat/lon/alt ->and alt is in meters
        obj.coord = geo.Coord.new();
        obj.coord.set_latlon(obj.lat.getValue(), obj.lon.getValue(), obj.alt.getValue() * FT2M);
#});
#debug.benchmark("radar process4", func {
        obj.pitch           = obj.oriProp.getNode("pitch-deg");
        obj.roll            = obj.oriProp.getNode("roll-deg");
        obj.speed           = obj.velProp.getNode("true-airspeed-kt");
        obj.vSpeed          = obj.velProp.getNode("vertical-speed-fps");
        obj.callsign        = c.getNode("callsign", 1);
        obj.shorter         = c.getNode("model-shorter");
        obj.orig_callsign   = obj.callsign.getValue();
        obj.name            = c.getNode("name");
        obj.sign            = c.getNode("sign",1);
        obj.valid           = c.getNode("valid");
        obj.painted         = c.getNode("painted");
        obj.unique          = c.getNode("unique");
        obj.validTree       = 0;
#});
#debug.benchmark("radar process5", func {        
        #obj.transponderID   = c.getNode("instrumentation/transponder/transmitted-id");
#});
#debug.benchmark("radar process6", func {                
        obj.acType          = c.getNode("sim/model/ac-type");
        obj.type            = c.getName();
        obj.index           = c.getIndex();
        obj.string          = "ai/models/" ~ obj.type ~ "[" ~ obj.index ~ "]";
        obj.shortString     = obj.type ~ "[" ~ obj.index ~ "]";
#});
#debug.benchmark("radar process7", func {
        obj.range           = obj.rdrProp.getNode("range-nm");
        obj.bearing         = obj.rdrProp.getNode("bearing-deg");
        obj.elevation       = obj.rdrProp.getNode("elevation-deg");
#});        
        obj.deviation       = nil;

        obj.node            = c;
        obj.class           = class;

        obj.polar           = [0,0,0];
        obj.cartesian       = [0,0];
        
        return obj;
    },

    isValid: func () {
      var valid = me.valid.getValue();
      if (valid == nil) {
        valid = FALSE;
      }
      if (me.callsign.getValue() != me.orig_callsign) {
        valid = FALSE;
      }
      return valid;
    },

    isPainted: func () {
      if (me.painted == nil) {
        me.painted = me.node.getNode("painted");
      }
      if (me.painted == nil) {
        return nil;
      }
      var p = me.painted.getValue();
      return p;
    },

    getUnique: func () {
      if (me.unique == nil) {
        me.unique = me.node.getNode("unique");
      }
      if (me.unique == nil) {
        return nil;
      }
      var u = me.unique.getValue();
      return u;
    },

    getElevation: func() {
        var e = 0;
        e = me.elevation.getValue();
        if(e == nil or e == 0) {
            # AI/MP has no radar properties
            var self = geo.aircraft_position();
            me.get_Coord();
            var angleInv = ja37.clamp(self.distance_to(me.coord)/self.direct_distance_to(me.coord), -1, 1);
            e = (self.alt()>me.coord.alt()?-1:1)*math.acos(angleInv)*R2D;
        }
        return e;
    },

    getNode: func () {
      return me.node;
    },

    getFlareNode: func () {
      return me.node.getNode("rotors/main/blade[3]/flap-deg");
    },

    getChaffNode: func () {
      return me.node.getNode("rotors/main/blade[3]/position-deg");
    },

    setPolar: func(dist, angle, angle2 = 0, angle_normalized = 0) {
      me.polar = [dist,angle,angle2,angle_normalized];
    },

    setCartesian: func(x, y) {
      me.cartesian = [x,y];
    },

    remove: func(){
        if(me.validTree != 0){
          me.validTree.setBoolValue(0);
        }
    },

    get_Coord: func(){
        me.coord.set_latlon(me.lat.getValue(), me.lon.getValue(), me.alt.getValue() * FT2M);
        var TgTCoord  = geo.Coord.new(me.coord);
        return TgTCoord;
    },

    get_Callsign: func(){
        var n = me.callsign.getValue();
        if(n != "" and n != nil) {
            return n;
        }
        if (me.name == nil) {
          me.name = me.getNode().getNode("name");
        }
        if (me.name == nil) {
          n = "";
        } else {
          n = me.name.getValue();
        }
        if(n != "" and n != nil) {
            return n;
        }
        n = me.sign.getValue();
        if(n != "" and n != nil) {
            return n;
        }
        return "UFO";
    },

    get_model: func(){
        var n = "";
        if (me.shorter == nil) {
          me.shorter = me.node.getNode("model-shorter");
        }
        if (me.shorter != nil) {
          n = me.shorter.getValue();
        }
        if(n != "" and n != nil) {
            return n;
        }
        n = me.sign.getValue();
        if(n != "" and n != nil) {
            return n;
        }
        if (me.name == nil) {
          me.name = me.getNode().getNode("name");
        }
        if (me.name == nil) {
          n = "";
        } else {
          n = me.name.getValue();
        }
        if(n != "" and n != nil) {
            return n;
        }
        return me.get_Callsign();
    },

    get_Speed: func(){
        # return true airspeed
        var n = me.speed.getValue();
        return n;
    },

    get_Longitude: func(){
        var n = me.lon.getValue();
        return n;
    },

    get_Latitude: func(){
        var n = me.lat.getValue();
        return n;
    },

    get_Pitch: func(){
        var n = me.pitch.getValue();
        return n;
    },

    get_Roll: func(){
        var n = me.roll.getValue();
        return n;
    },

    get_heading : func(){
        var n = me.heading.getValue();
        if(n == nil)
        {
            n = 0;
        }
        return n;
    },

    get_bearing: func(){
        var n = 0;
        n = me.bearing.getValue();
        if(n == nil or n == 0) {
            # AI/MP has no radar properties
            n = me.get_bearing_from_Coord(geo.aircraft_position());
        }
        return n;
    },

    get_bearing_from_Coord: func(MyAircraftCoord){
        me.get_Coord();
        var myBearing = 0;
        if(me.coord.is_defined()) {
            myBearing = MyAircraftCoord.course_to(me.coord);
        }
        return myBearing;
    },

    get_reciprocal_bearing: func(){
        return geo.normdeg(me.get_bearing() + 180);
    },

    get_deviation: func(true_heading_ref, coord){
        me.deviation =  - deviation_normdeg(true_heading_ref, me.get_bearing_from_Coord(coord));
        return me.deviation;
    },

    get_altitude: func(){
        #Return Alt in feet
        return me.alt.getValue();
    },

    get_Elevation_from_Coord: func(MyAircraftCoord) {
        me.get_Coord();
        var value = (me.coord.alt() - MyAircraftCoord.alt()) / me.coord.direct_distance_to(MyAircraftCoord);
        if (math.abs(value) > 1) {
          # warning this else will fail if logged in as observer and see aircraft on other side of globe
          return 0;
        }
        var myPitch = math.asin(value) * R2D;
        return myPitch;
    },

    get_total_elevation_from_Coord: func(own_pitch, MyAircraftCoord){
        var myTotalElevation =  - deviation_normdeg(own_pitch, me.get_Elevation_from_Coord(MyAircraftCoord));
        return myTotalElevation;
    },
    
    get_total_elevation: func(own_pitch) {
        me.deviation =  - deviation_normdeg(own_pitch, me.getElevation());
        return me.deviation;
    },

    get_range: func() {
        var r = 0;
        if(me.range == nil or me.range.getValue() == nil or me.range.getValue() == 0) {
            # AI/MP has no radar properties
            me.get_Coord();
            r = me.coord.direct_distance_to(geo.aircraft_position()) * M2NM;
        } else {
          r = me.range.getValue();
        }
        return r;
    },

    get_range_from_Coord: func(MyAircraftCoord) {
        var myCoord = me.get_Coord();
        var myDistance = 0;
        if(myCoord.is_defined()) {
            myDistance = MyAircraftCoord.direct_distance_to(myCoord) * M2NM;
        }
        return myDistance;
    },

    get_type: func () {
      return me.class;
    },

    get_cartesian: func() {
      return me.cartesian;
    },

    get_polar: func() {
      return me.polar;
    },
};