import Foundation

class WayPointsResolver {
    let elasticSearch: ElasticSearchClient

    init(_ elasticSearch: ElasticSearchClient) {
        self.elasticSearch = elasticSearch
    }

    func get(_ id: String) throws -> [GeoPoint]? {
        // return wayPoints[id]
        if let entry = try elasticSearch.get(id: id) {
            if let way = entry as? OsmArea {
                if way.shape.count > 1 {
                    print("Unhandled multipoint: \(id)")
                } else {
                    return way.shape[0]
                }
            }
        }
        return nil
    }
}
