// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "osmlocations",
    dependencies: [

        .package(url: "https://github.com/nsomar/Guaka.git", from: "0.4.1"),
        .package(url: "https://github.com/dduan/Just.git",  from: "0.8.0"),
        // .package(url: "https://github.com/SwiftyJSON/SwiftyJSON", from: "5.0.0"),   // Overridden to build on Linux/Docker
    ],
    targets: [
        .target(
            name: "osmlocations",
            dependencies: ["Guaka", "Just"]),
        .testTarget(
            name: "osmlocationsTests",
            dependencies: ["osmlocations"]),
    ]
)
