/* This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/. */

extension JPEG
{
    /// A JFIF metadata record.
    public
    struct JFIF
    {
        /// A unit of measurement.
        public
        enum Unit
        {
            /// The unit is inches.
            case inches
            /// The unit is centimeters.
            case centimeters
        }
        /// A version of the [JFIF standard](https://www.w3.org/Graphics/JPEG/jfif3.pdf).
        public
        enum Version
        {
            /// JFIF version 1.0.
            case v1_0

            /// JFIF version 1.1.
            case v1_1

            /// JFIF version 1.2.
            case v1_2
        }

        /// The JFIF version of this metadata record.
        public
        let version:Version
        /// The sampling density of the image.
        ///
        /// The `x` and `y` fields specify the number of physical samples along
        /// each dimension per `unit` length. For example, the value
        /// `(x: 72, y: 72, unit: ```Unit.inches```)` indicates a density of 72\ dpi.
        /// If the `unit` field is `nil`, the units are unknown.
        public
        let density:(x:Int, y:Int, unit:Unit?)

        // initializer has to live here due to compiler issue

        /// Creates a metadata record.
        ///
        /// -   Parameter version:
        ///     The JFIF version of the metadata record.
        ///
        /// -   Parameter density:
        ///     The sampling density of the image.
        public
        init(version:Version, density:(x:Int, y:Int, unit:Unit?))
        {
            self.version = version
            self.density = density
        }
    }
    /// An EXIF metadata record.
    ///
    /// This type will index the root, *EXIF* (tag 34665), and *GPS* (tag 34853)
    /// field groups, if they are present and well-linked in the record.
    ///
    /// This framework only supports basic field retrieval from EXIF data.
    /// It does not support constructing or editing EXIF records. Because this metadata format
    /// relies extensively on internal file pointers, it is easy to accidentally
    /// corrupt an EXIF segment. To perform more sophisticated operations,
    /// use a dedicated library, such as [Carpaccio](https://github.com/mz2/Carpaccio).
    public
    struct EXIF
    {
        /// An endianness mode.
        public
        enum Endianness
        {
            /// Multibyte integers are stored most-significant-byte first.
            ///
            /// For historical reasons, the [EXIF standard](https://www.exif.org/Exif2-2.PDF)
            /// refers to this mode as *motorola byte order*.
            case bigEndian
            /// Multibyte integers are stored least-significant-byte first.
            ///
            /// For historical reasons, the [EXIF standard](https://www.exif.org/Exif2-2.PDF)
            /// refers to this mode as *intel byte order*.
            case littleEndian
        }

        /// A variant field type.
        public
        enum FieldType
        {
            /// A ``Unicode.ASCII.CodeUnit`` field.
            case ascii
            /// A ``UInt8`` field.
            ///
            /// The [EXIF standard](https://www.exif.org/Exif2-2.PDF)
            /// refers to this variant type as a *byte*.
            case uint8
            /// A ``UInt16`` field.
            ///
            /// The [EXIF standard](https://www.exif.org/Exif2-2.PDF)
            /// refers to this variant type as a *short*.
            case uint16
            /// A ``UInt32`` field.
            ///
            /// The [EXIF standard](https://www.exif.org/Exif2-2.PDF)
            /// refers to this variant type as a *long*.
            case uint32
            /// An ``Int32`` field.
            ///
            /// The [EXIF standard](https://www.exif.org/Exif2-2.PDF)
            /// refers to this variant type as a *slong*.
            case int32
            /// An unsigned fraction field, represented as two ``UInt32``s.
            ///
            /// The [EXIF standard](https://www.exif.org/Exif2-2.PDF)
            /// refers to this variant type as a *rational*.
            case urational
            /// A signed fraction field, represented as two ``Int32``s.
            ///
            /// The [EXIF standard](https://www.exif.org/Exif2-2.PDF)
            /// refers to this variant type as a *srational*.
            case rational
            /// A raw byte.
            ///
            /// The [EXIF standard](https://www.exif.org/Exif2-2.PDF)
            /// refers to this variant type as an *undefined*.
            case raw

            /// A field of unknown type.
            ///
            /// -   Parameter code:
            ///     The type indicator code.
            case other(code:UInt16)
        }
        /// An abstracted field value.
        ///
        /// Depending on the size of the field data, the field value may either
        /// be stored inline within this instance, or be stored indirectly
        /// elsewhere in the mantle of this metadata segment.
        public
        struct Box
        {
            /// The contents of this field box.
            ///
            /// Depending on the field, the four bytes that make up this property
            /// may encode the field value directly, or encode a 32-bit internal
            /// file address pointing to the field value.
            public
            let contents:(UInt8, UInt8, UInt8, UInt8)
            /// The byte order of the contents of this field box.
            ///
            /// This is always the same as the byte order of the entire metadata record.
            public
            let endianness:Endianness

