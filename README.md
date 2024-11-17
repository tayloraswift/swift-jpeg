<div align="center">

***`jpeg`***

[![Tests](https://github.com/tayloraswift/swift-jpeg/actions/workflows/Tests.yml/badge.svg)](https://github.com/tayloraswift/swift-jpeg/actions/workflows/Tests.yml)
[![Documentation](https://github.com/tayloraswift/swift-jpeg/actions/workflows/Documentation.yml/badge.svg)](https://github.com/tayloraswift/swift-jpeg/actions/workflows/Documentation.yml)

</div>


Swift *JPEG* is a cross-platform pure Swift framework for decoding, inspecting, editing, and encoding JPEG images. The core framework has no external dependencies, including *Foundation*, and should compile and provide consistent behavior on *all* Swift platforms. The framework supports additional features, such as file system support, on Linux and MacOS.

Swift *JPEG* is available under the [Mozilla Public License 2.0](https://www.mozilla.org/en-US/MPL/2.0/). The [example programs](Snippets/) are public domain and can be adapted freely.

<div align="center">

[documentation](https://swiftinit.org/docs/swift-jpeg/jpeg) ·
[license](LICENSE)

</div>


## Requirements

The swift-jpeg library requires Swift 5.10 or later.


| Platform | Status |
| -------- | ------ |
| 🐧 Linux | [![Tests](https://github.com/tayloraswift/swift-jpeg/actions/workflows/Tests.yml/badge.svg)](https://github.com/tayloraswift/swift-jpeg/actions/workflows/Tests.yml) |
| 🍏 Darwin | [![Tests](https://github.com/tayloraswift/swift-jpeg/actions/workflows/Tests.yml/badge.svg)](https://github.com/tayloraswift/swift-jpeg/actions/workflows/Tests.yml) |
| 🍏 Darwin (iOS) | [![iOS](https://github.com/tayloraswift/swift-jpeg/actions/workflows/iOS.yml/badge.svg)](https://github.com/tayloraswift/swift-jpeg/actions/workflows/iOS.yml) |
| 🍏 Darwin (tvOS) | [![tvOS](https://github.com/tayloraswift/swift-jpeg/actions/workflows/tvOS.yml/badge.svg)](https://github.com/tayloraswift/swift-jpeg/actions/workflows/tvOS.yml) |
| 🍏 Darwin (visionOS) | [![visionOS](https://github.com/tayloraswift/swift-jpeg/actions/workflows/visionOS.yml/badge.svg)](https://github.com/tayloraswift/swift-jpeg/actions/workflows/visionOS.yml) |
| 🍏 Darwin (watchOS) | [![watchOS](https://github.com/tayloraswift/swift-jpeg/actions/workflows/watchOS.yml/badge.svg)](https://github.com/tayloraswift/swift-jpeg/actions/workflows/watchOS.yml) |


[Check deployment minimums](https://swiftinit.org/docs/swift-jpeg#ss:platform-requirements)


## [tutorials and example programs](examples/)

* [basic decoding](examples#basic-decoding)
* [basic encoding](examples#basic-encoding)
* [advanced decoding](examples#advanced-decoding)
* [advanced encoding](examples#advanced-encoding)
* [using in-memory images](examples#using-in-memory-images)
* [online decoding](examples#online-decoding)
* [requantizing images](examples#requantizing-images)
* [lossless rotations](examples#lossless-rotations)
* [custom color formats](examples#custom-color-formats)

## [api reference](https://swiftinit.org/docs/swift-jpeg/jpeg/)

* [`JPEG.JPEG`](https://swiftinit.org/docs/swift-jpeg/jpeg/jpeg)
* [`JPEG.General`](https://swiftinit.org/docs/swift-jpeg/jpeg/general)
* [`JPEG.System`](https://swiftinit.org/docs/swift-jpeg/jpegsystem/system)

## getting started

To Swift *JPEG* in a project, add this descriptor to the `dependencies` list in your `Package.swift`:

```swift
.package(url: "https://github.com/tayloraswift/swift-jpeg", from: "2.0.0")
```

## basic usage

Decode an image:

```swift
import JPEG
func decode(jpeg path:String) throws
{
    guard let image:JPEG.Data.Rectangular<JPEG.Common> = try .decompress(path: path)
    else
    {
        // failed to access file from file system
    }

    let rgb:[JPEG.RGB]      = image.unpack(as: JPEG.RGB.self),
        size:(x:Int, y:Int) = image.size
    // ...
}
```

Encode an image:

```swift
import JPEG
func encode(jpeg path:String, size:(x:Int, y:Int), pixels:[JPEG.RGB],
    compression:Double) // 0.0 = highest quality
    throws
{
    let layout:JPEG.Layout<JPEG.Common> = .init(
        format:     .ycc8,
        process:    .baseline,
        components:
        [
            1: (factor: (2, 2), qi: 0), // Y
            2: (factor: (1, 1), qi: 1), // Cb
            3: (factor: (1, 1), qi: 1), // Cr
        ],
        scans:
        [
            .sequential((1, \.0, \.0), (2, \.1, \.1), (3, \.1, \.1)),
        ])
    let jfif:JPEG.JFIF = .init(version: .v1_2, density: (72, 72, .inches))
    let image:JPEG.Data.Rectangular<JPEG.Common> =
        .pack(size: size, layout: layout, metadata: [.jfif(jfif)], pixels: rgb)

    try image.compress(path: path, quanta:
    [
        0: JPEG.CompressionLevel.luminance(  compression).quanta,
        1: JPEG.CompressionLevel.chrominance(compression).quanta
    ])
}
```
