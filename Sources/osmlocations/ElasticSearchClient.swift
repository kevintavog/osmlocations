import Foundation
import Just


public class ElasticSearchClient {
    private let baseUrl: String
    private var largestPayloadBytes = 0

    public static func connect() -> ElasticSearchClient {
        return ElasticSearchClient(ElasticSearch.ServerUrl)
    }

    private init(_ baseUrl: String) {
        self.baseUrl = baseUrl
    }

    public func close() {
    }

    private func pathToUrl(_ path: String) -> String {
        return "\(baseUrl)/\(path)".replacingOccurrences(of: "//", with: "/")
    }

    public func get(id: String) throws -> OsmEntry? {
        let path = "/\(ElasticSearch.IndexName)/_doc/\(id)"
        let response = Just.get(pathToUrl(path))
        if !response.ok {
            throw OsmError.httpError(status: response.statusCode ?? 0, message: response.text ?? "")
        }

        if let content = response.content {
            let json = try JSON(data: content)
            if let found = json["found"].bool {
                if found {
                    return try decodeFromElasticSearch(json: json["_source"])
                }
            }
        }
        throw OsmError.notFound(message: "'\(id)' not found")
    }

#if canImport(ObjectiveC)
    public func containedIn(lat: Double, lon: Double, first: Int, count: Int) throws -> SearchResponse {
        let query = String(format: elasticShapeQuery, first, count, "contains", lon, lat, lon, lat)
        return try _querySearch(fullQuery: query)
    }

    public func nearby(lat: Double, lon: Double, withinMeters: Double, first: Int, count: Int) throws -> SearchResponse {
        let (latDiff, lonDiff) = Geo.metersOffsetAt(meters: withinMeters, lat: lat, lon: lon)
        let query = String(format: elasticShapeQuery, 
            first, count,
            "intersects",
            // NOTE: The envelope requires [[minLon, maxLat], [maxLon, minLat]]
            // See https://www.elastic.co/guide/en/elasticsearch/reference/7.6/geo-shape.html#_envelope
            lon - lonDiff, lat + latDiff,
            lon + lonDiff, lat - latDiff)
        return try _querySearch(fullQuery: query)
    }
#endif

    public func search(query: String, first: Int, count: Int) throws -> SearchResponse {
        let q = query == "" ? "{ \"match_all\": {} }" : "{ \"query_string\": { \"query\": \"\(query)\" } }"
        let search = #"{ "query": \#(q), "from": \#(first), "size": \#(count) } "#
        return try _querySearch(fullQuery: search)
    }

    private func _querySearch(fullQuery: String) throws -> SearchResponse {
        let path = "/\(ElasticSearch.IndexName)/_search"
        let data = fullQuery.data(using: .utf8)!
        let response = Just.post(pathToUrl(path), headers: ElasticSearch.Headers, requestBody: data)
        if !response.ok {
            throw OsmError.httpError(status: response.statusCode ?? 0, message: response.text ?? "")
        }

        if let content = response.content {
            let json = try JSON(data: content)
            let totalMatches = json["hits"]["total"]["value"].intValue
            let jsonMatches = json["hits"]["hits"].arrayValue
            let matches = try jsonMatches.compactMap { try decodeFromElasticSearch(json: $0["_source"]) }

            return SearchResponse(matches: matches, totalMatches: totalMatches)
        }

        return SearchResponse(matches: [], totalMatches: 0)
    }

    public func index(entries: [OsmEntry]) throws -> ElasticSearchBulkResponse {
        do {
            let encodedEntries = try entries.map { try $0.encodeToElasticSearch() }
            var esBulk = [String]()
            for idx in 0..<entries.count {
                let item = entries[idx]
                let encoded = encodedEntries[idx]
                let s = "{\"index\": { \"_index\": \"\(ElasticSearch.IndexName)\", \"_id\": \"\(item.id)\" } }"
                esBulk.append(s)
                esBulk.append(encoded)
            }

            let request = esBulk.joined(separator: "\n") + "\n"
            if request.count > largestPayloadBytes {
                largestPayloadBytes = request.count
print("Largest payload now \(largestPayloadBytes)")
            }

// print("About to call with \(request.count)")

let payload = request.data(using: .utf8)!

// print("  -> payload: \(payload.count)")

            let path = "\(ElasticSearch.IndexName)/_bulk"
            let response = Just.post(
                pathToUrl(path),
                headers: ElasticSearch.Headers,
                timeout: 90.0,
                requestBody: payload)
            if !response.ok {
print("response !ok: \(response)")
                throw OsmError.httpError(status: response.statusCode ?? 0, message: response.text ?? "\(response)")
            }
            if let content = response.content {
                return try JSONDecoder().decode(ElasticSearchBulkResponse.self, from: content)
            }
            throw OsmError.unexpected(message: "index operation returned no data")
        } catch {
            throw OsmError.invalidParameter(message: "Can't convert item: \(error)")
        }
    }
}
