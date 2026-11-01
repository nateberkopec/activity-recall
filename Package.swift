// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "activity-recall",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "activity-recall", targets: ["activity-recall"])],
    targets: [
        .executableTarget(name: "activity-recall", linkerSettings: [.linkedLibrary("sqlite3")])
    ]
)
