# for a list of all contacts, use the vector mpdb.cx_master_list

# goals:
# filter out radar contacts based on:
# closure speed / doppler notching
# terrain masking, ala flying close to the ground
# terrain blocking, ala flying behind a mountain
# rcs
# weather - clouds, rain, snow, hail
#
# also use a moving antenna instead of looking at all contacts at the same time.
# instead of setting contacts on the radar canvas, instead update variables in the contacts object
# that the canvas will look through.

var FALSE = 0;
var TRUE = 1;

var kts2kmh = 1.852;
var round0 = func(x) { return math.abs(x) > 0.01 ? x : 0; };


# Radar Parameters
var radarRange = 60000;
var radarPowerRange = 30000;
var radarPowerRCS = 4;

# NOTE: you can change these later to scan a smaller window, but the initial settings should be the max limits to
# properly calculate antenna movement and limit stuffs
var radar_bottom_limit = -30;
var radar_top_limit = 30;
var radar_left_limit = -30;
var radar_right_limit = 30;

var radar_gimbal_limit_hori = 70; # if the antenna can't move completely with the plane as the plane rolls/pitches to keep a steady horizon.
var radar_gimbal_limit_vert = 70;

var full_scan_time = 0.17; # time in seconds the radar takes to go from full left to full right (assume up/down takes same amount of time)

var beam_width = 10;
var beam_height = 10;

# scan patterns are percentages of the limit values placed above.
# it is up to the person coding it to make sure there are no blind spots.
# the radar antenna will move ~80% of the above beam variables until it hits the end.
# multiple scan patterns are allowed, although the mig-21 only uses one.
var radar_scan_patterns = [
                            [-1,0],[1,0],[1,-1],[-1,-1],[-1,1],[1,1],[1,0],[-1,0],[-1,-1],[1,-1],[1,1],[-1,1]
                          ];

# change the scan pattern by calling RadarLogic.changeScanPattern();
var default_scan_pattern = 0;

##### NON USER SETTINGS
# calculate the movement rate of the antenna
var beam_width_norm = (radar_right_limit - radar_left_limit) / beam_width;
var beam_height_norm = (radar_top_limit - radar_bottom_limit) / beam_height;
var movement_rate = full_scan_time / beam_width_norm; # how many seconds per scan


