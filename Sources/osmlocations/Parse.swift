import Foundation

#if !canImport(ObjectiveC)
import FoundationXML
#endif

let skipFirstItemCount = 0

class TempEntry: CustomStringConvertible {
    var id: String = ""
    var name: String = ""
    var nameEnglish: String = ""
    var tags = [String:String]()

    var nodePoints = [GeoPoint]()
    var wayPoints = [[GeoPoint]]()

    func reset() {
        id = ""
        name = ""
        nameEnglish = ""
        tags = [:]
        nodePoints = []
        wayPoints = []
    }

    var properName: String {
        if nameEnglish.count > 1 {
            return nameEnglish
        }
        return name
    }

    var isValid: Bool {
        return id.count > 1 && properName != "" && tags.count > 0 && (nodePoints.count > 0 || wayPoints.count > 0)
    }

    public var description: String {
        return "\(id), \"\(properName)\"; \(tags); \(nodePoints.count) node points"
    }
}

class Parse: NSObject, XMLParserDelegate {
    static let BatchSize = 100

    var countEntriesIndexed = 0
    var entries = [OsmEntry]()
    let elasticClient = ElasticSearchClient.connect()

    let wayPointsResolver: WayPointsResolver

    var tempEntry = TempEntry()

    let filePath: String
    init(_ filePath: String) {
        self.filePath = filePath
        wayPointsResolver = WayPointsResolver(elasticClient)
    }

    func run() throws {
        print("Parse \(filePath)")
        try validateArgs()

        try printTimeElapsedWhenRunningCode("parse", {
            try parse()
        })

        elasticClient.close()
    }

    func indexEntries(_ entries: [OsmEntry]) throws {
        if countEntriesIndexed >= skipFirstItemCount {
            var idx = 0
            while idx < entries.count {
                let end = min(idx + Parse.BatchSize, entries.count)
                do {
                    let response = try elasticClient.index(entries: Array(entries[idx..<end]))
                    if response.errors {
                        emitErrors(response, entries)
                    }
                } catch {
let printableEntries = entries.map { "\($0.id): \($0.name); \($0.numShapes) - \($0.numPoints)" }
print("Error indexing: \(error) @ \(countEntriesIndexed): \(printableEntries)")
                    throw error
                }
                idx = end
            }
        }

        countEntriesIndexed += entries.count
        if 0 == (countEntriesIndexed % 10000) {
            print("Have indexed \(countEntriesIndexed) entries")
        }
    }

    func emitErrors(_ response: ElasticSearchBulkResponse, _ entries: [OsmEntry]) {
        print("Failed indexing some entries:")
        for idx in 0..<response.items.count {
            let item = response.items[idx]
            if let error = item.index.error {
                print(" -> \(error.type): \(error.reason);")
                print(" --> \(error.caused_by.type): \(error.caused_by.reason ?? "")")
                if idx < entries.count {
                    print(" ---> \(entries[idx])")
                    // print(" ---> \(entries[idx]):\n\(entries[idx].debugDescription)")
                    // print(" ---> \(entries[idx]):\n\(entries[idx].geoJson)")
                }
            }
        }
    }

    func parse() throws {
        if let xmlParser = XMLParser(contentsOf: URL(fileURLWithPath: filePath)) {
            xmlParser.delegate = self
            if !xmlParser.parse() {
                throw "Some parsing error: \(String(describing: xmlParser.parserError))"
            }
        } else {
            throw "Unable to find or open \(filePath)"
        }
    }

