#!/bin/bash

# written by Michael Maier (s.8472@aon.at)
# 
# 16.06.2017   - intial release
#

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 2 as published by the Free Software Foundation.

###
### Standard help text
###

if [ "$1" = "-h" ] || [ "$1" = " -help" ] || [ "$1" = "--help" ]
then 
cat <<EOH
Usage: $0 [OPTIONS] 

$0 is a program to retrieve newest OSM files for routing and generate Graz extracts

OPTIONS:
   -h -help --help     this help text

EOH
fi

###
### variables
###



###
### working part
###

cd /srv/osrm/planet/austria/
wget -N http://download.geofabrik.de/europe/austria-latest.osm.pbf
osmosis --read-pbf file=austria-latest.osm.pbf --bounding-box top=47.15 bottom=47 left=15.36 right=15.55 completeWays=yes --write-pbf file=graz/graz.osm.pbf
