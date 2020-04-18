import Foundation
import Guaka

private func executeRoot(flags: Flags, args: [String]) {
    print(rootCommand.helpMessage)
}

let rootCommand = Command(usage: "osmlocations", run: executeRoot)
rootCommand.add(subCommand: indexCommand)
rootCommand.add(subCommand: lookupCommand)
rootCommand.add(subCommand: processCommand)
rootCommand.add(subCommand: searchCommand)

rootCommand.execute()

func printSearchResults(_ results: SearchResponse, _ prefix: String = "") {
    switch results.matches.count {
        case 0:
            print("\(prefix)No matches found")
            break
        case 1:
            print("\(prefix)\(results.matches.first!)")
            break
        default:
            print("\(prefix)Showing \(results.matches.count) of \(results.totalMatches) total matches:")
            for m in results.matches {
                print("\(prefix) -> \(m)")
            }
    }
}

func printTimeElapsedWhenRunningCode(_ title: String, _ operation: () throws ->()) throws {
#if canImport(ObjectiveC)
    let startTime = CFAbsoluteTimeGetCurrent()
    try operation()
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    print("Elapsed time '\(title)': \(timeElapsed) seconds")
#endif
}
