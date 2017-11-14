#!/bin/bash
docker run -t -v $(pwd):/data osrm/osrm-backend:v5.5.2 osrm-extract -p /data/osrm-wheelchair-profiles/wheelchair-elektro.lua /data/planet/austria/graz/electro/graz.osm.pbf
docker run -t -v $(pwd):/data osrm/osrm-backend:v5.5.2 osrm-contract /data/planet/austria/graz/electro/graz.osrm
docker run -t -i -p 5001:5000 -v $(pwd):/data osrm/osrm-backend:v5.5.2 osrm-routed /data/planet/austria/graz/electro/graz.osrm
