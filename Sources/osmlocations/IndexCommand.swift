import Guaka

let indexCommand = Command(
        usage: "index",
        flags: [dataPathFlag, createScriptFlag, elasticUrlFlag],
        run: executeIndexCommand)


private let createScriptFlag = Flag(
    shortName: "c", 
    longName: "createScript", 
    type: String.self, 
    description: "The script for creating the ElasticSearch index if the index doesn't exist", 
    required: false)

private let dataPathFlag = Flag(
    shortName: "d", 
    longName: "data", 
    type: String.self,
    description: "The path containing the OpenStreetMap processed data",
    required: true)

private let elasticUrlFlag = Flag(
    shortName: "e", 
    longName: "elasticUrl", 
    type: String.self, 
    description: "The URL for the ElasticSearch service", 
    required: true)

private func executeIndexCommand(flags: Flags, args: [String]) {
    if let createScript = flags.getString(name: "createScript") {
        ElasticSearch.CreateIndexScript = createScript
    }

    ElasticSearch.ServerUrl = flags.getString(name: "elasticUrl")!
    do {
        try ElasticSearch().initialize()
    } catch {
        fail(statusCode: 1, errorMessage: "Failed initializing: \(error)")
    }

    do {
        try Parse(flags.getString(name: "data")!).run()
    } catch {
        fail(statusCode: 1, errorMessage: "Failed: \(error)")
    }
}
