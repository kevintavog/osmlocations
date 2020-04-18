import Foundation

// Useful ids
//  Seattle; 47.60621, -122.33207 - XXX
//  Space Needle; 47.62051, -122.34928 - XXX
// 
public protocol OsmEntry: Codable, CustomStringConvertible, CustomDebugStringConvertible {
    var id: String { get }
    var name: String { get }
    var tags: [String:String] { get }
    var geoJson: String { get }

    var numShapes: Int { get }
    var numPoints: Int { get }
}

public extension OsmEntry {
    var description: String {
        return "\(id): \(name); \(tags)"
    }
}

public func createOsmEntry(id: String, name: String, points: [[GeoPoint]], tags: [String:String]) -> OsmEntry? {
    if points.count == 1 && points[0].count == 1 {
        return OsmPoint(id, name, points[0][0], tags)
    } else {
        return OsmArea(id, name, points, tags)
    }
}

public struct OsmPoint: OsmEntry {
    public let id: String
    public let name: String
    public let tags: [String:String]

    public let location: GeoPoint

    public init?(_ id: String, _ name: String, _ location: GeoPoint, _ tags: [String:String]) {
        self.id = id
        self.name = name
        self.tags = tags

        self.location = location
    }

    public var geoJson: String {
        return #" { "type": "Point", "coordinates": [ \(location.lon), \(location.lat) ] }"#
    }

    public var debugDescription: String {
        return "point; \(location)"
    }

    public var numShapes: Int {
        return 1
    }

    public var numPoints: Int {
        return 1
    }
}

public struct OsmArea: OsmEntry {
    public let id: String
    public let name: String
    public let tags: [String:String]

    public let shape: [[GeoPoint]]

    public init?(_ id: String, _ name: String, _ shape: [[GeoPoint]], _ tags: [String:String]) {
        if let grouped = OsmArea.formShapes(shape) {
            self.id = id
            self.name = name
            self.tags = tags
            self.shape = grouped
        } else {
            // print("ERROR: Can't get proper shapes for \(id): \(name); \(tags)")
            return nil
        }
    }

    public var geoJson: String {
        if self.shape.count == 1 {
            var g = #" { "type": "Polygon", "coordinates": [ [ "#
            g += shape[0].map { "[\($0.lon),\($0.lat)]" }.joined(separator: ",")
            g += #" ] ] }"#
            return g
        } else {
            var g = #" { "type": "MultiPolygon", "coordinates": [ "#
            g += shape.map { "[ [" + $0.map { "[\($0.lon),\($0.lat)]" }.joined(separator: ",") + "] ]" }.joined(separator: ",")
            g += #"  ] }"#
            return g
        }
    }

    public var debugDescription: String {
        return "shape, \(shape.count) points; \(shape)"
    }

    // Based off: https://wiki.openstreetmap.org/wiki/Relation:multipolygon/Algorithm
    private static func formShapes(_ shape: [[GeoPoint]]) -> ([[GeoPoint]]?) {
        var polygons = [[GeoPoint]]()
        var remainingShapes = shape
        var curShape: [GeoPoint]?

// print("Remaining: \(remainingShapes)")
        while remainingShapes.count > 0 {
            if curShape == nil {
                curShape = remainingShapes.removeFirst()
            }

// print("Current: \(curShape!)")
            // Is it self-contained? Then it doesn't depend on other shapes
            if curShape!.first! == curShape!.last! {
                polygons.append(curShape!)
                curShape = nil
// print("Standalone, first == last")
            } else {
                // Find the way that attaches to the end of this one
                if let idx = findAdjoiningIndex(curShape!, remainingShapes) {
// print("Found adjoining at \(idx): \(remainingShapes[idx])")
                    var next = remainingShapes.remove(at: idx)
                    if next.last! == curShape!.last! {
// print("Reversed adjoining")
                        next.reverse()
                    }
                    next.removeFirst()  // Remove duplicate point
                    curShape! += next
                } else {
                    return nil
                }
            }
        }

        if curShape != nil {
            polygons.append(curShape!)
        }

        return polygons
    }

    private static func findAdjoiningIndex(_ line: [GeoPoint], _ shapes: [[GeoPoint]]) -> Int? {
        for idx in 0..<shapes.count {
            let check = shapes[idx]
            if line.last! == check.first! || line.last! == check.last! {
                return idx
            }
        }
        return nil
    }

    public var numShapes: Int {
        return shape.count
    }

    public var numPoints: Int {
        return shape.reduce(0, { $0 + $1.count })
    }
}
