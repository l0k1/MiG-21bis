# MiG-21bis 

by: Petar Jedvaj, David Culp, Raptor, Stuart Cassie, Gary Brown, Brendan Black, bugman, and Tomaskom.

Currently maintained by Justin Nicholson, a.k.a. pinto.

## Overview

The MiG-21bis is a point-defence fighter aircraft developed by Mikoyan-Gurevich in 1972. It was one of the later variants in a long and extensive family tree, and was used as the basis for several more modern variants.

The MiG-21 is one of the most prolific fighters in the world, with production beginning in 1959 and later variants still being fielded to this day. Originally intended as a high altiude interceptor to defend against high-flying bombers, later variants equipped with more powerful engines fully rounded out this fighter which is still included in modern air forces.

## For FlightGear

The FlightGear MiG-21bis is currently undergoing substantial work, with a redone 3D cockpit, more weapons systems, accurate guidance and radar, FDM work, and much more. We are focused on quality work - everything should be done with an eye to realism and not taking shortcuts (if we can).

Further down the line, other variants of the MiG-21 are planned. Following the MiG-21bis will be the MiG-21bisD (the modern Croatian Air Force variant), a MiG-21MF, and a MiG-21 LanceR C/III. Contributions towards other variants are welcome - I will not limit the variants to this list, that's just my plan for the time being.

## Current State

This plane is a heavy work in progress, so things are constantly in flux. The realism is currently flexible while things are being implemented (such as the radar - there is no warmup period or timelimit yet, and it is too powerful), but as we get closer to a final product realism will be a higher priority.

Guided missiles use the guided-missiles.nas framework, dumb bombs and rockets use FlightGear's submodel framework.

The radar-logic.nas file is fairly standard but has some custom code in it, so direct replacement is not possible at this time.

## Contributing

The biggest needs I have are for more ordinance, specifically 3D models. If it was used by any variant of a MiG, it would be welcome. Please limit tris for single missiles/rockets to around 2,000 (not a hard limit), and for multi-rocket-launchers to 3,000-4,000. More tris are okay, I'd rather have quality vs not-quality. No hard texture limit size, keep it reasonable. These will be reviewed for quality before committing.

High quality instrument face textures are needed - 512x512, use Cabin Condensed font, please try to maintain a consistent style using the current fuel guage, VSI, HI, and ASI as references.

On the nasal side, support for multiple weapons per pylon is needed, such as 2 R-60's or 4 FAB-100's.

The radar canvas is nearly complete, but could still use some love.

If you see a need that isn't listed here, feel free to contact me to organize contributing. If it isn't already being worked on, you won't be turned down!
