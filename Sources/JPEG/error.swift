/* This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/. */

extension JPEG
{
    /// Functionality common to all library error types.
    public
    protocol Error:Swift.Error
    {
        /// The human-readable namespace for errors of this type.
        static
        var namespace:String
        {
            get
        }
        /// A basic description of this error instance.
        var message:String
        {
            get
        }
        /// A detailed description of this error instance, if available.
        var details:String?
        {
            get
        }
    }

    /// A lexing error.
    public
    enum LexingError:JPEG.Error
    {
        /// The lexer encountered end-of-stream while lexing a marker
        /// segment type indicator.
        case truncatedMarkerSegmentType
        /// The lexer encountered end-of-stream while lexing a marker
        /// segment length field.
        case truncatedMarkerSegmentHeader
        /// The lexer encountered end-of-stream while lexing a marker
        /// segment body.
        ///
        /// -   Parameter expected:
        ///     The number of bytes the lexer was expecting to read.
        case truncatedMarkerSegmentBody(expected:Int)
        /// The lexer encountered end-of-stream while lexing an entropy-coded
        /// segment, usually because it was expecting a subsequent marker segment.
        case truncatedEntropyCodedSegment
        /// The lexer read a marker segment length field, but the value did
        /// not make sense.
        ///
        /// -   Parameter _:
        ///     The value that the lexer read from the marker segment length field.
        case invalidMarkerSegmentLength(Int)
        /// The lexer encountered a prefixed entropy-coded segment where it
        /// was expecting none.
        ///
        /// -   Parameter _:
        ///     The first invalid byte encountered by the lexer.
        case invalidMarkerSegmentPrefix(UInt8)
        /// The lexer encountered a marker segment with a reserved type indicator
        /// code.
        ///
        /// -   Parameter _:
        ///     The invalid type indicator code encountered by the lexer.
        case invalidMarkerSegmentType(UInt8)
        /// Returns the string `"lexing error"`.
        public static
        var namespace:String
        {
            "lexing error"
        }
        /// Returns a basic description of this lexing error.
        public
        var message:String
        {
            switch self
            {
            case .truncatedMarkerSegmentType:
                return "truncated marker segment type"
            case .truncatedMarkerSegmentHeader:
                return "truncated marker segment header"
            case .truncatedMarkerSegmentBody:
                return "truncated marker segment body"
            case .truncatedEntropyCodedSegment:
                return "truncated entropy coded segment"

            case .invalidMarkerSegmentLength:
                return "invalid value in marker segment length field"
            case .invalidMarkerSegmentPrefix:
                return "invalid marker segment prefix"
            case .invalidMarkerSegmentType:
                return "invalid marker segment type code"
            }
        }
        /// Returns a detailed description of this lexing error, if available.
        public
        var details:String?
        {
            switch self
            {
            case .truncatedMarkerSegmentType:
                return "unexpected end-of-stream while lexing marker segment type field"
            case .truncatedMarkerSegmentHeader:
                return "unexpected end-of-stream while lexing marker segment length field"
            case .truncatedMarkerSegmentBody(expected: let expected):
                return "unexpected end-of-stream while lexing marker segment body (expected \(expected) bytes)"
            case .truncatedEntropyCodedSegment:
                return "unexpected end-of-stream while lexing entropy coded segment"

            case .invalidMarkerSegmentLength(let length):
                return "value of marker segment length field (\(length)) cannot be less than 2"
            case .invalidMarkerSegmentPrefix(let byte):
                return "padding byte (0x\(String.init(byte, radix: 16))) preceeding marker segment must be 0xff"
            case .invalidMarkerSegmentType(let code):
                return "marker segment type code (0x\(String.init(code, radix: 16))) is a reserved marker code"
            }
        }
    }
    /// A parsing error.
    public
    enum ParsingError:JPEG.Error
    {
        /// A marker segment contained less than the expected amount of data.
        ///
        /// -   Parameter type:
        ///     The marker segment type.
        ///
        /// -   Parameter size:
        ///     The size of the marker segment, in bytes.
        ///
        /// -   Parameter expected:
        ///     The range of marker segment sizes that was expected, in bytes.
        case truncatedMarkerSegmentBody(Marker, Int, expected:ClosedRange<Int>)
        /// A marker segment contained more than the expected amount of data.
        ///
        /// -   Parameter type:
        ///     The marker segment type.
        ///
        /// -   Parameter size:
        ///     The size of the marker segment, in bytes.
        ///
        /// -   Parameter expected:
        ///     The amount of data that was expected, in bytes.
        case extraneousMarkerSegmentData(Marker, Int, expected:Int)
        /// A JFIF segment had an invalid signature.
        ///
        /// -   Parameter _:
        ///     The signature read from the segment.
        case invalidJFIFSignature([UInt8])
        /// A JFIF segment had an invalid version code.
        ///
        /// -   Parameter _:
        ///     The version code read from the segment.
        case invalidJFIFVersionCode((major:UInt8, minor:UInt8))
        /// A JFIF segment had an invalid density unit code.
        ///
        /// -   Parameter _:
        ///     The density unit code read from the segment.
        case invalidJFIFDensityUnitCode(UInt8)
        /// An EXIF segment had an invalid signature.
        ///
        /// -   Parameter _:
        ///     The signature read from the segment.
        case invalidEXIFSignature([UInt8])
        /// An EXIF segment had an invalid endianness specifier.
        ///
        /// -   Parameter _:
        ///     The endianness specifier read from the segment.
        case invalidEXIFEndiannessCode((UInt8, UInt8, UInt8, UInt8))

