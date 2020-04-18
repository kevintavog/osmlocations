import Foundation

extension OsmPoint {
    public func encodeToJson() throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(self)
    }

    static public func decodeFromJson(json: Data) throws -> OsmPoint {
        let decoder = JSONDecoder()
        return try decoder.decode(OsmPoint.self, from: json)
    }
}

extension OsmArea {
    public func encodeToJson() throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(self)
    }

    static public func decodeFromJson(json: Data) throws -> OsmArea {
        let decoder = JSONDecoder()
        return try decoder.decode(OsmArea.self, from: json)
    }
}
