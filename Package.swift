// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "swift-jpeg",
    products:
    [
        .library(name: "JPEG", targets: ["JPEG"]),
        .library(name: "JPEGSystem", targets: ["JPEGSystem"]),
    ],
    targets:
    [
        .target(name: "JPEG"),

        .target(name: "JPEGSystem",
            dependencies: ["JPEG"]),

        .target(name: "JPEGInspection"),

        .executableTarget(name: "JPEGFuzzer",
            dependencies: ["JPEG", "JPEGInspection", "JPEGSystem"],
            path: "tests/fuzz",
            exclude: [
                "data/",
            ]
        ),

        .executableTarget(name: "JPEGComparator",
            dependencies: ["JPEG", "JPEGInspection", "JPEGSystem"],
            path: "tests/compare"),

        .executableTarget(name: "JPEGUnitTests",
            dependencies: ["JPEG", "JPEGInspection", "JPEGSystem"],
            path: "tests/unit"),

        .executableTarget(name: "JPEGRegressionTests",
            dependencies: ["JPEG", "JPEGInspection", "JPEGSystem"],
            path: "tests/regression",
            exclude: [
                "gold/",
            ]),

        .executableTarget(name: "JPEGIntegrationTests",
            dependencies: ["JPEG", "JPEGInspection", "JPEGSystem"],
            path: "tests/integration",
            exclude: [
                "decode/",
                "encode/",
            ]),
    ],
    swiftLanguageVersions: [.v4_2, .v5]
)