            /// The contents of this field box, interpreted as a 32-bit internal
            /// file pointer, and extended to the width of an ``Int``.
            public
            var asOffset:Int
            {
                switch self.endianness
                {
                case .littleEndian:
                    return  .init(contents.3) << 24 |
                            .init(contents.2) << 24 |
                            .init(contents.1) << 24 |
                            .init(contents.0)
                case .bigEndian:
                    return  .init(contents.0) << 24 |
                            .init(contents.1) << 24 |
                            .init(contents.2) << 24 |
                            .init(contents.3)
                }
            }
            /// Creates a field box instance.
            ///
            /// -   Parameter b0:
            ///     The zeroth content byte. Depending on the `endianness`, this
            ///     is either the most- or least-significant byte.
            ///
            /// -   Parameter b1:
            ///     The first content byte.
            ///
            /// -   Parameter b2:
            ///     The second content byte.
            ///
            /// -   Parameter b3:
            ///     The third content byte. Depending on the `endianness`, this
            ///     is either the least- or most-significant byte.
            ///
            /// -   Parameter endianness:
            ///     The byte order of the content bytes.
            public
            init(_ b0:UInt8, _ b1:UInt8, _ b2:UInt8, _ b3:UInt8, endianness:Endianness)
            {
                self.contents   = (b0, b1, b2, b3)
                self.endianness = endianness
            }
        }

        /// The byte order of this metadata record.
        public
        let endianness:Endianness
        /// The index of tags and fields defined in this metadata record.
        ///
        /// The tag codes are listed in the [EXIF standard](https://www.exif.org/Exif2-2.PDF).
        /// The dictionary values are internal file pointers that can be
        /// dereferenced manually from the ``storage``; alternatively, the
        /// ``subscript(tag:)`` subscript can perform both the lookup and the dereferencing
        /// in one step.
        public private(set)
        var tags:[UInt16: Int]
        /// The raw contents of this metadata record.
        ///
        /// A file pointer with a value of 0 points to the beginning of this
        /// array.
        public private(set)
        var storage:[UInt8]
    }
}

// jfif segment parsing
extension JPEG.JFIF.Version
{
    static
    func parse(code:(UInt8, UInt8)) -> Self?
    {
        switch (major: code.0, minor: code.1)
        {
        case (major: 1, minor: 0):
            return .v1_0
        case (major: 1, minor: 1):
            return .v1_1
        case (major: 1, minor: 2):
            return .v1_2
        default:
            return nil
        }
    }
}
extension JPEG.JFIF.Unit
{
    static
    func parse(code:UInt8) -> Self??
    {
        switch code
        {
        case 0:
            return .some(nil)
        case 1:
            return .inches
        case 2:
            return .centimeters
        default:
            return nil
        }
    }
}
extension JPEG.JFIF
{
    static
    let signature:[UInt8] = [0x4a, 0x46, 0x49, 0x46, 0x00]
    /// Parses a JFIF segment into a metadata record.
    ///
    /// If the given data does not parse to a valid metadata record,
    /// this function will throw a ``JPEG/ParsingError``.
    ///
    /// This parser ignores embedded thumbnails.
    ///
    /// -   Parameter data:
    ///     The segment data to parse.
    ///
    /// -   Returns:
    ///     The parsed metadata record.
    public static
    func parse(_ data:[UInt8]) throws -> Self
    {
        guard data.count >= 14
        else
        {
            throw JPEG.ParsingError.mismatched(marker: .application(0),
                count: data.count, minimum: 14)
        }

        // look for 'JFIF\0' signature
        guard data[0 ..< 5] == Self.signature[...]
        else
        {
            throw JPEG.ParsingError.invalidJFIFSignature(.init(data[0 ..< 5]))
        }

        guard let version:Version   = .parse(code: (data[5], data[6]))
        else
        {
            throw JPEG.ParsingError.invalidJFIFVersionCode((data[5], data[6]))
        }
        guard let unit:Unit?        = Unit.parse(code: data[7])
        else
        {
            // invalid JFIF density unit
            throw JPEG.ParsingError.invalidJFIFDensityUnitCode(data[7])
        }

        let density:(x:Int, y:Int)  =
        (
            data.load(bigEndian: UInt16.self, as: Int.self, at:  8),
            data.load(bigEndian: UInt16.self, as: Int.self, at: 10)
        )

        // we ignore the thumbnail data
        return .init(version: version, density: (density.x, density.y, unit))
    }
}

