import Foundation
import Just

public class ElasticSearch {
    static public var ServerUrl = ""
    static public var IndexName = "osm_poi"
    static public var CreateIndexScript = "./createIndex.json"
    static public let Headers = ["Content-Type": "application/json"]

    public init() { }

    public func initialize() throws {
        // Make sure ES exists (get version)
        var response = Just.get(ElasticSearch.ServerUrl)
        if !response.ok {
             throw OsmError.httpError(status: response.statusCode ?? 0, message: response.text ?? "")
        }

        let json = try JSON(data: response.content!)
        print("Using ElasticSearch \(json["version"]["number"].string!) host: \(ElasticSearch.ServerUrl)")

        // Make sure the index exists - create if not
        response = Just.get("\(ElasticSearch.ServerUrl)/\(ElasticSearch.IndexName)/_settings")
        if !response.ok {
            if response.statusCode! != 404 {
                throw OsmError.httpError(status: response.statusCode ?? 0, message: response.text ?? "")
            }
            try createIndex()
        }
    }

    private func createIndex() throws {
        print("Creating index '\(ElasticSearch.IndexName)'")
        let fileData = try Data(contentsOf: URL(fileURLWithPath: ElasticSearch.CreateIndexScript))
        let response = Just.put(
            "\(ElasticSearch.ServerUrl)/\(ElasticSearch.IndexName)/",
            headers: ElasticSearch.Headers,
            requestBody: fileData)
        if !response.ok {
            throw OsmError.httpError(status: response.statusCode ?? 0, message: response.text ?? "")
        }
    }
}
