#!/bin/bash
docker run -t -v $(pwd):/data osrm/osrm-backend:v5.5.2 osrm-extract -p /data/osrm-wheelchair-profiles/wheelchair-athletic.lua /data/planet/austria/graz/athletic/graz.osm.pbf
docker run -t -v $(pwd):/data osrm/osrm-backend:v5.5.2 osrm-contract /data/planet/austria/graz/athletic/graz.osrm
docker run -t -i -p 5002:5000 -v $(pwd):/data osrm/osrm-backend:v5.5.2 osrm-routed /data/planet/austria/graz/athletic/graz.osrm