var RadarLogic = {

    new: func() {
        var radarLogic     = { parents : [RadarLogic]};
        radarLogic.typeHashes = {};
        radarLogic.bottom_limit = radar_bottom_limit + (beam_height / 2);
        radarLogic.top_limit = radar_top_limit - (beam_height / 2);
        radarLogic.left_limit = radar_left_limit + (beam_width / 2);
        radarLogic.right_limit = radar_right_limit - (beam_width / 2);
        radarLogic._denormalizeScanPatterns();
        radarLogic.scan_pattern = radarLogic.scan_patterns[default_scan_pattern];
        radarLogic.scan_index = 0;
        radarLogic.scan_location = radarLogic.scan_pattern[0];
        radarLogic.iterator = 0;
        radarLogic.contact_list = [];
        return radarLogic;
    },

    loop: func () {
    # only update target positions every 10 loops.
    if (me.iterator == 0) {
      me.updateTargetLocations();
    }
    me.iterator = me.iterator < 10 ? me.iterator + 1 : 0;
    
    me.setAntennaPos();
    me.processContacts();
    settimer(func{me.loop();}, 0.15);
  },

  processContacts: func() {
  
  },
  
  processScan: func() {
    foreach ( var c; me.contact_list ) {
      
    }  
  },
  
  setAntennaPos: func() {
    # move the antenna to the next pos
    
    # move the antenna in the x/y dir by the normalized beam amount
    # and make sure it doesnt move past the next point.
    if (me.x_dir != 0 ) {
      me.scan_location[0] += (beam_width_norm * me.x_dir);
      if ( me.scan_location[0] * x_dir > me.scan_location_next[0] * x_dir ) {
        me.scan_location[0] = me.scan_location_next[0];
      }
    }
    if (me.y_dir != 0 ) {
      me.scan_location[1] += (beam_height_norm * me.y_dir);
      if ( me.scan_location[1] * y_dir > me.scan_location_next[1] * y_dir ) {
        me.scan_location[1] = me.scan_location_next[1];
      }
    }
    
    if ( me.scan_location[0] == me.scan_location_next[0] and me.scan_location[1] == me.scan_location_next[1] ) {
      me.processNextAntennaPoint();
    }
    
    # get the current yaw/pitch of the antenna
    me.roll = getprop("orientation/roll-deg");
    me.pitch = getprop("orientation/pitch-deg");
    me.antenna_yaw = me.scan_location[0];
    me.antenna_pitch = me.scan_location[1];
    
    
    # adjust the yaw and pitch of the antenna by the roll and pitch of the aircraft, adjusting for antenna gimbal limits
    if ( math.abs(me.roll) > radar_gimbal_limit_hori ) {
      me.roll_rad = me.roll * D2R
      me.antenna_yaw = me.scan_location[0] * math.cos(me.roll_rad) + me.scan_location[1] * math.sin(me.roll_rad); # x * cos(deg) + y * sin(deg)
      me.antenna_pitch = -me.scan_location[0] * math.sin(me.roll_rad) + me.scan_location[1] * math.cos(me.roll_rad); # -x * sin(deg) + y * cos(deg)
    }
    # denormalize antenna pos
    me.antenna_yaw = me.antenna_yaw > 0 ? me.antenna_yaw * radar_right_limit : me.antenna_yaw * radar_left_limit;
    me.antenna_pitch = me.antenna_pitch > 0 ? me.antenna_pitch * radar_top_limit : me.antenna_pitch * radar_bottom_limit;
    
    # adjust pitch if over gimbal limit
    if ( math.abs(me.pitch) > radar_gimbal_limit_vert ) {
      me.antenna_pitch = me.antenna_pitch + (me.pitch - (radar_gimbal_limit_vert * math.sgn(me.pitch)));
    }
    
  },
  
  changeScanPattern: func(v) {
    if (v >= size(radar_scan_patterns)) {
      # pattern doesnt exist, do nothing
      print("Attempted to set radar to non-existent scan pattern: " ~ v);
    } else {
      me.scan_pattern = radar_scan_patterns[v];
      me.scan_index = 0;
      me.scan_index_next = 0;
      me.scan_location = me.scan_pattern[0];
      me.processNextAntennaPoint();
    }
  },
  
  processNextAntennaPoint: func() {
    # run after the antenna has reached a waypoint
    # this will process the waypoints and create directionality for the antenna to move
    
    # update index
    
    if ( len(me.scan_pattern) == 1 ) {
      me.x_dir = 0;
      me.y_dir = 0;
      return;
    }
    
    me.scan_index = me.scan_index_next;
    if ( me.scan_index + 1 > len(me.scan_pattern) - 1 ) {
      me.scan_index_next = 0;
    } else {
      me.scan_index_next = me.scan_index + 1;
    }
    me.scan_location_next = me.scan_pattern[me.scan_index_next];
    
    # create x/y directional vectors
    
    if ( me.scan_location[0] > me.scan_pattern[me.scan_index_next][0] ) {
      me.x_dir = -1;
    } elsif ( me.scan_location[0] < me.scan_pattern[me.scan_index_next][0] ) {
      me.x_dir = 1;
    } else {
      me.x_dir = 0;
    }
    
    if ( me.scan_location[1] > me.scan_pattern[me.scan_index_next][1] ) {
      me.y_dir = -1;
    } elsif ( me.scan_location[1] < me.scan_pattern[me.scan_index_next][1] ) {
      me.y_dir = 1;
    } else {
      me.y_dir = 0;
    }
    
  },
  

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

var knownShips = {
    "missile_frigate":       nil,
    "frigate":       nil,
    "USS-LakeChamplain":     nil,
    "USS-NORMANDY":     nil,
    "USS-OliverPerry":     nil,
    "USS-SanAntonio":     nil,
};



var input = {
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
};

var RadarLogic = {

    new: func() {
        var radarLogic     = { parents : [RadarLogic]};
        radarLogic.typeHashes = {};
        return radarLogic;
    },

    loop: func () {
      me.findRadarTracks();
      settimer(func{me.loop();}, 0.15);
    },

    findRadarTracks: func () {
      self      =  geo.aircraft_position();
      myPitch   =  input.pitch.getValue()*D2R;
      myRoll    =  input.roll.getValue()*D2R;
      myAlt     =  self.alt();
      myHeading =  input.hdgReal.getValue();
      
      tracks = [];

    
      if(input.radar_serv.getValue() > FALSE) {

        me.players = [];
        foreach(item; multiplayer.model.list) {
          append(me.players, item.node);
        }
    
    
        me.AIplanes = input.ai_models.getChildren("aircraft");
        me.tankers = input.ai_models.getChildren("tanker");
        me.ships = input.ai_models.getChildren("ship");
        me.vehicles = input.ai_models.getChildren("groundvehicle");
        if(selection != nil and selection.isValid() == FALSE) {
          #print("not valid");
          me.paint(selection.getNode(), FALSE);
          selection = nil;
        }


        me.processTracks(me.players, FALSE, FALSE, TRUE);    
        me.processTracks(me.tankers, FALSE, FALSE, FALSE, AIR);
        me.processTracks(me.ships, FALSE, FALSE, FALSE, MARINE);
  #debug.benchmark("radar process AI tracks", func {    
        me.processTracks(me.AIplanes, FALSE, FALSE, FALSE, AIR);
  #});
        me.processTracks(me.vehicles, FALSE, FALSE, FALSE, SURFACE);
        me.processCallsigns(me.players);

      } else {
    # Do not supply target info to the missiles if radar is off.
        if(selection != nil) {
          me.paint(selection.getNode(), FALSE);
        }
        selection = nil;
      }
      if(selection != nil) {
        #append(selection, "lock");
      }
  },

  processCallsigns: func (players) {
    callsign_struct = {};
    foreach (var player; players) {
      if(player.getChild("valid") != nil and player.getChild("valid").getValue() == TRUE and player.getChild("callsign") != nil and player.getChild("callsign").getValue() != "" and player.getChild("callsign").getValue() != nil) {
        me.callsign = player.getChild("callsign").getValue();
        callsign_struct[me.callsign] = player;
      }
    }
  },

  processTracks: func (vector, carrier, missile = 0, mp = 0, type = -1) {
    #me.carrierNear = FALSE;
    me.damagemod = getprop("/fdm/jsbsim/radar/antenna-damage");
    me.damagemod = me.damagemod == nil ? 0 : 1 - me.damagemod;
    foreach (var track; vector) {
      if(track != nil and track.getChild("valid") != nil and track.getChild("valid").getValue() == TRUE) { #only the tracks that are valid are sent here
        me.trackInfo = nil;
  #debug.benchmark("radar trackitemcalc", func {
        me.trackInfo = me.trackItemCalc(track, radarRange * me.damagemod, carrier, mp, type);
  #});
  #debug.benchmark("radar process", func {
        if(me.trackInfo != nil) {
          me.distance = me.trackInfo.get_range()*NM2M;

          # find and remember the type of the track
          me.typeNode = track.getChild("model-shorter");
          me.model = nil;
          if (me.typeNode != nil) {
            me.model = me.typeNode.getValue();
          } else {
            me.pathNode = track.getNode("sim/model/path");
            if (me.pathNode != nil) {
              me.path = me.pathNode.getValue();

              me.model = split(".", split("/", me.path)[-1])[0];

              me.model = me.remove_suffix(me.model, "-model");
              me.model = me.remove_suffix(me.model, "-anim");
              track.addChild("model-shorter").setValue(me.model);

              var funcHash = {
                new: func (trackN, pNode) {
                  me.listenerID1 = setlistener(trackN.getChild("valid"), func me.callme1(), nil, 1);
                  me.listenerID2 = setlistener(pNode,                    func me.callme2(), nil, 1);
                },
                callme1: func () {
                  if(me.trackme.getChild("valid").getValue() == FALSE) {
                    var child = me.trackme.removeChild("model-shorter",0);#index 0 must be specified!
                    if (child != nil) {#for some reason this can be called two times, even if listener removed, therefore this check.
                      me.del();
                    }
                  }
                },
                callme2: func () {
                  if(me.trackme.getNode("sim/model/path") == nil or funcHash.trackme.getNode("sim/model/path").getValue() != me.oldpath) {
                    var child = me.trackme.removeChild("model-shorter",0);
                    if (child != nil) {#for some reason this can be called two times, even if listener removed, therefore this check.
                      me.del();
                    }
                  }
                },
                del: func () {
                  removelistener(me.listenerID1);
                  removelistener(me.listenerID2);
                  radar_logic.radarLogic.typeHashes[me.trackme.getPath()] = nil;
                },
              };
              
              funcHash.trackme = track;
              funcHash.oldpath = me.path;

              me.typeHashes[track.getPath()] = funcHash;

              funcHash.new(track, me.pathNode);
            }
          }

          me.unique = track.getChild("unique");
          if (me.unique == nil) {
            me.unique = track.addChild("unique");
            me.unique.setDoubleValue(rand());
          }

          append(tracks, me.trackInfo);

          if(1==0 and selection == nil) {
            #this is first tracks in radar field, so will be default selection
            selection = me.trackInfo;
            lookatSelection();
            selection_updated = TRUE;
            me.paint(selection.getNode(), TRUE);
          } elsif (selection != nil and selection.getUnique() == me.unique.getValue()) {
            # this track is already selected, updating it
            #print("updating target");
            selection = me.trackInfo;
            setprop("instrumentation/gunsight/distance-to-lock",selection.get_range());
            selection_updated = TRUE;
          } else {
            #print("end2 "~selection.getUnique()~"=="~unique.getValue());
            me.paint(me.trackInfo.getNode(), FALSE);
          }
        } else {
          #print("end");
          me.paint(track, FALSE);
        }
      }
    }
  #});
  },#end of processTracks

  paint: func (node, painted) {
    if (node == nil) {
      return;
    }
    me.attr = node.getChild("painted");
    if (me.attr == nil) {
      me.attr = node.addChild("painted");
    }
    me.attr.setBoolValue(painted);
    #if(painted == TRUE) { 
      #print("painted "~attr.getPath()~" "~painted);
    #}
  },

  remove_suffix: func(s, x) {
      me.len = size(x);
      if (substr(s, -me.len) == x)
          return substr(s, 0, size(s) - me.len);
      return s;
  },

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

  trackItemCalc: func (track, range, carrier, mp, type) {
    me.pos = track.getNode("position");
    me.x = me.pos.getNode("global-x").getValue();
    me.y = me.pos.getNode("global-y").getValue();
    me.z = me.pos.getNode("global-z").getValue();
    if(me.x == nil or me.y == nil or me.z == nil) {
      return nil;
    }
    me.aircraftPos = geo.Coord.new().set_xyz(me.x, me.y, me.z);
    me.item = me.trackCalc(me.aircraftPos, range, carrier, mp, type, track);
    
    return me.item;
  },

  trackCalc: func (aircraftPos, range, carrier, mp, type, node) {
    me.distance = nil;
    me.distanceDirect = nil;

    #print("Checking for: " ~ node.getChild("callsign").getValue());
    
    call(func {me.distance = self.distance_to(aircraftPos); me.distanceDirect = self.direct_distance_to(aircraftPos);}, nil, var err = []);

    if ((size(err))or(me.distance==nil)) {
      # Oops, have errors. Bogus position data (and distance==nil).
      #print("Received invalid position data: dist "~distance);
      #target_circle[track_index+maxTargetsMP].hide();
      #print(i~" invalid pos.");
      print("returned some sort of invalid pos error");
      return nil;
    }

    if (mp == TRUE or getprop("/mig21/advanced-radar") == TRUE) {
      # is multiplayer or 2017.2.1+
      if (me.isNotBehindTerrain(aircraftPos) == FALSE) {
        #hidden behind terrain
        #print("behind terrain: TRUE");
        return nil;
      }
    }
    #print("behind terrain: FALSE");

    #print("me.distanceDirect: " ~ me.distanceDirect);
    #print("range: " ~ range);

    if (me.distanceDirect < range) {
      # Node with valid position data (and "distance!=nil").
      #distance = distance*kts2kmh*1000;
      me.aircraftAlt = aircraftPos.alt(); #altitude in meters

      #aircraftAlt = aircraftPos.x();
      #myAlt = self.x();
      #distance = math.sqrt(pow2(aircraftPos.z() - self.z()) + pow2(aircraftPos.y() - self.y()));

      #ground angle
      me.yg_rad = vector.Math.getPitch(self, aircraftPos)*D2R-myPitch;#math.atan2(aircraftAlt-myAlt, distance) - myPitch; 
      me.xg_rad = (self.course_to(aircraftPos) - myHeading) * D2R;

      while (me.xg_rad > math.pi) {
        me.xg_rad = me.xg_rad - 2*math.pi;
      }
      while (me.xg_rad < -math.pi) {
        me.xg_rad = me.xg_rad + 2*math.pi;
      }
      while (me.yg_rad > math.pi) {
        me.yg_rad = me.yg_rad - 2*math.pi;
      }
      while (me.yg_rad < -math.pi) {
        me.yg_rad = me.yg_rad + 2*math.pi;
      }

      #aircraft angle
      me.ya_rad = me.xg_rad * math.sin(myRoll) + me.yg_rad * math.cos(myRoll);
      me.xa_rad = me.xg_rad * math.cos(myRoll) - me.yg_rad * math.sin(myRoll);

      while (me.xa_rad < -math.pi) {
        me.xa_rad = me.xa_rad + 2*math.pi;
      }
      while (me.xa_rad > math.pi) {
        me.xa_rad = me.xa_rad - 2*math.pi;
      }
      while (me.ya_rad > math.pi) {
        me.ya_rad = me.ya_rad - 2*math.pi;
      }
      while (me.ya_rad < -math.pi) {
        me.ya_rad = me.ya_rad + 2*math.pi;
      }

      #print("ya_rad: " ~ me.ya_rad * R2D);
      #print("xa_rad: " ~ me.xa_rad * R2D);

      if(me.ya_rad > RADAR_BOTTOM_LIMIT * D2R and me.ya_rad < RADAR_TOP_LIMIT * D2R and me.xa_rad > RADAR_LEFT_LIMIT * D2R and me.xa_rad < RADAR_RIGHT_LIMIT * D2R) {
        #is within the radar cone
        
        if (mp == TRUE) {
          me.shrtr = node.getChild("model-shorter")==nil?"nil":node.getChild("model-shorter").getValue();
          if (me.doppler(aircraftPos, node) == TRUE) {
            # doppler picks it up, must be an aircraft
            type = AIR;
          } elsif (me.aircraftAlt > 1 and !contains(knownShips, me.shrtr)) {
            # doppler does not see it, and is not on sea, must be ground target
            type = SURFACE;
          } else {
            type = MARINE;
          }
        }

        me.contact = Contact.new(node, type);

        if (rcs.inRadarRange(me.contact, radarPowerRange * M2NM, radarPowerRCS) == TRUE) {
          #print("rcs: TRUE");
          return me.contact;
        } else {
          #print("rcs: FALSE");
          return nil;
        }        

      }
    }
    return nil;
  },

#
# The following 6 methods is partly from Mirage 2000-5
#
  isNotBehindTerrain: func(SelectCoord) {
    me.myOwnPos = geo.aircraft_position();
    if(me.myOwnPos.alt() > 8900 and SelectCoord.alt() > 8900) {
      # both higher than mt. everest, so not need to check.
      return TRUE;
    }
    me.xyz = {"x":me.myOwnPos.x(),                  "y":me.myOwnPos.y(),                 "z":me.myOwnPos.z()};
    me.dir = {"x":SelectCoord.x()-me.myOwnPos.x(),  "y":SelectCoord.y()-me.myOwnPos.y(), "z":SelectCoord.z()-me.myOwnPos.z()};

    # Check for terrain between own aircraft and other:
    me.v = get_cart_ground_intersection(me.xyz, me.dir);
    if (me.v == nil) {
      return TRUE;
      #printf("No terrain, planes has clear view of each other");
    } else {
     me.terrain = geo.Coord.new();
     me.terrain.set_latlon(me.v.lat, me.v.lon, me.v.elevation);
     me.maxDist = me.myOwnPos.direct_distance_to(SelectCoord);
     me.terrainDist = me.myOwnPos.direct_distance_to(me.terrain);
     if (me.terrainDist < me.maxDist) {
       #print("terrain found between the planes");
       return FALSE;
     } else {
        return TRUE;
        #print("The planes has clear view of each other");
     }
    }
  },

# will return true if absolute closure speed of target is greater than 50kt
#
  doppler: func(t_coord, t_node) {
    # Test to check if the target can hide below us
    # Or Hide using anti doppler movements

    if (input.dopplerOn.getValue() == FALSE or 
        (t_node.getNode("velocities/true-airspeed-kt") != nil and t_node.getNode("velocities/true-airspeed-kt").getValue() != nil
         and t_node.getNode("radar/range-nm") != nil and t_node.getNode("radar/range-nm").getValue() != nil
         and math.atan2(t_node.getNode("velocities/true-airspeed-kt").getValue(), t_node.getNode("radar/range-nm").getValue()*1000) > 0.025)# if aircraft traverse speed seen from me is high
        ) {
      return TRUE;
    }

    me.DopplerSpeedLimit = input.dopplerSpeed.getValue();
    me.InDoppler = 0;
    me.groundNotbehind = me.isGroundNotBehind(t_coord, t_node);

    if(me.groundNotbehind)
    {
        me.InDoppler = 1;
    } elsif(abs(me.get_closure_rate_from_Coord(t_coord, t_node)) > me.DopplerSpeedLimit)
    {
        me.InDoppler = 1;
    }
    return me.InDoppler;
  },

  isGroundNotBehind: func(t_coord, t_node){
    me.myPitch = me.get_Elevation_from_Coord(t_coord);
    me.GroundNotBehind = 1; # sky is behind the target (this don't work on a valley)
    if(me.myPitch < 0)
    {
        # the aircraft is below us, the ground could be below
        # Based on earth curve. Do not work with mountains
        # The script will calculate what is the ground distance for the line (us-target) to reach the ground,
        # If the earth was flat. Then the script will compare this distance to the horizon distance
        # If our distance is greater than horizon, then sky behind
        # If not, we cannot see the target unless we have a doppler radar
        me.distHorizon = geo.aircraft_position().alt() / math.tan(abs(me.myPitch * D2R)) * M2NM;
        me.horizon = me.get_horizon( geo.aircraft_position().alt() *M2FT, t_node);
        me.TempBool = (me.distHorizon > me.horizon);
        me.GroundNotBehind = (me.distHorizon > me.horizon);
    }
    return me.GroundNotBehind;
  },

  get_Elevation_from_Coord: func(t_coord) {
    # fix later: Nasal runtime error: floating point error in math.asin() when logged in as observer:
    #var myPitch = math.asin((t_coord.alt() - geo.aircraft_position().alt()) / t_coord.direct_distance_to(geo.aircraft_position())) * R2D;
    return vector.Math.getPitch(geo.aircraft_position(), t_coord);
  },

  get_horizon: func(own_alt, t_node){
      me.tgt_alt = t_node.getNode("position/altitude-ft").getValue();
      if(debug.isnan(me.tgt_alt))
      {
          return(0);
      }
      if(me.tgt_alt < 0 or me.tgt_alt == nil)
      {
          me.tgt_alt = 0;
      }
      if(own_alt < 0 or own_alt == nil)
      {
          own_alt = 0;
      }
      # Return the Horizon in NM
      return (2.2 * ( math.sqrt(own_alt * FT2M) + math.sqrt(me.tgt_alt * FT2M)));# don't understand the 2.2 conversion to NM here..
  },

  get_closure_rate_from_Coord: func(t_coord, t_node) {
      me.MyAircraftCoord = geo.aircraft_position();

      if(t_node.getNode("orientation/true-heading-deg") == nil) {
        return 0;
      }

      # First step : find the target heading.
      me.myHeading = t_node.getNode("orientation/true-heading-deg").getValue();
      
      # Second What would be the aircraft heading to go to us
      me.myCoord2 = t_coord;
      me.projectionHeading = me.myCoord2.course_to(me.MyAircraftCoord);
      
      if (me.myHeading == nil or me.projectionHeading == nil) {
        return 0;
      }

      # Calculate the angle difference
      me.myAngle = me.myHeading - me.projectionHeading; #Should work even with negative values
      
      # take the "ground speed"
      # velocities/true-air-speed-kt
      me.mySpeed = t_node.getNode("velocities/true-airspeed-kt").getValue();
      me.myProjetedHorizontalSpeed = me.mySpeed*math.cos(me.myAngle*D2R); #in KTS
      
      #print("Projetted Horizontal Speed:"~ myProjetedHorizontalSpeed);
      
      # Now getting the pitch deviation
      me.myPitchToAircraft = - t_node.getNode("radar/elevation-deg").getValue();
      #print("My pitch to Aircraft:"~myPitchToAircraft);
      
      # Get V speed
      if(t_node.getNode("velocities/vertical-speed-fps").getValue() == nil)
      {
          return 0;
      }
      me.myVspeed = t_node.getNode("velocities/vertical-speed-fps").getValue()*FPS2KT;
      # This speed is absolutely vertical. So need to remove pi/2
      
      me.myProjetedVerticalSpeed = me.myVspeed * math.cos(me.myPitchToAircraft-90*D2R);
      
      # Control Print
      #print("myVspeed = " ~myVspeed);
      #print("Total Closure Rate:" ~ (myProjetedHorizontalSpeed+myProjetedVerticalSpeed));
      
      # Total Calculation
      me.cr = me.myProjetedHorizontalSpeed+me.myProjetedVerticalSpeed;
      
      # Setting Essential properties
      #var rng = me. get_range_from_Coord(MyAircraftCoord);
      #var newTime= ElapsedSec.getValue();
      #if(me.get_Validity())
      #{
      #    setprop(me.InstrString ~ "/" ~ me.shortstring ~ "/closure-last-range-nm", rng);
      #    setprop(me.InstrString ~ "/" ~ me.shortstring ~ "/closure-rate-kts", cr);
      #}
      
      return me.cr;
  },

};

var getCallsign = func (callsign) {
  var node = callsign_struct[callsign];
  return node;
};

var deviation_normdeg = func(our_heading, target_bearing) {
  var dev_norm = geo.normdeg180(our_heading - target_bearing);
  return dev_norm;
}

setlistener('/controls/radar/power-panel/run',func() {
  var status = getprop('/controls/radar/power-panel/run');
  setprop('/sim/multiplay/generic/int[2]', (status - 1) * -1);
});

var radarLogic = nil;
radarLogic = RadarLogic.new();
radarLogic.loop();
#var starter = func () {
#  removelistener(lsnr);
#  if(getprop("ja37/supported/radar") == TRUE) {
#    radarLogic = RadarLogic.new();
#    #radarLogic.loop();
#  }
#};