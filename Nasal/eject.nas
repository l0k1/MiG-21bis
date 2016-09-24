init_eject = func {
 
   props.globals.getNode("sim/model/ejection/start", 1).setBoolValue(0);
   props.globals.getNode("sim/model/ejection/launch",1).setBoolValue(0);
   props.globals.getNode("sim/model/ejection/seperation", 1).setBoolValue(0);
   props.globals.getNode("controls/eject", 1).setBoolValue(0);
 
};
 
 
eject = func {
 
   # at T= 0.0
   setprop("sim/model/ejection/start", 1);
   setprop("sim/model/ejection/launch", 0);
   setprop("sim/model/ejection/seperation", 0);
 
   settimer(launch, 0.3);
   settimer(seperate, 2.2);
};
 
 
 
launch = func {
  setprop("sim/model/ejection/launch", 1);
  setprop("sim/model/ejection/seperation", 0);
  setprop("controls/eject", 1);
};
 
seperate = func {
  setprop("sim/model/ejection/launch", 0);
  setprop("sim/model/ejection/seperation", 1);
};
 
 
init_eject();