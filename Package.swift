// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "Cadence",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "Cadence",
            path: "Sources/Cadence"
        )
    ]
)
