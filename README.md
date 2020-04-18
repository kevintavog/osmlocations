# osmlocations

A description of this package.



https://wiki.openstreetmap.org/wiki/Map_Features
https://taginfo.openstreetmap.org/keys/boundary#values

aeroway=aerodome
amenity=college,library,university,marketplace,monastery,public_bath
boundary=national_park
building=train_station,stadium
geological=palaeontological_site
historic=aqueduct,archaeological_site,battlefield,castle,church,city_gate,fort,manor,memorial,monument,ruins,tower,wreck
landuse=cemetery
leisure=dog_park,nature_reserve,park,stadium
man_made=lighthouse,obelisk
natural=volcano
place=square,sea,ocean
route=mtb
tourism=aquarium,artwork,museum,viewpoint,zoo


--------

osmosis --read-pbf andalucia.osm.pbf --tf accept-nodes \
aeroway=aerodome amenity=college,library,university,marketplace,monastery,public_bath \
attraction="*" boundary=national_park \
building=train_station,stadium geological=palaeontological_site \
historic=aqueduct,archaeological_site,battlefield,castle,church,city_gate,fort,manor,memorial,monument,ruins,tower,wreck \
landuse=cemetery leisure=dog_park,nature_reserve,park,stadium man_made=lighthouse,obelisk natural=volcano \
place=square,sea,ocean route=mtb tourism=aquarium,artwork,museum,viewpoint,zoo \
--node-key keyList="name" --tf reject-ways --tf reject-relations --write-xml andalucia.osm

------

// Filter nodes, ways & relations to POI
osmium tags-filter Seattle.osm.pbf --overwrite -o Seattle.osm \
aeroway=aerodome amenity=college,library,university,marketplace,monastery,public_bath \
attraction="*" boundary=national_park \
building=train_station,stadium geological=palaeontological_site \
historic=aqueduct,archaeological_site,battlefield,castle,church,city_gate,fort,manor,memorial,monument,ruins,tower,wreck \
landuse=cemetery leisure=dog_park,nature_reserve,park,stadium man_made=lighthouse,obelisk natural=volcano \
place=square,sea,ocean route=mtb tourism=aquarium,artwork,museum,viewpoint,zoo

// Add node locations to all ways
osmium add-locations-to-ways Seattle.osm -n --overwrite -o LocationsSeattle.osm

// This will be done in code instead - otherwise, needed `ways` will be lost
<!-- // Get rid of everything missing a name -->
<!-- osmium tags-filter LocationsSeattle.osm --overwrite -o NamedSeattle.osm name -->


------------


Genesee Park and Playfield
    Relation: 2132448
    Multipolygon

Joseph Foster Memorial park
    47.47816/-122.26902
    Relation: 7538923
    Multipolygon

Seattle center:
    47.62050/-122.34930
    Way: 4755066

Gas Works park:
    47.64523/-122.33487
    Relation: 1047789

Seward park:
    47.5538/-122.2516
    Relation: 971480

Jefferson park:
    47.5702/-122.3115
    Relation: 537386

