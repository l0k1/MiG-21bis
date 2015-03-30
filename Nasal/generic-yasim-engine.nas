# generic-yasim-engine.nas -- a generic Nasal-based engine control system for YASim
# Version 1.0.0
#
# Copyright (C) 2011  Ryan Miller
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#


var UPDATE_PERIOD = 0.01; # update interval for engine init() functions

# jet engine class
var Jet =
{
	# creates a new engine object
	new: func(n, running = 0, idle_throttle = 0.01, max_start_n1 = 5.21, start_threshold = 5, spool_time = 4, start_time = 5, shutdown_time = 4)
	{
		# copy the Jet object
		var m = { parents: [Jet] };
		# declare object variables
		m.number = n;
		m.autostart_status = 0;
		m.autostart_id = -1;
		m.loop_running = 0;
		m.started = 0;
		m.starting = 0;
		m.idle_throttle = idle_throttle;
		m.max_start_n1 = max_start_n1;
		m.start_threshold = start_threshold;
		m.spool_time = spool_time;
		m.start_time = start_time;
		m.shutdown_time = shutdown_time;
		# create references to properties and set default values
		m.cutoff = props.globals.getNode("controls/engines/engine[" ~ n ~ "]/cutoff", 1);
		m.cutoff.setBoolValue(!running);
		m.n1 = props.globals.getNode("engines/engine[" ~ n ~ "]/n1", 1);
		m.n1.setDoubleValue(0);
		m.out_of_fuel = props.globals.getNode("engines/engine[" ~ n ~ "]/out-of-fuel", 1);
		m.out_of_fuel.setBoolValue(0);
		m.reverser = props.globals.getNode("controls/engines/engine[" ~ n ~ "]/reverser", 1);
		m.reverser.setBoolValue(0);
		m.rpm = props.globals.getNode("engines/engine[" ~ n ~ "]/rpm", 1);
		m.rpm.setDoubleValue(running ? 100 : 0);
		m.running = props.globals.getNode("engines/engine[" ~ n ~ "]/running", 1);
		m.running.setBoolValue(running);
		m.serviceable = props.globals.getNode("engines/engine[" ~ n ~ "]/serviceable", 1);
		m.serviceable.setBoolValue(1);
		m.starter = props.globals.getNode("controls/engines/engine[" ~ n ~ "]/starter", 1);
		m.starter.setBoolValue(0);
		m.throttle = props.globals.getNode("controls/engines/engine[" ~ n ~ "]/throttle", 1);
		m.throttle.setDoubleValue(0);
		m.throttle_lever = props.globals.getNode("controls/engines/engine[" ~ n ~ "]/throttle-lever", 1);
		m.throttle_lever.setDoubleValue(0);
		# return our new object
		return m;
	},
	# engine-specific autostart
	autostart: func
	{
		if (me.autostart_status)
		{
			me.autostart_status = 0;
			me.cutoff.setBoolValue(1);
		}
		else
		{
			me.autostart_status = 1;
			me.starter.setBoolValue(1);
			settimer(func
			{
				me.cutoff.setBoolValue(0);
			}, me.max_start_n1 / me.start_time);
		}
	},
	# creates an engine update loop (optional)
	init: func
	{
		if (me.loop_running) return;
		me.loop_running = 1;
		var loop = func
		{
			me.update();
			settimer(loop, UPDATE_PERIOD);
		};
		settimer(loop, 0);
	},
	# updates the engine
	update: func
	{
		if (me.running.getBoolValue() and !me.started)
		{
			me.running.setBoolValue(0);
		}
		if (me.cutoff.getBoolValue() or !me.serviceable.getBoolValue() or me.out_of_fuel.getBoolValue())
		{
			var rpm = me.rpm.getValue();
			var time_delta = getprop("sim/time/delta-realtime-sec");
			if (me.starter.getBoolValue())
			{
				rpm += time_delta * me.spool_time;
				me.rpm.setValue(rpm >= me.max_start_n1 ? me.max_start_n1 : rpm);
			}
			else
			{
				rpm -= time_delta * me.shutdown_time;
				me.rpm.setValue(rpm <= 0 ? 0 : rpm);
				me.running.setBoolValue(0);
                                me.throttle.setDoubleValue(0);
				me.throttle_lever.setDoubleValue(0);
				me.started = 0;
			}
		}
		elsif (me.starter.getBoolValue())
		{
			var rpm = me.rpm.getValue();
			if (rpm >= me.start_threshold)
			{
				var time_delta = getprop("sim/time/delta-realtime-sec");
				rpm += time_delta * me.spool_time;
				me.rpm.setValue(rpm);
				if (rpm >= me.n1.getValue())
				{
					me.running.setBoolValue(1);
					me.starter.setBoolValue(0);
					me.started = 1;
				}
				else
				{
					me.running.setBoolValue(0);
				}
			}
		}
		elsif (me.running.getBoolValue())
		{
			me.throttle_lever.setValue(me.idle_throttle + (1 - me.idle_throttle) * me.throttle.getValue());
			me.rpm.setValue(me.n1.getValue());
		}
	}
};

