import Foundation

public enum ElasticSearchResultType: String, Codable {
    case created = "created"
    case updated = "updated"
    case deleted = "deleted"
    case notFound = "not_found"
    case noop = "noop"
}

public struct ElasticSearchIndexResponse: Codable {
    public let result: ElasticSearchResultType
}

public struct ElasticSearchBulkResponse: Codable {
    public let errors: Bool
    public let items: [BulkItemsResponse]

    public struct BulkItemsResponse: Codable {
        public let index: BulkIndexResponse
    }

    public struct BulkIndexResponse: Codable {
        public let result: String?
        public let status: Int
        public let error: BulkIndexResponseError?
        public let _shards: BulkIndexResponseShards?

        public struct BulkIndexResponseShards: Codable {
            public let total: Int
            public let successful: Int
            public let failed: Int
        }

        public struct BulkIndexResponseError: Codable {
            public let type: String
            public let reason: String
            public let caused_by: BulkdIndexResponseErrorCause
        }

        public struct BulkdIndexResponseErrorCause: Codable {
            public let type: String
            public let reason: String?
        }
    }
}

public struct SearchResponse {
    public let matches: [OsmEntry]
    public let totalMatches: Int

    public init(matches: [OsmEntry], totalMatches: Int) {
        self.matches = matches
        self.totalMatches = totalMatches
    }
}

