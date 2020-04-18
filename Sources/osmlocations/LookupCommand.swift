import Guaka

let lookupCommand = Command(
        usage: "lookup",
        flags: [countFlag, elasticUrlFlag, locationFlag, metersFlag],
        run: executeLookupCommand)

private let countFlag = Flag(
    shortName: "c", 
    longName: "count", 
    type: Int.self, 
    description: "The number of results to return", 
    required: false)

private let elasticUrlFlag = Flag(
    shortName: "e", 
    longName: "elasticUrl", 
    type: String.self, 
    description: "The URL for the ElasticSearch service", 
    required: true)

private let locationFlag = Flag(
    shortName: "l", 
    longName: "location", 
    type: String.self, 
    description: "Comma separated lat/lon: 47.1,-122.3", 
    required: true)

private let metersFlag = Flag(
    shortName: "m", 
    longName: "meters", 
    type: Int.self, 
    description: "For the nearby search, how many meters away to search through",
    required: false)

private func executeLookupCommand(flags: Flags, args: [String]) {
    ElasticSearch.ServerUrl = flags.getString(name: "elasticUrl")!
    do {
        try ElasticSearch().initialize()
    } catch {
        fail(statusCode: 1, errorMessage: "Failed initializing: \(error)")
    }

#if canImport(ObjectiveC)
    do {
        let location = flags.getString(name: "location")!
        let count = flags.getInt(name: "count") ?? 10
        let meters = flags.getInt(name: "meters") ?? 50
        let (latitude,longitude) = parseLocation(location)
        if let lat = latitude, let lon = longitude {
            print("Lookup: \(lat),\(lon)")
            let client = ElasticSearchClient.connect()
            defer { client.close() }

            var results = try client.containedIn(lat: lat, lon: lon, first: 0, count: count)
            print("Contained in")
            printSearchResults(results, "  ")

            results = try client.nearby(lat: lat, lon: lon, withinMeters: Double(meters), first: 0, count: count)
            print("Within \(meters) meters")
            printSearchResults(results, "  ")
        }

    } catch {
        fail(statusCode: 1, errorMessage: "Failed: \(error)")
    }
#endif
}

private func parseLocation(_ location: String) -> (Double?, Double?) {
    var tokens = location.split(separator: ",")
    if tokens.count == 1 {
        tokens = location.split(separator: "/")
    }
    if tokens.count == 1 {
        tokens = location.split(separator: " ")
    }

    if tokens.count == 2 {
        return (Double(tokens[0]), Double(tokens[1]))
    }
    return (nil, nil)
}