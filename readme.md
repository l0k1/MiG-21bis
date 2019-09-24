# MiG-21bis 

by: Petar Jedvaj, David Culp, Raptor, Stuart Cassie, Gary Brown, Brendan Black, bugman, and Tomaskom.

Currently maintained by Justin Nicholson, a.k.a. pinto.

## Overview

The MiG-21bis is a point-defence fighter aircraft developed by Mikoyan-Gurevich in 1972. It was one of the later variants in a long and extensive family tree, and was used as the basis for several more modern variants.

The MiG-21 is one of the most prolific fighters in the world, with production beginning in 1959 and later variants still being fielded to this day. Originally intended as a high altiude interceptor to defend against high-flying bombers, later variants equipped with more powerful engines fully rounded out this fighter which is still included in modern air forces.

Additional documentation can be found at http://wiki.flightgear.org/Mikoyan-Gurevich_MiG-21 as well as https://github.com/l0k1/MiG-21bis/wiki

## For FlightGear

The FlightGear MiG-21bis is currently undergoing substantial work, with a redone 3D cockpit, more weapons systems, accurate guidance and radar, FDM work, and much more. We are focused on quality work - everything should be done with an eye to realism and not taking shortcuts (if we can).

Further down the line, other variants of the MiG-21 are planned. Following the MiG-21bis will be the MiG-21bisD (the modern Croatian Air Force variant), a MiG-21MF, and a MiG-21 LanceR C/III. Contributions towards other variants are welcome - I will not limit the variants to this list, that's just my plan for the time being.

## Current State

This plane is a heavy work in progress, so things are constantly in flux. The realism is currently flexible while things are being implemented (such as the radar - there is no warmup period or timelimit yet, and it is too powerful), but as we get closer to a final product realism will be a higher priority.

Guided missiles use the guided-missiles.nas framework, dumb bombs, guns, and rockets use FlightGear's submodel framework.

The radar-logic.nas file is fairly standard but has some custom code in it, so direct replacement is not possible at this time.

## Contributing

Check the Github Projects pages for current needs, and feel free to open a pull request.