extension JPEG.JFIF.Version
{
    var serialized:(UInt8, UInt8)
    {
        switch self
        {
        case .v1_0:
            return (1, 0)
        case .v1_1:
            return (1, 1)
        case .v1_2:
            return (1, 2)
        }
    }
}
extension JPEG.JFIF.Unit
{
    var serialized:UInt8
    {
        switch self
        {
        case .inches:
            return 1
        case .centimeters:
            return 2
        }
    }
}
extension JPEG.JFIF
{
    /// Serializes this metadata record as segment data.
    ///
    /// This method is the inverse of ``parse(_:)``.
    ///
    /// -   Returns:
    ///     A marker segment body. This array does not include the marker type
    ///     indicator, or the marker segment length field.
    public
    func serialized() -> [UInt8]
    {
        var bytes:[UInt8] = Self.signature
        bytes.append(self.version.serialized.0)
        bytes.append(self.version.serialized.1)
        bytes.append(self.density.unit?.serialized ?? 0)
        bytes.append(contentsOf: [UInt8].store(self.density.x, asBigEndian: UInt16.self))
        bytes.append(contentsOf: [UInt8].store(self.density.y, asBigEndian: UInt16.self))
        // no thumbnail
        bytes.append(0)
        bytes.append(0)
        return bytes
    }
}


extension JPEG.EXIF.FieldType
{
    static
    func parse(code:UInt16) -> Self
    {
        switch code
        {
        case 1:
            return .uint8
        case 2:
            return .ascii
        case 3:
            return .uint16
        case 4:
            return .uint32
        case 5:
            return .urational
        case 7:
            return .raw
        case 9:
            return .int32
        case 10:
            return .rational
        default:
            return .other(code: code)
        }
    }
}
extension JPEG.EXIF
{
    static
    let signature:[UInt8] = [0x45, 0x78, 0x69, 0x66, 0x00, 0x00]
    /// Parses an EXIF segment into a metadata record.
    ///
    /// If the given data does not parse to a valid metadata record,
    /// this function will throw a ``JPEG/ParsingError``.
    ///
    /// This constructor will attempt to index the root, *EXIF* (tag 34665),
    /// and *GPS* (tag 34853) field groups, if they are present and well-linked
    /// in the segment data. This parser ignores embedded thumbnails.
    ///
    /// -   Parameter data:
    ///     The segment data to parse.
    ///
    /// -   Returns:
    ///     The parsed metadata record.
    public static
    func parse(_ data:[UInt8]) throws -> Self
    {
        guard data.count >= 14
        else
        {
            throw JPEG.ParsingError.mismatched(marker: .application(1),
                count: data.count, minimum: 14)
        }

        // look for 'Exif\0\0' signature
        guard data[0 ..< 6] == Self.signature[...]
        else
        {
            throw JPEG.ParsingError.invalidEXIFSignature(.init(data[0 ..< 6]))
        }

        // determine endianness
        let endianness:Endianness
        switch (data[6], data[7], data[8], data[9])
        {
        case (0x49, 0x49, 0x2a, 0x00):
            endianness = .littleEndian
        case (0x4d, 0x4d, 0x00, 0x2a):
            endianness = .bigEndian
        default:
            throw JPEG.ParsingError.invalidEXIFEndiannessCode(
                (data[6], data[7], data[8], data[9]))
        }

        var exif:Self = .init(endianness: endianness, tags: [:],
            storage: .init(data.dropFirst(6)))

        exif.index(ifd: .init(exif[4, as: UInt32.self]))
        // exif ifd
        if  let (type, count, box):(FieldType, Int, Box) = exif[tag: 34665],
            case .uint32 = type, count == 1
        {
            exif.index(ifd: box.asOffset)
        }
        // gps ifd
        if  let (type, count, box):(FieldType, Int, Box) = exif[tag: 34853],
            case .uint32 = type, count == 1
        {
            exif.index(ifd: box.asOffset)
        }

        return exif
    }

