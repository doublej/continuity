// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Continuity",
    platforms: [
        .macOS(.v26)
    ],
    targets: [
        .executableTarget(
            name: "Continuity",
            path: "continuity"
        ),
        .testTarget(
            name: "ContinuityTests",
            dependencies: ["Continuity"],
            path: "Tests/ContinuityTests"
        )
    ]
)
