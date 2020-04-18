import Foundation

public struct GeoPoint: Codable {
    public let lat: Double
    public let lon: Double
}

extension GeoPoint: CustomStringConvertible {
    public var description: String {
        return "\(lat),\(lon)"
    }
}

extension GeoPoint: Equatable {
    public static func == (lhs: GeoPoint, rhs: GeoPoint) -> Bool {
        return
            lhs.lat == rhs.lat &&
            lhs.lon == rhs.lon
    }
}

public class Geo {
    static let radiusEarthKm = 6371.3
    static let oneDegreeLatitudeMeters = 111111.0


    // Use the small distance calculation (Pythagorus' theorem)
    // See the 'Equirectangular approximation' section of http://www.movable-type.co.uk/scripts/latlong.html
    // The distance returned is in kilometers
    static public func distance(pt1: GeoPoint, pt2: GeoPoint) -> Double {
        return Geo.distance(lat1: pt1.lat, lon1: pt1.lon, lat2: pt2.lat, lon2: pt2.lon)
    }

    static public func distance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let rLat1 = Geo.toRadians(degrees: lat1)
        let rLon1 = Geo.toRadians(degrees: lon1)
        let rLat2 = Geo.toRadians(degrees: lat2)
        let rLon2 = Geo.toRadians(degrees: lon2)

        let x = (rLon2 - rLon1) * cos((rLat1 + rLat2) / 2)
        let y = rLat2 - rLat1
        return sqrt((x * x) + (y * y)) * radiusEarthKm
    }

    static public func metersOffsetAt(meters: Double, lat: Double, lon: Double) -> (Double, Double) {
        // From https://gis.stackexchange.com/questions/2951/algorithm-for-offsetting-a-latitude-longitude-by-some-amount-of-meters
        let latOffset = meters / oneDegreeLatitudeMeters
        let lonOffset = meters / (oneDegreeLatitudeMeters * cos(toRadians(degrees: lon)))
        return (latOffset, lonOffset)
    }

    static public func toRadians(degrees: Double) -> Double {
        return degrees * Double.pi / 180.0
    }

    static public func toDegrees(radians: Double) -> Double {
        return radians * 180.0 / Double.pi
    }
}