    private mutating
    func index(ifd:Int)
    {
        guard ifd + 2 <= self.storage.count
        else
        {
            return
        }

        let count:Int = .init(self[ifd, as: UInt16.self])
        for i:Int in 0 ..< count
        {
            let offset:Int = ifd + 2 + i * 12
            guard offset + 12 <= self.storage.count
            else
            {
                continue
            }

            self.tags[self[offset, as: UInt16.self]] = offset
        }
    }
    /// Returns the field descriptor and boxed value for the given tag,
    /// if it exists in this metadata record.
    ///
    /// -   Parameter tag:
    ///     A tag code. The various EXIF tag codes are listed in the
    ///     [EXIF standard](https://www.exif.org/Exif2-2.PDF). The ``tags``
    ///     dictionary contains an index of the known, defined tags in this metadata
    ///     record.
    ///
    /// -   Returns:
    ///     The field descriptor and boxed value, if it exists, otherwise `nil`.
    public
    subscript(tag tag:UInt16) -> (type:FieldType, count:Int, box:Box)?
    {
        guard let offset:Int = self.tags[tag]
        else
        {
            return nil
        }

        let type:FieldType = .parse(code: self[offset + 2, as: UInt16.self])

        let count:Int = .init(self[offset + 4, as: UInt32.self])
        let box:Box   = .init(
            self[offset + 8 , as: UInt8.self],
            self[offset + 9 , as: UInt8.self],
            self[offset + 10, as: UInt8.self],
            self[offset + 11, as: UInt8.self],
            endianness: self.endianness)
        return (type, count, box)
    }
    /// Loads the ``FieldType/uint8`` value at the given address.
    ///
    /// -   Parameter offset:
    ///     The address of the value to access. This pointer must be within the
    ///     index range of ``storage``.
    ///
    /// -   Parameter _:
    ///     This parameter must be set to `UInt8.self`.
    ///
    /// -   Returns:
    ///     The ``FieldType/uint8`` value.
    public
    subscript(offset:Int, as _:UInt8.Type) -> UInt8
    {
        self.storage[offset]
    }
    /// Loads the ``FieldType/uint16`` value at the given address.
    ///
    /// -   Parameter offset:
    ///     The address of the value to access. This pointer, and the address after
    ///     it must be within the index range of ``storage``.
    ///
    /// -   Parameter _:
    ///     This parameter must be set to `UInt16.self`.
    ///
    /// -   Returns:
    ///     The ``FieldType/uint16`` value, loaded according to the ``endianness``
    ///     of this metadata record.
    public
    subscript(offset:Int, as _:UInt16.Type) -> UInt16
    {
        switch self.endianness
        {
        case .littleEndian:
            return  .init(self[offset + 1, as: UInt8.self]) << 8 |
                    .init(self[offset    , as: UInt8.self])
        case .bigEndian:
            return  .init(self[offset    , as: UInt8.self]) << 8 |
                    .init(self[offset + 1, as: UInt8.self])
        }
    }
    /// Loads the ``FieldType/uint32`` value at the given address.
    ///
    /// -   Parameter offset:
    ///     The address of the value to access. This pointer, and the next three
    ///     addresses after it must be within the index range of ``storage``.
    ///
    /// -   Parameter _:
    ///     This parameter must be set to `UInt32.self`.
    ///
    /// -   Returns:
    ///     The ``FieldType/uint32`` value, loaded according to the ``endianness``
    ///     of this metadata record.
    public
    subscript(offset:Int, as _:UInt32.Type) -> UInt32
    {
        switch self.endianness
        {
        case .littleEndian:
            return  .init(self[offset + 3, as: UInt8.self]) << 24 |
                    .init(self[offset + 2, as: UInt8.self]) << 16 |
                    .init(self[offset + 1, as: UInt8.self]) <<  8 |
                    .init(self[offset    , as: UInt8.self])
        case .bigEndian:
            return  .init(self[offset    , as: UInt8.self]) << 24 |
                    .init(self[offset + 1, as: UInt8.self]) << 16 |
                    .init(self[offset + 2, as: UInt8.self]) <<  8 |
                    .init(self[offset + 3, as: UInt8.self])
        }
    }
}

extension JPEG.EXIF.Endianness
{
    func serialized() -> [UInt8]
    {
        switch self
        {
        case .littleEndian:
            return [0x49, 0x49, 0x2a, 0x00]
        case .bigEndian:
            return [0x4d, 0x4d, 0x00, 0x2a]
        }
    }
}
extension JPEG.EXIF
{
    /// Serializes this metadata record as segment data.
    ///
    /// This method is the inverse of ``parse(_:)``.
    ///
    /// -   Returns:
    ///     A marker segment body. This array does not include the marker type
    ///     indicator, or the marker segment length field.
    public
    func serialized() -> [UInt8]
    {
        var bytes:[UInt8] = Self.signature
        bytes.append(contentsOf: self.endianness.serialized())
        bytes.append(contentsOf: self.storage.dropFirst(4))
        return bytes
    }
}
