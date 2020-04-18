public class OsmKeysAndValues {
    static let allKeysAndValues:[String:Set<String>] = [
        "aeroway": ["aerodome"],
        "amenity": ["college", "library", "university", "marketplace", 
            "monastery", "public_bath"],
        "attraction": ["*"],
        "boundary": ["national_park"],
        "building": ["train_station", "stadium"],
        "geological": ["palaeontological_site"],
        "historic": ["aqueduct", "archaeological_site", "battlefield", "castle",
            "church", "city_gate", "fort", "manor", "memorial", "monument", 
            "ruins", "tower", "wreck"],
        "landuse": ["cemetery"],
        "leisure": ["dog_park", "nature_reserve", "park" , "stadium"],
        "man_made": ["lighthouse", "obelisk"],
        "natural": ["volcano"],
        "place": ["square", "sea", "ocean"],
        "route": ["mtb"],
        "tourism": ["aquarium", "museum", "viewpoint", "zoo"],
    ]

    public static func isAllowed(key: String, val: String) -> Bool {
        if let subKeyValues = allKeysAndValues[key] {
            return subKeyValues.contains("*") || subKeyValues.contains(val)
        }
        return false
    }
}
