// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "jpeg",
    products: 
    [
        .library(name: "JPEG",    targets: ["JPEG"])
    ],
    targets: 
    [
        .target(          name: "JPEG",                                           path: "sources/jpeg"),
        .executableTarget(name: "fuzzer",              dependencies: ["JPEG"], path: "tests/fuzz",
            exclude:
            [
                "data/",
            ]
        ),
        .executableTarget(name: "comparator",          dependencies: ["JPEG"], path: "tests/compare"),
        .executableTarget(name: "unit-test",           dependencies: ["JPEG"], path: "tests/unit"),
        .executableTarget(name: "regression-test",     dependencies: ["JPEG"], path: "tests/regression",
            exclude:
            [
                "gold/",
            ]
        ),
        .executableTarget(name: "integration-test",    dependencies: ["JPEG"], path: "tests/integration",
            exclude:
            [
                "decode/",
                "encode/",
            ]
        ),
        
        .executableTarget(name: "decode-basic",        dependencies: ["JPEG"], path: "examples/decode-basic",
            exclude:
            [
                "karlie-kwk-2019.jpg.rgb",
                "karlie-kwk-2019.jpg",
                "karlie-kwk-2019.jpg.rgb.png",
            ]
        ),
        .executableTarget(name: "encode-basic",        dependencies: ["JPEG"], path: "examples/encode-basic",
            exclude:
            [
                "karlie-milan-sp12-2011-4-4-0-4.0.jpg",
                "karlie-milan-sp12-2011-4-2-2-1.0.jpg",
                "karlie-milan-sp12-2011-4-4-0-2.0.jpg",
                "karlie-milan-sp12-2011-4-4-4-0.5.jpg",
                "karlie-milan-sp12-2011-4-2-2-8.0.jpg",
                "karlie-milan-sp12-2011-4-4-0-0.0.jpg",
                "karlie-milan-sp12-2011-4-4-0-0.5.jpg",
                "karlie-milan-sp12-2011-4-4-0-1.0.jpg",
                "karlie-milan-sp12-2011-4-2-0-4.0.jpg",
                "karlie-milan-sp12-2011-4-2-0-0.25.jpg",
                "karlie-milan-sp12-2011-4-2-0-0.5.jpg",
                "karlie-milan-sp12-2011-4-4-4-1.0.jpg",
                "karlie-milan-sp12-2011-4-2-0-1.0.jpg",
                "karlie-milan-sp12-2011-4-2-2-0.25.jpg",
                "karlie-milan-sp12-2011-4-2-2-4.0.jpg",
                "karlie-milan-sp12-2011-4-2-2-2.0.jpg",
                "karlie-milan-sp12-2011-4-4-0-0.125.jpg",
                "karlie-milan-sp12-2011-4-4-4-4.0.jpg",
                "karlie-milan-sp12-2011-4-2-0-2.0.jpg",
                "karlie-milan-sp12-2011-4-4-4-0.0.jpg",
                "karlie-milan-sp12-2011-4-2-2-0.0.jpg",
                "karlie-milan-sp12-2011-4-2-2-0.5.jpg",
                "karlie-milan-sp12-2011-4-2-2-0.125.jpg",
                "karlie-milan-sp12-2011-4-2-0-0.125.jpg",
                "karlie-milan-sp12-2011-4-2-0-8.0.jpg",
                "karlie-milan-sp12-2011.rgb",
                "karlie-milan-sp12-2011.rgb.png",
                "karlie-milan-sp12-2011-4-4-0-8.0.jpg",
                "karlie-milan-sp12-2011-4-4-4-2.0.jpg",
                "karlie-milan-sp12-2011-4-4-4-8.0.jpg",
                "karlie-milan-sp12-2011-4-4-4-0.25.jpg",
                "karlie-milan-sp12-2011-4-4-0-0.25.jpg",
                "karlie-milan-sp12-2011-4-2-0-0.0.jpg",
                "karlie-milan-sp12-2011-4-4-4-0.125.jpg",
            ]
        ),
        .executableTarget(name: "decode-advanced",     dependencies: ["JPEG"], path: "examples/decode-advanced",
            exclude:
            [
                "karlie-2019.jpg-0.640x432.gray",
                "karlie-2019.jpg-2.320x216.gray.png",
                "karlie-2019.jpg",
                "karlie-2019.jpg.rgb.png",
                "karlie-2019.jpg-1.320x216.gray",
                "karlie-2019.jpg-1.320x216.gray.png",
                "karlie-2019.jpg-2.320x216.gray",
                "karlie-2019.jpg.rgb",
                "karlie-2019.jpg-0.640x432.gray.png",
            ]
        ),
        .executableTarget(name: "encode-advanced",     dependencies: ["JPEG"], path: "examples/encode-advanced",
            exclude:
            [
                "karlie-cfdas-2011.png.rgb",
                "karlie-cfdas-2011.png",
                "karlie-cfdas-2011.png.rgb.jpg",
            ]
        ),
        .executableTarget(name: "in-memory",           dependencies: ["JPEG"], path: "examples/in-memory",
            exclude:
            [
                "karlie-2011.jpg.rgb.png",
                "karlie-2011.jpg",
                "karlie-2011.jpg.rgb",
                "karlie-2011.jpg.jpg",
            ]
        ),
        .executableTarget(name: "decode-online",       dependencies: ["JPEG"], path: "examples/decode-online",
            exclude:
            [
                "karlie-oscars-2017.jpg-9.rgb.png",
                "karlie-oscars-2017.jpg-difference-8.rgb.png",
                "karlie-oscars-2017.jpg-difference-6.rgb",
                "karlie-oscars-2017.jpg-2.rgb",
                "karlie-oscars-2017.jpg-5.rgb.png",
                "karlie-oscars-2017.jpg-8.rgb",
                "karlie-oscars-2017.jpg-7.rgb",
                "karlie-oscars-2017.jpg-3.rgb",
                "karlie-oscars-2017.jpg-difference-0.rgb.png",
                "karlie-oscars-2017.jpg-difference-1.rgb.png",
                "karlie-oscars-2017.jpg-5.rgb",
                "karlie-oscars-2017.jpg-difference-7.rgb.png",
                "karlie-oscars-2017.jpg-8.rgb.png",
                "karlie-oscars-2017.jpg-6.rgb",
                "karlie-oscars-2017.jpg-9.rgb",
                "karlie-oscars-2017.jpg-difference-3.rgb.png",
                "karlie-oscars-2017.jpg-6.rgb.png",
                "karlie-oscars-2017.jpg-difference-9.rgb.png",
                "karlie-oscars-2017.jpg-difference-5.rgb.png",
                "karlie-oscars-2017.jpg-2.rgb.png",
                "karlie-oscars-2017.jpg-difference-0.rgb",
                "karlie-oscars-2017.jpg-difference-4.rgb.png",
                "karlie-oscars-2017.jpg-difference-4.rgb",
                "karlie-oscars-2017.jpg-1.rgb",
                "karlie-oscars-2017.jpg-difference-6.rgb.png",
                "karlie-oscars-2017.jpg-0.rgb",
                "karlie-oscars-2017.jpg-4.rgb",
                "karlie-oscars-2017.jpg",
                "karlie-oscars-2017.jpg-difference-2.rgb",
                "karlie-oscars-2017.jpg-4.rgb.png",
                "karlie-oscars-2017.jpg-1.rgb.png",
                "karlie-oscars-2017.jpg-difference-7.rgb",
                "karlie-oscars-2017.jpg-difference-8.rgb",
                "karlie-oscars-2017.jpg-difference-5.rgb",
                "karlie-oscars-2017.jpg-difference-2.rgb.png",
                "karlie-oscars-2017.jpg-3.rgb.png",
                "karlie-oscars-2017.jpg-7.rgb.png",
                "karlie-oscars-2017.jpg-0.rgb.png",
                "karlie-oscars-2017.jpg-difference-9.rgb",
                "karlie-oscars-2017.jpg-difference-3.rgb",
                "karlie-oscars-2017.jpg-difference-1.rgb",
            ]
        ),
        .executableTarget(name: "recompress",          dependencies: ["JPEG"], path: "examples/recompress",
            exclude:
            [
                "recompressed-requantized.jpg",
                "original.jpg",
                "recompressed-full-cycle.jpg",
            ]
        ),
        .executableTarget(name: "rotate",              dependencies: ["JPEG"], path: "examples/rotate",
            exclude:
            [
                "karlie-kwk-wwdc-2017.jpg",
                "karlie-kwk-wwdc-2017-iii.jpg",
                "karlie-kwk-wwdc-2017-ii.jpg",
                "karlie-kwk-wwdc-2017-iv.jpg",
            ]
        ),
        .executableTarget(name: "custom-color",        dependencies: ["JPEG"], path: "examples/custom-color",
            exclude:
            [
                "output.jpg",
                "output.jpg.rgb-16.png",
                "output.jpg.rgb-difference.png",
                "output.jpg.rgb-8.png",
                "output.jpg.rgb",
            ]
        ),
    ], 
    swiftLanguageVersions: [.v4_2, .v5]
)
