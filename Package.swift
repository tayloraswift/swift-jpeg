// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "swift-jpeg",
    products: [
        .library(name: "JPEG", targets: ["JPEG"]),
        .library(name: "JPEGSystem", targets: ["JPEGSystem"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ordo-one/dollup", from: "1.0.1"),
    ],
    targets: [
        .target(name: "JPEG"),

        .target(
            name: "JPEGSystem",
            dependencies: ["JPEG"]
        ),

        .target(name: "JPEGInspection"),

        .executableTarget(
            name: "JPEGFuzzer",
            dependencies: ["JPEG", "JPEGInspection", "JPEGSystem"],
            path: "tests/fuzz",
            exclude: [
                "data/",
            ]
        ),

        .executableTarget(
            name: "JPEGComparator",
            dependencies: ["JPEG", "JPEGInspection", "JPEGSystem"],
            path: "tests/compare"
        ),

        .executableTarget(
            name: "JPEGUnitTests",
            dependencies: ["JPEG", "JPEGInspection", "JPEGSystem"],
            path: "tests/unit"
        ),

        .executableTarget(
            name: "JPEGRegressionTests",
            dependencies: ["JPEG", "JPEGInspection", "JPEGSystem"],
            path: "tests/regression",
            exclude: [
                "gold/",
            ]
        ),

        .executableTarget(
            name: "JPEGIntegrationTests",
            dependencies: ["JPEG", "JPEGInspection", "JPEGSystem"],
            path: "tests/integration",
            exclude: [
                "decode/",
                "encode/",
            ]
        ),
    ],
)
for target: Target in package.targets {
    {
        var settings: [SwiftSetting] = $0 ?? []

        settings.append(.enableUpcomingFeature("ExistentialAny"))
        settings.append(.enableExperimentalFeature("StrictConcurrency"))

        $0 = settings
    } (&target.swiftSettings)
}
