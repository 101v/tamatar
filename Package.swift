// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Tamatar",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Tamatar", targets: ["Tamatar"]),
    ],
    targets: [
        .target(name: "TamatarCore"),
        .executableTarget(
            name: "Tamatar",
            dependencies: ["TamatarCore"],
            linkerSettings: [.linkedFramework("AVFoundation")]
        ),
        .testTarget(name: "TamatarCoreTests", dependencies: ["TamatarCore"]),
    ]
)