        /// A frame header segment had a negative or zero width field.
        ///
        /// -   Parameter _:
        ///     The value of the width field read from the segment.
        case invalidFrameWidth(Int)
        /// A frame header segment had an invalid precision field.
        ///
        /// -   Parameter value:
        ///     The value of the precision field read from the segment.
        ///
        /// -   Parameter process:
        ///     The coding process specified by the frame header.
        case invalidFramePrecision(Int, Process)
        /// A frame header segment had an invalid number of components.
        ///
        /// -   Parameter value:
        ///     The number of components in the segment.
        ///
        /// -   Parameter process:
        ///     The coding process specified by the frame header.
        case invalidFrameComponentCount(Int, Process)
        /// A component in a frame header segment had an invalid quantization
        /// table selector code.
        ///
        /// -   Parameter _:
        ///     The selector code read from the segment.
        case invalidFrameQuantizationSelectorCode(UInt8)
        /// A component in a frame header segment used a quantization table
        /// selector which is well-formed but unavailable given the frame header coding process.
        ///
        /// -   Parameter value:
        ///     The quantization table selector.
        ///
        /// -   Parameter process:
        ///     The coding process specified by the frame header.
        case invalidFrameQuantizationSelector(JPEG.Table.Quantization.Selector, Process)
        /// A component in a frame header had an invalid sampling factor.
        ///
        /// Sampling factors must be within the range `1 ... 4`.
        ///
        /// -   Parameter value:
        ///     The sampling factor of the component.
        ///
        /// -   Parameter key:
        ///     The component key.
        case invalidFrameComponentSamplingFactor((x:Int, y:Int), Component.Key)
        /// The same component key occurred more than once in the same frame header.
        ///
        /// -   Parameter _:
        ///     The duplicated component key.
        case duplicateFrameComponentIndex(Component.Key)

        /// A component in a frame header segment had an invalid quantization
        /// table selector code.
        ///
        /// -   Parameter _:
        ///     The selector code read from the segment.
        case invalidScanHuffmanSelectorCode(UInt8)
        /// A component in a frame header segment used a DC huffman table
        /// selector which is well-formed but unavailable given the frame header coding process.
        ///
        /// -   Parameter value:
        ///     The huffman table selector.
        ///
        /// -   Parameter process:
        ///     The coding process specified by the frame header.
        case invalidScanHuffmanDCSelector(JPEG.Table.HuffmanDC.Selector, Process)
        /// A component in a frame header segment used an AC huffman table
        /// selector which is well-formed but unavailable given the frame header coding process.
        ///
        /// -   Parameter value:
        ///     The huffman table selector.
        ///
        /// -   Parameter process:
        ///     The coding process specified by the frame header.
        case invalidScanHuffmanACSelector(JPEG.Table.HuffmanAC.Selector, Process)
        /// A scan header had more that the maximum allowed number of components
        /// given the image coding process.
        ///
        /// -   Parameter value:
        ///     The number of components in the scan header.
        ///
        /// -   Parameter process:
        ///     The coding process used by the image.
        case invalidScanComponentCount(Int, Process)
        /// A scan header specified an invalid progressive frequency band
        /// or bit range given the image coding process.
        ///
        /// -   Parameter band:
        ///     The lower and upper bounds of the frequency band read from the scan header.
        ///
        /// -   Parameter bits:
        ///     The lower and upper bounds of the bit range read from the scan header.
        ///
        /// -   Parameter process:
        ///     The coding process used by the image.
        case invalidScanProgressiveSubset(band:(Int, Int), bits:(Int, Int), Process)

