# osrm-wheelchair-profiles
Routing profiles for different kinds of wheelchair users for OSRM (Open Source Routing Machine)

there are also script files to download latest data, and to run OSRM from Docker.

File structure for Docker:

e.g. in /srv/osrm:
* osrm-wheelchair-profiles/ #(this git repo) - copy the scripts to ../
* \*.sh
* planet/austria/graz/ - folders for osm data - they download here.
 * in there 3 folders: athletic/, electro/, normal/ . the routing data gets extracted here. 
 * in each of the 3 folders a symlink "../graz.osm.pbf" has to be placed manually.
