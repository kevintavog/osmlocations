import Foundation

enum OsmError: Swift.Error {
    case missingConfigFile
    case httpError(status: Int, message: String)
    case invalidParameter(message: String)
    case unexpected(message: String)
    case notFound(message: String)
}

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}