        /// A huffman table definition had an invalid huffman table
        /// selector code.
        ///
        /// -   Parameter _:
        ///     The selector code read from the segment.
        case invalidHuffmanTargetCode(UInt8)
        /// A huffman table definition had an invalid type indicator code.
        ///
        /// -   Parameter _:
        ///     The type indicator code read from the segment.
        case invalidHuffmanTypeCode(UInt8)
        /// A huffman table definition did not define a valid binary tree.
        case invalidHuffmanTable

        /// A quantization table definition had an invalid quantization table
        /// selector code.
        ///
        /// -   Parameter _:
        ///     The selector code read from the segment.
        case invalidQuantizationTargetCode(UInt8)
        /// A quantization table definition had an invalid precision indicator code.
        ///
        /// -   Parameter _:
        ///     The precision indicator code read from the segment.
        case invalidQuantizationPrecisionCode(UInt8)

        static
        func mismatched(marker:Marker, count:Int, minimum:Int) -> Self
        {
            .truncatedMarkerSegmentBody(marker, count, expected: minimum ... .max)
        }
        static
        func mismatched(marker:Marker, count:Int, expected:Int) -> Self
        {
            if count < expected
            {
                return .truncatedMarkerSegmentBody(marker, count, expected: expected ... expected)
            }
            else
            {
                return .extraneousMarkerSegmentData(marker, count, expected: expected)
            }
        }
        /// Returns the string `"parsing error"`.
        public static
        var namespace:String
        {
            "parsing error"
        }
        /// Returns a basic description of this parsing error.
        public
        var message:String
        {
            switch self
            {
            case .truncatedMarkerSegmentBody:
                return "truncated marker segment body"
            case .extraneousMarkerSegmentData:
                return "extraneous data in marker segment body"

            case .invalidJFIFSignature:
                return "invalid JFIF signature"
            case .invalidJFIFVersionCode:
                return "invalid JFIF version"
            case .invalidJFIFDensityUnitCode:
                return "invalid JFIF density unit"

            case .invalidEXIFSignature:
                return "invalid EXIF signature"
            case .invalidEXIFEndiannessCode:
                return "invalid EXIF endianness code"

            case .invalidFrameWidth:
                return "invalid frame width"
            case .invalidFramePrecision:
                return "invalid precision specifier"
            case .invalidFrameComponentCount:
                return "invalid total component count"
            case .invalidFrameQuantizationSelectorCode:
                return "invalid quantization table selector code"
            case .invalidFrameQuantizationSelector:
                return "invalid quantization table selector"
            case .invalidFrameComponentSamplingFactor:
                return "invalid component sampling factors"
            case .duplicateFrameComponentIndex:
                return "duplicate component indices"

            case .invalidScanHuffmanSelectorCode:
                return "invalid huffman table selector pair code"
            case .invalidScanHuffmanDCSelector:
                return "invalid dc huffman table selector"
            case .invalidScanHuffmanACSelector:
                return "invalid ac huffman table selector"
            case .invalidScanComponentCount:
                return "invalid scan component count"
            case .invalidScanProgressiveSubset:
                return "invalid spectral selection or successive approximation"

            case .invalidHuffmanTargetCode:
                return "invalid huffman table destination"
            case .invalidHuffmanTypeCode:
                return "invalid huffman table type specifier"
            case .invalidHuffmanTable:
                return "malformed huffman table"

            case .invalidQuantizationTargetCode:
                return "invalid quantization table destination"
            case .invalidQuantizationPrecisionCode:
                return "invalid quantization table precision specifier"
            }
        }
        /// Returns a detailed description of this parsing error, if available.
        public
        var details:String?
        {
            switch self
            {
            case .truncatedMarkerSegmentBody(let marker, let count, expected: let expected):
                if expected.count == 1
                {
                    return "\(marker) segment (\(count) bytes) must be exactly \(expected.lowerBound) bytes long"
                }
                else
                {
                    return "\(marker) segment (\(count) bytes) must be at least \(expected.lowerBound) bytes long"
                }
            case .extraneousMarkerSegmentData(let marker, let count, expected: let expected):
                return "\(marker) segment (\(count) bytes) must be exactly \(expected) bytes long"

            case .invalidJFIFSignature(let string):
                return "string (\(string.map{ "0x\(String.init($0, radix: 16))" }.joined(separator: ", "))) is not a valid JFIF signature"
            case .invalidJFIFVersionCode(let (major, minor)):
                return "version (\(major).\(minor)) must be within 1.0 ... 1.2"
            case .invalidJFIFDensityUnitCode(let code):
                return "density code (\(code)) does not correspond to a valid density unit"

            case .invalidEXIFSignature(let string):
                return "string (\(string.map{ "0x\(String.init($0, radix: 16))" }.joined(separator: ", "))) is not a valid EXIF signature"
            case .invalidEXIFEndiannessCode(let code):
                return "endianness code (\(code.0), \(code.1), \(code.2), \(code.3)) does not correspond to a valid EXIF endianness"

            case .invalidFrameWidth(let width):
                return "frame cannot have width \(width)"
            case .invalidFramePrecision(let precision, let process):
                return "precision (\(precision)) is not allowed for frame coding process '\(process)'"
            case .invalidFrameComponentCount(let count, let process):
                if count == 0
                {
                    return "frame must have at least one component"
                }
                else
                {
                    return "frame (\(count) components) with coding process '\(process)' has disallowed component count"
                }
            case .invalidFrameQuantizationSelectorCode(let code):
                return "quantization table selector code (\(code)) must be within 0 ... 3"
            case .invalidFrameQuantizationSelector(let selector, let process):
                return "quantization table selector (\(String.init(selector: selector))) is not allowed for coding process '\(process)'"
            case .invalidFrameComponentSamplingFactor(let factor, let ci):
                return "both sampling factors (\(factor.x), \(factor.y)) for component index \(ci) must be within 1 ... 4"
            case .duplicateFrameComponentIndex(let ci):
                return "component index (\(ci)) conflicts with previously defined component"

            case .invalidScanHuffmanSelectorCode(let code):
                return "huffman table selector pair code (\(code)) must be within 0 ... 3 or 16 ... 19"
            case .invalidScanHuffmanDCSelector(let selector, let process):
                return "dc huffman table selector (\(String.init(selector: selector))) is not allowed for coding process '\(process)'"
            case .invalidScanHuffmanACSelector(let selector, let process):
                return "ac huffman table selector (\(String.init(selector: selector))) is not allowed for coding process '\(process)'"
            case .invalidScanComponentCount(let count, let process):
                if count == 0
                {
                    return "scan must contain at least one component"
                }
                else
                {
                    return "scan component count (\(count)) is not allowed for coding process '\(process)'"
                }
            case .invalidScanProgressiveSubset(band: let band, bits: let bits, let process):
                return "scan cannot define spectral selection (\(band.0) ..< \(band.1)) with successive approximation (\(bits.0) ..< \(bits.1)) for coding process '\(process)'"

            case .invalidHuffmanTargetCode(let code):
                return "selector code (0x\(String.init(code, radix: 16))) does not correspond to a valid huffman table destination"
            case .invalidHuffmanTypeCode(let code):
                return "code (\(code)) does not correspond to a valid huffman table type"
            case .invalidHuffmanTable:
                return nil

            case .invalidQuantizationTargetCode(let code):
                return "selector code (0x\(String.init(code, radix: 16))) does not correspond to a valid quantization table destination"
            case .invalidQuantizationPrecisionCode(let code):
                return "code (\(code)) does not correspond to a valid quantization table precision"
            }
        }
    }
    /// A decoding error.
    public
    enum DecodingError:JPEG.Error
    {
        /// An entropy-coded segment contained less than the expected amount of data.
        case truncatedEntropyCodedSegment