# turboprop engine class
var turboprop_condition_cutoff = 0.001; # minimum condition value for YASim turboprops to start
var Turboprop =
{
	new: func(n, running = 0, min_condition = 0.2)
	{
		# copy the Turboprop object
		var m = { parents: [Turboprop] };
		# declare object variables
		m.number = n;
		m.autostart_status = 0;
		m.loop_running = 0;
		m.min_condition = min_condition;
		# create references to properties and set default values
		m.condition = props.globals.getNode("controls/engines/engine[" ~ n ~ "]/condition", 1);
		m.condition.setDoubleValue(0);
		m.condition_lever = props.globals.getNode("controls/engines/engine[" ~ n ~ "]/condition-lever", 1);
		m.condition_lever.setDoubleValue(running ? min_condition : 0);
		m.cutoff = props.globals.getNode("controls/engines/engine[" ~ n ~ "]/cutoff", 1);
		m.cutoff.setBoolValue(!running);
		m.n1 = props.globals.getNode("engines/engine[" ~ n ~ "]/n1", 1);
		m.n1.setDoubleValue(running ? 100 : 0);
		m.n2 = props.globals.getNode("engines/engine[" ~ n ~ "]/n2", 1);
		m.n2.setDoubleValue(0);
		m.out_of_fuel = props.globals.getNode("engines/engine[" ~ n ~ "]/out-of-fuel", 1);
		m.out_of_fuel.setBoolValue(0);
		m.propeller_feather = props.globals.getNode("controls/engines/engine[" ~ n ~ "]/propeller-feather", 1);
		m.propeller_feather.setBoolValue(0);
		m.starter = props.globals.getNode("controls/engines/engine[" ~ n ~ "]/starter", 1);
		m.starter.setBoolValue(0);
		# return our new object
		return m;
	},
	# engine-specific autostart
	autostart: func
	{
		if (me.autostart_status)
		{
			me.autostart_status = 0;
			me.cutoff.setBoolValue(1);
			me.condition.setValue(0);
		}
		else
		{
			me.autostart_status = 1;
			me.cutoff.setBoolValue(0);
			me.starter.setBoolValue(1);
			me.condition.setValue(me.min_condition);
		}
	},
	# creates an engine update loop (optional)
	init: func
	{
		if (me.loop_running) return;
		me.loop_running = 1;
		var loop = func
		{
			me.update();
			settimer(loop, UPDATE_PERIOD);
		};
		settimer(loop, 0);
	},
	# updates the engine
	update: func
	{        
		if (me.cutoff.getBoolValue())
		{
			me.out_of_fuel.setBoolValue(1);
		}
		if (me.starter.getBoolValue() and me.condition_lever.getValue() < turboprop_condition_cutoff and me.condition.getValue() >= me.min_condition)
		{
			me.condition_lever.setValue(me._get_condition_value(me.condition.getValue()));
		}
		elsif (me.condition_lever.getValue() < turboprop_condition_cutoff and me.n2.getValue() < 0.5)
		{
			if (me.propeller_feather.getBoolValue())
			{
				me.n1.setValue(0);
			}
			me.condition_lever.setValue(0);
		}
		if (me.n2.getValue() >= 0.5)
		{
			if (me.condition_lever.getValue() >= turboprop_condition_cutoff)
			{
				me.condition_lever.setValue(me._get_condition_value(me.condition.getValue()));
			}
			else
			{
				me.condition_lever.setValue(0);
			}
			me.n1.setValue(me.n2.getValue());
		}
	},
	_get_condition_value: func(v)
	{
		if (v >= me.min_condition)
		{
			return turboprop_condition_cutoff + (v - me.min_condition) / (1 - me.min_condition) * (1 - turboprop_condition_cutoff);
		}
		return v / me.min_condition * turboprop_condition_cutoff;
	}
};
