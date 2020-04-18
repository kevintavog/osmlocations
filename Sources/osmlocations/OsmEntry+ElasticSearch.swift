import Foundation

public extension OsmEntry {
    func encodeToElasticSearch() throws -> String {
        var shape = JSON()
        if let point = self as? OsmPoint {
            shape = try point.encodeToElasticSearchShape()
        } else if let area = self as? OsmArea {
            shape = try area.encodeToElasticSearchShape()
        } else {
            throw "INTERNAL: Missing handling for \(self)"
        }

        let json: JSON = [
            "id": id,
            "timestamp": Int64(Date().timeIntervalSince1970),
            "name": name,
            "tags": tags,
            "osmshape": shape.object,
        ]
        if let converted = json.rawString(options: JSONSerialization.WritingOptions(rawValue: 0)) {
            return converted
        }
        throw "Failed converting to json: \(self)"
    }
}

public func decodeFromElasticSearch(stringData: String) throws -> OsmEntry? {
    if let data = stringData.data(using: .utf8, allowLossyConversion: false) {
        return try decodeFromElasticSearch(json: JSON(data))
    }
    throw "Unable to get data from string"    
}

public func decodeFromElasticSearch(json: JSON) throws -> OsmEntry? {
    switch json["osmshape"]["type"] {
        case "point":
            return OsmPoint.decodeFromElasticSearchJson(json)
        case "polygon", "multipolygon":
            return OsmArea.decodeFromElasticSearchJson(json)
        default:
            throw "Unhandled type: entry '\(json["osmshape"]["type"])''"
    }
}

public extension OsmPoint {
    func encodeToElasticSearchShape() throws -> JSON {
        let coordinates = [self.location.lon, self.location.lat]
        let shape: JSON = [
            "type": "point",
            "coordinates": coordinates,
        ]

        return shape
    }

    static func decodeFromElasticSearchJson(_ json: JSON) -> OsmPoint? {
        let pointJson = json["osmshape"]["coordinates"].arrayValue
        let tags: [String:String] = json["tags"].dictionaryObject as! [String:String]

        return OsmPoint(
            json["id"].stringValue,
            json["name"].stringValue,
            GeoPoint(lat: pointJson[0].doubleValue, lon: pointJson[1].doubleValue),
            tags)
    }
}

public extension OsmArea {
    func encodeToElasticSearchShape() throws -> JSON {
        let multipolygon = self.shape.count > 1

        let shape: JSON = [
            "type": multipolygon ? "multipolygon" : "polygon",
            "coordinates": multipolygon ? multipolygonCoordinates() : polygonCoordinates(),
        ]

        return shape
    }

    private func polygonCoordinates() -> Any {
        return self.shape.map { $0.map { [$0.lon, $0.lat] } }
    }

    private func multipolygonCoordinates() -> Any {

        return self.shape.map { [$0.map { [$0.lon, $0.lat] }] }
    }

    static func decodeFromElasticSearchJson(_ json: JSON) -> OsmArea? {
        let tags: [String:String] = json["tags"].dictionaryObject as! [String:String]
        let coordinatesJson = json["osmshape"]["coordinates"].arrayValue[0]
        let shape = coordinatesJson.arrayValue.map {
            GeoPoint(lat: $0[0][1].doubleValue, lon: $0[0][0].doubleValue)}
        return OsmArea(
            json["id"].stringValue,
            json["name"].stringValue,
            [shape],
            tags)
    }
}