        /// A restart marker appeared out-of-phase.
        ///
        /// Restart markers should cycle from 0 to 7, in that order.
        ///
        /// -   Parameter _:
        ///     The phase read from the restart marker.
        ///
        /// -   Parameter expected:
        ///     The expected phase, which is one greater than the phase of the
        ///     last-encountered restart marker (modulo 8), or 0 if this is the
        ///     first restart marker in the entropy-coded segment.
        case invalidRestartPhase(Int, expected:Int)
        /// A restart marker appeared, but no restart interval was ever defined,
        /// or restart markers were disabled.
        case missingRestartIntervalSegment

        /// The first scan for a component encoded a frequency band that
        /// did not include the DC coefficient.
        ///
        /// -   Parameter value:
        ///     The frequency band encoded by the scan.
        ///
        /// -   Parameter key:
        ///     The component key of the invalidated color channel.
        case invalidSpectralSelectionProgression(Range<Int>, Component.Key)
        /// A scan did not follow the correct successive approximation sequence
        /// for at least one frequency coefficient.
        ///
        /// Successive approximation must refine bits starting from the most-significant
        /// and going towards the least-significant, only the initial scan
        /// for each coefficient can encode more than one bit at a time.
        ///
        /// -   Parameter bits:
        ///     The bit range encoded by the scan.
        ///
        /// -   Parameter bit:
        ///     The index of the least-significant bit encoded so far for the coefficient `z`.
        ///
        /// -   Parameter z:
        ///     The zigzag index of the coefficient.
        ///
        /// -   Parameter key:
        ///     The component key of the invalidated color channel.
        case invalidSuccessiveApproximationProgression(Range<Int>, Int, z:Int, Component.Key)

