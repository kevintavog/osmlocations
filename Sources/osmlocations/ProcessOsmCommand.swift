import Guaka

let processCommand = Command(
        usage: "process",
        flags: [osmFile],
        run: executeProcessCommand)


private let osmFile = Flag(
    shortName: "o", 
    longName: "osm", 
    type: String.self,
    description: "The OSM pbf file to process",
    required: true)

private func executeProcessCommand(flags: Flags, args: [String]) {
print("execute process command")

/*

osmium tags-filter andalucia.osm.pbf  --overwrite -o andalucia.osm  \
  aeroway=aerodome amenity=college,library,university,marketplace,monastery,public_bath boundary=national_park \
  building=train_station,stadium geological=palaeontological_site \
  historic=aqueduct,archaeological_site,battlefield,castle,church,city_gate,fort,manor,memorial,monument,ruins,tower,wreck \
  landuse=cemetery leisure=dog_park,nature_reserve,park,stadium man_made=lighthouse,obelisk natural=volcano \
  place=square,sea,ocean route=mtb tourism=aquarium,museum,viewpoint,zoo

*/

/*

osmium add-locations-to-ways andalucia.osm -n --overwrite -o LocationsAndalucia.osm

*/

}
