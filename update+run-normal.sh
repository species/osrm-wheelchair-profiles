#!/bin/bash
docker run -t -v $(pwd):/data osrm/osrm-backend:v5.5.2 osrm-extract -p /data/osrm-wheelchair-profiles/wheelchair-normal.lua /data/planet/austria/graz/normal/graz.osm.pbf
docker run -t -v $(pwd):/data osrm/osrm-backend:v5.5.2 osrm-contract /data/planet/austria/graz/normal/graz.osrm
docker run -t -i -p 5000:5000 -v $(pwd):/data osrm/osrm-backend:v5.5.2 osrm-routed /data/planet/austria/graz/normal/graz.osrm