        /// The decoder decoded an out-of-range composite value.
        ///
        /// This error occurs when a refining AC scan encodes any composite
        /// value that is not –1, 0, or +1, because refining scans can only
        /// refine one bit at a time.
        ///
        /// -   Parameter _:
        ///     The decoded composite value.
        ///
        /// -   Parameter expected:
        ///     The expected range for the composite value.
        case invalidCompositeValue(Int16, expected:ClosedRange<Int>)
        /// The decoder decoded an out-of-range end-of-band/end-of-block run count.
        ///
        /// This error occurs when a sequential scan tries to encode an end-of-band
        /// run, which is a progressive coding process concept only. Sequential
        /// scans can only end-of-block runs of length 1.
        ///
        /// -   Parameter _:
        ///     The decoded end-of-band/end-of-block run count.
        ///
        /// -   Parameter expected:
        ///     The expected range for the end-of-band/end-of-block run count.
        case invalidCompositeBlockRun(Int, expected:ClosedRange<Int>)

        /// A scan encoded a component with a key that was not one of the
        /// resident components declared in the frame header.
        ///
        /// -   Parameter _:
        ///     The undefined component key.
        ///
        /// -   Parameter keys:
        ///     The set of defined resident component keys.
        case undefinedScanComponentReference(Component.Key, Set<Component.Key>)
        /// An interleaved scan had a total component sampling volume greater
        /// than 10.
        ///
        /// The total sampling volume is the sum of the products of the sampling
        /// factors of each component encoded by the scan.
        ///
        /// -   Parameter _:
        ///     The total sampling volume of the scan components.
        case invalidScanSamplingVolume(Int)
        /// A DC huffman table selector in a scan referenced a table
        /// slot with no bound table.
        ///
        /// -   Parameter _:
        ///     The table selector.
        case undefinedScanHuffmanDCReference(Table.HuffmanDC.Selector)
        /// An AC huffman table selector in a scan referenced a table
        /// slot with no bound table.
        ///
        /// -   Parameter _:
        ///     The table selector.
        case undefinedScanHuffmanACReference(Table.HuffmanAC.Selector)
        /// A quantization table selector in the first scan for a particular
        /// component referenced a table slot with no bound table.
        ///
        /// -   Parameter _:
        ///     The table selector.
        case undefinedScanQuantizationReference(Table.Quantization.Selector)
        /// A quantization table had the wrong precision mode for the image
        /// color format.
        ///
        /// Only images with a bit depth greater than 8 should use a 16-bit
        /// quantization table.
        ///
        /// -   Parameter _:
        ///     The precision mode of the quantization table.
        case invalidScanQuantizationPrecision(Table.Quantization.Precision)

