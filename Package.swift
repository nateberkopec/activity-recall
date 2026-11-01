// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "activity-recall",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "activity-recall", linkerSettings: [.linkedLibrary("sqlite3")])
    ]
)