    // Start element
    func parser(_ parser: XMLParser, 
            didStartElement elementName: String, 
            namespaceURI: String?, 
            qualifiedName qName: String?, 
            attributes attributeDict: [String : String] = [:]) {


        autoreleasepool {
            switch elementName {
                case "way":
                    // id and tags (which will come in later elements)
                    tempEntry.reset()
                    tempEntry.id = "w" + (attributeDict["id"] ?? "")
                    break

                // <nd ref="30102621" lat="47.5980308" lon="-122.3303163"/>
                case "nd":
                    // TODO: It's posible to skip unparseable lat/lon here; consider if warnings or errors are useful
                    if let lat = Double(attributeDict["lat"] ?? ""), let lon = Double(attributeDict["lon"] ?? "") {
                        tempEntry.nodePoints.append(GeoPoint(lat: lat, lon: lon))
                    }
                    break

                case "relation":
                    tempEntry.reset()
                    tempEntry.id = "r" + (attributeDict["id"] ?? "")
                    break

                case "member":
                    // type=way, ref="<way id>", role="outer"
                    let type = attributeDict["type"] ?? ""
                    let role = attributeDict["role"] ?? ""
                    if type == "way" && role == "outer" {
                        let ref = "w" + (attributeDict["ref"] ?? "")
                        if ref.count > 1 {
                            do {
                                if let points = try wayPointsResolver.get(ref) {
                                    tempEntry.wayPoints.append(points)
                                } else {
                                    print("Unable to find way: \(ref) for relation \(tempEntry.id)")
                                }
                            } catch {
                                print("ERROR: unable to retrieve way points: \(error)")
                            }
                        }
                    }
                    break

                case "node":
                    // lon, lat, id
                    tempEntry.reset()
                    tempEntry.id = "n" + (attributeDict["id"] ?? "")
                    if let lat = Double(attributeDict["lat"] ?? ""), let lon = Double(attributeDict["lon"] ?? "") {
                        tempEntry.nodePoints.append(GeoPoint(lat: lat, lon: lon))
                    }
                    break

                case "tag":
                    addFilteredTags(attributeDict)
                    break

                default:
                    return
            }
        }
    }

    // End element
    func parser(_ parser: XMLParser, 
            didEndElement elementName: String, 
            namespaceURI: String?, 
            qualifiedName qName: String?) {

        switch elementName {
            case "node":
                break
            case "way":
                break
            case "relation":
                break
            default:
                return
        }

        autoreleasepool {
            // if elementName == "way" && tempEntry.nodePoints.count > 1 {
            //     osmWayPoints[tempEntry.id] = tempEntry.nodePoints
            // }
            if tempEntry.isValid {
                let points = elementName == "relation" ? tempEntry.wayPoints : [tempEntry.nodePoints]
                if let osmEntry = createOsmEntry(
                    id:tempEntry.id, name: tempEntry.properName, points: points, tags: tempEntry.tags) {
                        entries.append(osmEntry)
                    }
            }

            if entries.count >= Parse.BatchSize {
                do {
                    try indexEntries(entries)
                } catch {
                    print("Failed indexing entries: \(error)")
                    parser.abortParsing()
                }
                entries.removeAll(keepingCapacity: true)
            }
        }
    }

    func parserDidStartDocument(_ parser: XMLParser) {
        entries.removeAll(keepingCapacity: true)
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        if entries.count > 0 {
            do {
                try indexEntries(entries)
            } catch {
                print("Failed indexing entries: \(error)")
                parser.abortParsing()
            }
            entries.removeAll(keepingCapacity: true)
        }
    }

    // name, <list from osmosis filter, such as tourism, leisure, etc>
    func addFilteredTags(_ attributes: [String:String]) {
        if let k = attributes["k"], let v = attributes["v"] {
            if OsmKeysAndValues.isAllowed(key: k, val: v) {
                tempEntry.tags[k] = v
            } else if k == "name" {
                tempEntry.name = v
            } else if k == "name:en" {
                tempEntry.nameEnglish = v
            }
        }
    }

    func validateArgs() throws {
        var isFolder: ObjCBool = false
        if !FileManager.default.fileExists(atPath: filePath, isDirectory: UnsafeMutablePointer<ObjCBool>(&isFolder)) {
            throw "Path does not exist: \(filePath)"
        }
        if isFolder.boolValue {
            throw "Path must be a file: \(filePath)"
        }
    }
}
