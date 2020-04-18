import Guaka

let searchCommand = Command(
        usage: "search",
        flags: [countFlag, elasticUrlFlag, queryFlag],
        run: executeSearchCommand)

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

private let queryFlag = Flag(
    shortName: "q", 
    longName: "query", 
    type: String.self, 
    description: "The name to look for", 
    required: true)


private func executeSearchCommand(flags: Flags, args: [String]) {
    ElasticSearch.ServerUrl = flags.getString(name: "elasticUrl")!
    do {
        try ElasticSearch().initialize()
    } catch {
        fail(statusCode: 1, errorMessage: "Failed initializing: \(error)")
    }

    do {
        let count = flags.getInt(name: "count") ?? 10
        let query = flags.getString(name: "query")!
        let client = ElasticSearchClient.connect()
        defer { client.close() }

        let results = try client.search(query: query, first: 0, count: count)
        printSearchResults(results)

    } catch {
        fail(statusCode: 1, errorMessage: "Failed: \(error)")
    }
}