        /// The first marker segment in the image was not a start-of-image marker.
        ///
        /// -   Parameter _:
        ///     The type indicator of the first encountered marker segment.
        case missingStartOfImage(Marker)
        /// The decoder encountered more than one start-of-image marker.
        case duplicateStartOfImage
        /// The decoder encountered more than one frame header segment.
        ///
        /// JPEG files using the hierarchical coding process can encode more
        /// than one frame header. However, this coding process is not currently
        /// supported.
        case duplicateFrameHeaderSegment
        /// The decoder encountered a scan header segment before a frame header
        /// segment.
        case prematureScanHeaderSegment
        /// The decoder did not encounter the height redefinition segment that
        /// must follow the first scan of an image with a declared height of 0.
        case missingHeightRedefinitionSegment
        /// The decoder encountered a height redefinition segment before the
        /// first image scan.
        case prematureHeightRedefinitionSegment
        /// The decoder encountered a height redefinition segment after, but
        /// not immediately after the first image scan.
        case unexpectedHeightRedefinitionSegment
        /// The decoder encountered a restart marker outside of an entropy-coded
        /// segment.
        case unexpectedRestart
        /// The decoder encountered an end-of-image marker before encountering
        /// a frame header segment.
        case prematureEndOfImage

        /// The image coding process was anything other than
        /// ``Process/baseline``, or ``Process/extended(coding:differential:)``
        /// and ``Process/progressive(coding:differential:)`` with ``Process.Coding/huffman``
        /// coding and `differential` set to `false`.
        ///
        /// -   Parameter _:
        ///     The coding process used by the image.
        case unsupportedFrameCodingProcess(Process)
        /// A ``Format/recognize(_:precision:)`` implementation failed to
        /// recognize the component set and bit precision in a frame header.
        ///
        /// -   Parameter components:
        ///     The set of resident component keys read from the frame header.
        ///
        /// -   Parameter precision:
        ///     The bit precision read from the frame header.
        ///
        /// -   Parameter format:
        ///     The ``Format`` type that tried to detect the color format.
        case unrecognizedColorFormat(Set<Component.Key>, Int, Any.Type)

        /// Returns the string `"decoding error"`.
        public static
        var namespace:String
        {
            "decoding error"
        }
        /// Returns a basic description of this decoding error.
        public
        var message:String
        {
            switch self
            {
            case .truncatedEntropyCodedSegment:
                return "truncated entropy coded segment bitstream"

            case .invalidSpectralSelectionProgression:
                return "invalid spectral selection progression"
            case .invalidSuccessiveApproximationProgression:
                return "invalid successive approximation progression"

            case .invalidRestartPhase:
                return "invalid restart phase"
            case .missingRestartIntervalSegment:
                return "missing restart interval segment"

            case .invalidCompositeValue:
                return "invalid composite value"
            case .invalidCompositeBlockRun:
                return "invalid composite end-of-band run length"

            case .undefinedScanComponentReference:
                return "undefined component reference"
            case .invalidScanSamplingVolume:
                return "invalid scan component sampling volume"
            case .undefinedScanHuffmanDCReference:
                return "undefined dc huffman table reference"
            case .undefinedScanHuffmanACReference:
                return "undefined ac huffman table reference"
            case .undefinedScanQuantizationReference:
                return "undefined quantization table reference"
            case .invalidScanQuantizationPrecision:
                return "quantization table precision mismatch"

            case .missingStartOfImage:
                return "missing start-of-image marker"
            case .duplicateStartOfImage:
                return "duplicate start-of-image marker"
            case .duplicateFrameHeaderSegment:
                return "duplicate frame header segment"
            case .prematureScanHeaderSegment:
                return "premature scan header segment"
            case .missingHeightRedefinitionSegment:
                return "missing height redefinition segment"
            case .prematureHeightRedefinitionSegment:
                return "premature height redefinition segment"
            case .unexpectedHeightRedefinitionSegment:
                return "unexpected height redefinition segment"
            case .unexpectedRestart:
                return "unexpected restart marker"
            case .prematureEndOfImage:
                return "premature end-of-image marker"

            case .unsupportedFrameCodingProcess:
                return "unsupported encoding process"
            case .unrecognizedColorFormat:
                return "unrecognized color format"
            }
        }
        /// Returns a detailed description of this decoding error, if available.
        public
        var details:String?
        {
            switch self
            {
            case .truncatedEntropyCodedSegment:
                return "not enough data in entropy coded segment bitstream"

            case .invalidRestartPhase(let phase, expected: let expected):
                return "decoded restart phase (\(phase)) is not the expected phase (\(expected))"
            case .missingRestartIntervalSegment:
                return "encountered restart segments, but no restart interval has been defined"

            case .invalidSpectralSelectionProgression(let band, let ci):
                return "frequency band \(band.lowerBound) ..< \(band.upperBound) for component \(ci) is not allowed"
            case .invalidSuccessiveApproximationProgression(let bits, let a, z: let z, let ci):
                return "bits \(bits.lowerBound)\(bits.upperBound == .max ? "..." : " \(bits.upperBound)") for component \(ci) cannot refine bit \(a) of coefficient \(z)"

            case .invalidCompositeValue(let value, expected: let expected):
                return "magnitude-tail encoded value (\(value)) must be within \(expected.lowerBound) ... \(expected.upperBound)"
            case .invalidCompositeBlockRun(let value, expected: let expected):
                return "magnitude-tail encoded end-of-band run length (\(value)) must be within \(expected.lowerBound) ... \(expected.upperBound)"

            case .undefinedScanComponentReference(let ci, let defined):
                return "component with index (\(ci)) is not one of the components \(defined.sorted()) defined in frame header"
            case .invalidScanSamplingVolume(let volume):
                return "scan mcu sample volume (\(volume)) can be at most 10"
            case .undefinedScanHuffmanDCReference(let selector):
                return "no dc huffman table has been installed at the location <\(String.init(selector: selector))>"
            case .undefinedScanHuffmanACReference(let selector):
                return "no ac huffman table has been installed at the location <\(String.init(selector: selector))>"
            case .undefinedScanQuantizationReference(let selector):
                return "no quantization table has been installed at the location <\(String.init(selector: selector))>"
            case .invalidScanQuantizationPrecision(let precision):
                return "quantization table has invalid integer type (\(precision))"

            case .missingStartOfImage:
                return "start-of-image marker must be the first marker in image"
            case .duplicateStartOfImage:
                return "start-of-image marker cannot occur more than once"
            case .duplicateFrameHeaderSegment:
                return "multiple frame headers only allowed for the hierarchical coding process"
            case .prematureScanHeaderSegment:
                return "scan header must occur after frame header"
            case .missingHeightRedefinitionSegment:
                return "define height segment must occur immediately after first scan"
            case .prematureHeightRedefinitionSegment, .unexpectedHeightRedefinitionSegment:
                return "define height segment can only occur immediately after first scan"
            case .unexpectedRestart:
                return "restart marker can only follow an entropy-coded segment"
            case .prematureEndOfImage:
                return "premature end-of-image marker"

            case .unsupportedFrameCodingProcess(let process):
                return "frame coding process (\(process)) is not supported"
            case .unrecognizedColorFormat(let components, let precision, let type):
                return "color format type (\(type)) could not match component identifier set \(components.sorted()) with precision \(precision) to a known value"
            }
        }
    }
}

extension JPEG
{
    /// A formatting error.
    public
    enum FormattingError:JPEG.Error
    {
        /// The formatter could not write data to its destination stream.
        case invalidDestination
        /// Returns the string `"formatting error"`.
        public static
        var namespace:String
        {
            "formatting error"
        }
        /// Returns a basic description of this formatting error.
        public
        var message:String
        {
            switch self
            {
            case .invalidDestination:
                return "failed to write to destination"
            }
        }
        /// Returns a detailed description of this formatting error, if available.
        public
        var details:String?
        {
            switch self
            {
            case .invalidDestination:
                return nil
            }
        }
    }
    /// A serializing error.
    ///
    /// This enumeration currently has no cases.
    public
    enum SerializingError:JPEG.Error
    {
        /// Returns the string `"serializing error"`.
        public static
        var namespace:String
        {
            "serializing error"
        }
        /// Returns a basic description of this serializing error.
        public
        var message:String
        {
            switch self
            {
            }
        }
        /// Returns a detailed description of this serializing error, if available.
        public
        var details:String?
        {
            switch self
            {
            }
        }
    }
    /// An encoding error.
    ///
    /// This enumeration currently has no cases.
    public
    enum EncodingError:JPEG.Error
    {
        /// Returns the string `"encoding error"`.
        public static
        var namespace:String
        {
            "encoding error"
        }
        /// Returns a basic description of this encoding error.
        public
        var message:String
        {
            switch self
            {
            }
        }
        /// Returns a detailed description of this encoding error, if available.
        public
        var details:String?
        {
            switch self
            {
            }
        }
    }
}
