import Glibc

enum JPEGReadError:Error
{
    case FileError(String),
         FiletypeError,
         FilestreamError,
         MissingJFIFHeader,
         InvalidJFIFHeader,
         MissingFrameHeader,
         InvalidFrameHeader,
         MissingScanHeader,
         InvalidScanHeader,

         InvalidQuantizationTable,
         InvalidHuffmanTable,

         InvalidDNLSegment,

         StructuralError,
         SyntaxError(String),

         Unsupported(String)
}

struct UnsafeRawVector
{
    private
    var buffer:UnsafeMutableRawBufferPointer = .init(start: nil, count: 0)

    internal private(set)
    var count:Int = 0

    private
    var capacity:Int
    {
        return self.buffer.count
    }

    // don’t try to call `deallocate()` on this, it will work (after SE-0184), but
    // it is not well-defined. keep the original UnsafeRawVector object around
    // and call `deallocate()` on that instead.
    var dataView:UnsafeRawBufferPointer
    {
        return UnsafeRawBufferPointer(start: self.buffer.baseAddress, count: self.count)
    }

    subscript(i:Int) -> UInt8
    {
        get
        {
            return self.buffer[i]
        }
        set(v)
        {
            self.buffer[i] = v
        }
    }

    func deallocate()
    {
        self.buffer.deallocate()
    }

    mutating
    func append(_ byte:UInt8)
    {
        if self.count == self.capacity
        {
            let newCapacity:Int                         = max(1, self.capacity << 1)
            let newBuffer:UnsafeMutableRawBufferPointer = .allocate(count: newCapacity)
            newBuffer.copyBytes(from: self.buffer)
            self.buffer.deallocate()
            self.buffer = newBuffer
        }

        self.buffer[self.count] = byte
        self.count             += 1
    }
}

func resolvePath(_ path:String) -> String
{
    guard let first:Character = path.first
    else
    {
        return path
    }

    if first == "~"
    {
        let expanded:String.SubSequence = path.dropFirst()
        if  expanded.isEmpty ||
            expanded.first == "/"
        {
            return String(cString: getenv("HOME")) + expanded
        }

        return path
    }

    return path
}

extension UnsafeRawBufferPointer
{
    func loadBigEndian<I>(fromByteOffset offset:Int, as _:I.Type)
        -> I where I:FixedWidthInteger
    {
        var i:I = .init()
        withUnsafeMutablePointer(to: &i)
        {
            UnsafeMutableRawPointer($0).copyBytes(from: self.baseAddress! + offset,
                count: MemoryLayout<I>.size)
        }

        return I(bigEndian: i)
    }
}

// TODO: implement buffering
func readUInt8(from stream:UnsafeMutablePointer<FILE>) throws -> UInt8
{
    var uint8:UInt8 = 0
    return try withUnsafeMutablePointer(to: &uint8)
    {
        guard fread($0, 1, 1, stream) == 1
        else
        {
            throw JPEGReadError.FilestreamError
        }

        return $0.pointee
    }
}

func readBigEndian<I>(from stream:UnsafeMutablePointer<FILE>, as:I.Type) throws
    -> I where I:FixedWidthInteger
{
    var i:I = .init()
    return try withUnsafeMutablePointer(to: &i)
    {
        guard fread($0, MemoryLayout<I>.size, 1, stream) == 1
        else
        {
            throw JPEGReadError.FilestreamError
        }

        return I(bigEndian: $0.pointee)
    }
}

// reads length block and allocates output buffer
func readMarkerData(from stream:UnsafeMutablePointer<FILE>)
    throws -> UnsafeRawBufferPointer
{
    let length:Int = Int(try readBigEndian(from: stream, as: UInt16.self)) - 2
    let dest = UnsafeMutableRawBufferPointer.allocate(count: length)

    guard fread(dest.baseAddress, 1, length, stream) == length
    else
    {
        throw JPEGReadError.FilestreamError
    }

    return UnsafeRawBufferPointer(dest)
}

func readNextMarker(from stream:UnsafeMutablePointer<FILE>) throws -> UInt8
{
    guard try readUInt8(from: stream) == 0xff
    else
    {
        throw JPEGReadError.StructuralError
    }

    while true
    {
        let marker:UInt8 = try readUInt8(from: stream)
        if marker != 0xff
        {
            return marker
        }
    }
}

enum UnsafeQuantizationTable
{
    case q8 (UnsafeMutablePointer<UInt8>),
         q16(UnsafeMutablePointer<UInt16>)

    static
    func createQ8(data:UnsafeRawPointer) -> UnsafeQuantizationTable
    {
        let cells:UnsafeMutablePointer<UInt8> = .allocate(capacity: 64),
            u8:UnsafePointer<UInt8> = data.bindMemory(to: UInt8.self, capacity: 64)
        cells.initialize(from: u8, count: 64)
        return .q8(cells)
    }

    static
    func createQ16(data:UnsafeRawPointer) -> UnsafeQuantizationTable
    {
        let cells:UnsafeMutablePointer<UInt16> = .allocate(capacity: 64),
            u16:UnsafePointer<UInt16> = data.bindMemory(to: UInt16.self, capacity: 64)

        for cell:Int in 0 ..< 64
        {
            (cells + cell).initialize(to: UInt16(bigEndian: u16[cell]))
        }

        return .q16(cells)
    }

    func destroy()
    {
        switch self
        {
        case .q8 (let buffer):
            buffer.deinitialize (count: 64)
            buffer.deallocate(capacity: 64)

        case .q16(let buffer):
            buffer.deinitialize (count: 64)
            buffer.deallocate(capacity: 64)
        }
    }
}

struct UnsafeHuffmanTable
{
    enum CoefficientClass
    {
        case DC, AC
    }

    typealias Entry = (value:UInt8, length:UInt8)
    
    private 
    let coefficientClass:CoefficientClass, 
        storage:UnsafeMutablePointer<Entry>, 
        s:Int // s is the number of subtrees, not including the root 
    
    // number of level 0 entries
    private 
    var n0:Int 
    {
        return 256 - self.s
    }
    
    @inline(__always)
    private static 
    func size(s:Int) -> Int 
    {
        return 256 + 255 * s
    }
    
    // determine the value of k, explained in create(leafCounts:leafValues:coefficientClass),
    // also validates leaf counts to make sure they define a valid 16-bit tree
    
    // PARANOIA: what if we get bad data and leafCounts isn't long enough??
    private static
    func countSubtrees(_ leafCounts:UnsafePointer<UInt8>) -> Int?
    {
        var internalNodes:Int = 1 // count the root 
        for l:Int in 0 ..< 8 
        {
            guard internalNodes > 0 
            else 
            {
                return 0 // no subtrees
            }
            
            // every internal node on the level above generates two new nodes.
            // some of the new nodes are leaf nodes, the rest are internal nodes.
            internalNodes = internalNodes << 1 - Int(leafCounts[l])
        }
        
        // the number of internal nodes remaining is the number of child trees, with 
        // the possible exception of a fake all-ones branch 
        let subtrees:Int = internalNodes 
        
        // finish validating the tree 
        for l:Int in 8 ..< 16 
        {
            guard internalNodes > 0 
            else 
            {
                // if we reached level 16, internalNodes must be 1 since the all-ones 
                // pattern is reserved 
                guard l < 15 
                else 
                {
                    return nil
                }

                return subtrees
            }
            
            internalNodes = internalNodes << 1 - Int(leafCounts[l])
        }
        
        guard internalNodes == 1 
        else 
        {
            return nil
        }
        
        return subtrees
    }

    static 
    func create(leafCounts:UnsafePointer<UInt8>, leafValues:UnsafePointer<UInt8>, 
        coefficientClass:CoefficientClass) -> UnsafeHuffmanTable?
    {
    /*
        // idea:    jpeg huffman tables are encoded gzip style, as sequences of
        //          leaf counts and leaf values. the leaf counts tell you the
        //          number of leaf nodes at each level of the tree. combined with
        //          a rule that says that leaf nodes always occur on the “leftmost”
        //          side of the tree, this uniquely determines a huffman tree.
        //
        //          Given: leaves per level = [0, 3, 2, ... ]
        //
        //                     ___0___[root]___1___
        //                   /                      \
        //            __0__[ ]__1__            __0__[ ]__1__
        //          /              \         /               \
        //         [a]            [b]      [c]            _0_[ ]_1_
        //                                              /           \
        //                                            [d]           [e]
        //
        //          note that in a huffman tree, level 0 always contains 0 leaf
        //          nodes (why?) so the huffman table omits level 0 in the leaf
        //          counts list.
        //
        //          we *could* build a tree data structure, and traverse it as
        //          we read in the coded bits, but that would be slow and require
        //          a shift for every bit. instead we extend the huffman tree
        //          into a perfect tree, and assign the new leaf nodes the
        //          values of their parents.
        //
        //                      ________[root]________
        //                    /                        \
        //            _____[ ]_____                _____[ ]_____
        //           /             \             /               \
        //          [a]           [b]          [c]            ___[ ]___
        //        /     \       /     \       /   \         /           \
        //      (a)     (a)   (b)     (b)   (c)   (c)      [d]          [e]
        //
        //          this lets us make a table of huffman codes where all the
        //          codes are “padded” to the same length. note that codewords
        //          that occur higher up the tree occur multiple times because
        //          they have multiple children. of course, since the extra bits
        //          aren’t actually part of the code, we have to store separately
        //          the length of the original code so we know how many bits
        //          we should advance the current bit position by once we match
        //          a code.
        //
        //            code       value     length
        //          —————————  —————————  ————————
        //             000        'a'         2
        //             001        'a'         2
        //             010        'b'         2
        //             011        'b'         2
        //             100        'c'         2
        //             101        'c'         2
        //             110        'd'         3
        //             111        'e'         3
        //
        //          decoding coded data then becomes a matter of matching a fixed
        //          length bitstream against the table (the code works as an integer
        //          index!) since all possible combinations of trailing “padding”
        //          bits are represented in the table.
        //
        //          in jpeg, codewords can be a maximum of 16 bits long. this
        //          means in theory we need a table with 2^16 entries. that’s a
        //          huge table considering there are only 256 actual encoded
        //          values, and since this is the kind of thing that really needs
        //          to be optimized for speed, this needs to be as cache friendly
        //          as possible.
        //
        //          we can reduce the table size by splitting the 16-bit table
        //          into two 8-bit levels. this means we have one 8-bit “root”
        //          tree, and k 8-bit child trees rooted on the internal nodes
        //          at level 8 of the original tree.
        //
        //          how big can k be? well, remember that there are only 256
        //          different encoded values which means the original tree can
        //          only have 256 leaves. any full binary tree with height at
        //          least 1 *must* contain at least 2 leaf nodes (why?). since
        //          the child trees must have a height > 0 (otherwise they would
        //          be 0-bit trees), every child tree except possibly the right-
        //          most one must have at least 2 leaf nodes. the rightmost child
        //          tree is an exception because in jpeg, the all-ones codeword
        //          does not represent any value, so the right-most tree can
        //          possibly only contain one “real” leaf node. we can pigeonhole
        //          this shit to show that we can only have up to k ≤ 129 child
        //          trees. in fact, we can reduce this even further to k ≤ 128
        //          because if the rightmost tree only contains 1 leaf, there
        //          has to be at least one other tree with an odd number of leaves
        //          to make the total add up to 256, and that number has to be at
        //          least 3. in reality, k is rarely bigger than 7 or 8 yielding
        //          a significant size savings.
        //
        //          now we have one primary table with 256 entries of type
        //
        //      (value:UInt8, length:UInt8, childIndex:UInt8?) = primaryTable[code >> 8] ,
        //
        //          and k child tables of type
        //
        //      (value:UInt8, length:UInt8) = childTables[childIndex][code & 0xff] .
        //
        //          as it turns out, some of the primary table entry fields are
        //          redundant. no primary table leaf can have a length > 8 (or
        //          a length 0 for that matter), so we can use that as a sentinel
        //          for a child table and interpret the value field as a child
        //          table index should `1 ... 8 ~= length == false`. this means
        //          all of our tables can be stored as contigous UInt8 pairs of
        //          type
        //                   (valueOrChild:UInt8, lengthAndFlags:UInt8) .
        //
        //          such a buffer will never have size greater than
        //          2 × 256 × (1 + 128) = 66_048 bytes, compared with
        //          2 × (1 << 16)  = 131_072 bytes for the 16-bit table. in
        //          reality the 2 layer table is usually on the order of 2–4 kB.
        //
        //          why not compact the child trees further, since not all of them
        //          actually have height 8? we could do that, and get some serious
        //          worst-case memory savings, but then we couldn’t access the
        //          child tables at constant offsets from the buffer base. we’d
        //          need to store whole ass ≥16-bit pointers to the specific
        //          byte offset where the variable-length child table lives, and
        //          perform a conditional bit shift to transform the input bits
        //          into an appropriate index into the table. not a good look.
    */
        
        guard let s:Int = countSubtrees(leafCounts) 
        else 
        {
            return nil
        }
        
        let count:Int                           = size(s: s),
            storage:UnsafeMutablePointer<Entry> = .allocate(capacity: count)
        
        var value:UnsafePointer<UInt8> = leafValues, 
            shadow:Int                 = 0x100100, 
            i:Int                      = 0
        for l:Int in 0 ..< 16
        {
            guard i < count 
            else 
            {
                break
            }
            
            shadow >>= 1
            
            for _ in 0 ..< leafCounts[l]
            {
                let limit:Int = i + shadow & 0x1ff
                while (i < limit)
                {
                    storage[i] = (value: value.pointee, length: UInt8(truncatingIfNeeded: l + 1))
                    i             += 1
                }
                
                value += 1
            }
        }
        
        return .init(coefficientClass: coefficientClass, storage: storage, s: s)
    }
    
    func destroy() 
    {
        // no deinitialization because the buffer can be slightly underinitialized
        self.storage.deallocate(capacity: UnsafeHuffmanTable.size(s: self.s))
    }
    
    subscript(codeword:UInt16) -> Entry 
    {
        // [ level 0 index  |    offset    ]
        let l0:Int = .init(codeword >> 8)
        return self.storage[l0 < self.n0 ? l0 : (l0 - 255) << 8 + 255 * self.s + Int(codeword & 0xff)]
    }
}

struct JFIF
{
    enum DensityUnit:UInt8
    {
        case none = 0,
             dpi  = 1,
             dpcm = 2
    }

    let version:(major:UInt8, minor:UInt8),
        densityUnit:DensityUnit,
        density:(x:UInt16, y:UInt16)

    static
    func read(from stream:UnsafeMutablePointer<FILE>, marker:inout UInt8)
        throws -> JFIF?
    {
        guard marker == 0xe0
        else
        {
            throw JPEGReadError.MissingJFIFHeader
        }

        let data:UnsafeRawBufferPointer = try readMarkerData(from: stream)
        marker  = try readNextMarker(from: stream)
        return JFIF.create(from: data)
    }

    private static //todo: rewrite this with buffers and without throws
    func create(from data:UnsafeRawBufferPointer) -> JFIF?
    {
        guard data.count >= 14
        else
        {
            return nil
        }

        for (b1, b2):(UInt8, UInt8) in zip(data[0 ..< 5], [0x4a, 0x46, 0x49, 0x46, 0x00])
        {
            guard b1 == b2
            else
            {
                // missing 'JFIF' signature"
                return nil
            }
        }

        let version:(major:UInt8, minor:UInt8) =
            (data.load(fromByteOffset: 5, as: UInt8.self),
             data.load(fromByteOffset: 6, as: UInt8.self))

        guard version.major == 1, 0 ... 2 ~= version.minor
        else
        {
            // bad JFIF version number (expected 1.0 ... 1.2)
            return nil
        }

        guard let densityUnit =
            DensityUnit(rawValue: data.load(fromByteOffset: 7, as: UInt8.self))
        else
        {
            // invalid JFIF density unit
            return nil
        }

        let density:(x:UInt16, y:UInt16) =
            (data.loadBigEndian(fromByteOffset:  8, as: UInt16.self),
             data.loadBigEndian(fromByteOffset: 10, as: UInt16.self))

        // we ignore the thumbnail data

        return JFIF(version: version, densityUnit: densityUnit, density: density)
    }
}

struct UnsafeFrameHeader
{
    enum Encoding
    {
        case baselineDCT,
             extendedDCT,
             progressiveDCT
    }

    struct Component
    {
        private
        let _sampleFactors:UInt8

        let qtable:UInt8

        var sampleFactors:(x:UInt8, y:UInt8)
        {
            return (_sampleFactors >> 4, _sampleFactors & 0x0f)
        }

        init?(sampleFactors:UInt8, qtable:UInt8)
        {
            guard 1 ... 4 ~= sampleFactors >> 4,
                  1 ... 4 ~= sampleFactors & 0x0f,
                  0 ... 3 ~= qtable
            else
            {
                return nil
            }

            self._sampleFactors = sampleFactors
            self.qtable = qtable
        }
    }

    let encoding:Encoding,
        precision:Int,
        width:Int

    internal private(set)
    var height:Int

    let components:UnsafeBufferPointer<Component>

    let indexMap:UnsafePointer<Int> // always 256 Ints long, -1 signifies hole

    func deallocate()
    {
        UnsafeMutablePointer(mutating: self.components.baseAddress!)
            .deinitialize(count: self.components.count)
        UnsafeMutablePointer(mutating: self.components.baseAddress!)
            .deallocate(capacity: -1)
        UnsafeMutablePointer(mutating: self.indexMap)
            .deinitialize(count: 256)
        UnsafeMutablePointer(mutating: self.indexMap)
            .deallocate(capacity: -1)
    }

    static
    func read(from stream:UnsafeMutablePointer<FILE>, marker:inout UInt8) throws
        -> UnsafeFrameHeader?
    {
        let data:UnsafeRawBufferPointer,
            encoding:Encoding

        switch marker
        {
        case 0xc0:
            data     = try readMarkerData(from: stream)
            encoding = .baselineDCT

        case 0xc1:
            data     = try readMarkerData(from: stream)
            encoding = .extendedDCT

        case 0xc2:
            data     = try readMarkerData(from: stream)
            encoding = .progressiveDCT

        case 0xc3:
            throw JPEGReadError.Unsupported("hierarchical jpegs are unsupported")

        default:
            throw JPEGReadError.MissingFrameHeader
        }

        defer
        {
            data.deallocate()
        }

        marker = try readNextMarker(from: stream)
        return create(from: data, encoding: encoding)
    }

    private static
    func create(from data:UnsafeRawBufferPointer, encoding:Encoding)
        -> UnsafeFrameHeader?
    {
        guard data.count >= 8
        else
        {
            return nil
        }

        let precision = Int(data.load(fromByteOffset: 0, as: UInt8.self))
        switch encoding
        {
        case .baselineDCT:
            guard precision == 8
            else
            {
                return nil
            }

        case .extendedDCT, .progressiveDCT:
            guard precision == 8 || precision == 12
            else
            {
                return nil
            }
        }

        let width  = Int(data.loadBigEndian(fromByteOffset: 1, as: UInt16.self)),
            height = Int(data.loadBigEndian(fromByteOffset: 3, as: UInt16.self))

        let nf     = Int(data.load(fromByteOffset: 5, as: UInt8.self))

        if encoding == .progressiveDCT
        {
            guard 1 ... 4 ~= nf
            else
            {
                return nil
            }
        }

        guard 3 * nf + 6 == data.count
        else
        {
            return nil
        }

        let components = UnsafeMutablePointer<Component>.allocate(capacity: nf),
            indexMap   = UnsafeMutablePointer<Int>.allocate(capacity: 256)
            indexMap.initialize(to: -1, count: 256)
        for i:Int in 0 ..< nf
        {
            let ci = Int(data.load(fromByteOffset: 6 + 3 * i, as: UInt8.self))
            indexMap[ci] = i
            guard let component = Component(
                sampleFactors: data.load(fromByteOffset: 7 + 3 * i, as: UInt8.self),
                qtable:        data.load(fromByteOffset: 8 + 3 * i, as: UInt8.self))
            else
            {
                components.deinitialize(count: i)
                components.deallocate(capacity: -1)
                indexMap.deinitialize(count: 256)
                indexMap.deallocate(capacity: -1)
                return nil
            }

            (components + i).initialize(to: component)
        }

        return UnsafeFrameHeader(encoding: encoding,
            precision:  precision,
            width:      width,
            height:     height,
            components: UnsafeBufferPointer(start: components, count: nf),
            indexMap:   indexMap)
    }

    mutating
    func updateHeight(from stream:UnsafeMutablePointer<FILE>, marker:inout UInt8)
        throws
    {
        guard marker == 0xdc
        else
        {
            return
        }

        let data:UnsafeRawBufferPointer = try readMarkerData(from: stream)
        defer
        {
            data.deallocate()
        }

        guard data.count == 2
        else
        {
            throw JPEGReadError.InvalidDNLSegment
        }

        self.height = Int(data.loadBigEndian(fromByteOffset: 0, as: UInt16.self))
    }
}

struct ScanHeader
{
    // the marker parameter is not a reference because this function does not
    // update the `marker` variable because scan headers are followed by MCU data
    static
    func read(from stream:UnsafeMutablePointer<FILE>, marker:UInt8) throws
        -> ScanHeader?
    {
        guard marker == 0xda
        else
        {
            throw JPEGReadError.MissingScanHeader
        }

        let data:UnsafeRawBufferPointer = try readMarkerData(from: stream)
        defer
        {
            data.deallocate()
        }

        return create(from: data)
    }

    private static
    func create(from _:UnsafeRawBufferPointer) -> ScanHeader?
    {
        return ScanHeader()
    }
}

struct UnsafeContext
{
    internal private(set)
    var restartInterval:Int = 0

    // these must be managed manually or they will leak
    private
    var qtables:(UnsafeQuantizationTable?,
                 UnsafeQuantizationTable?,
                 UnsafeQuantizationTable?,
                 UnsafeQuantizationTable?) = (nil, nil, nil, nil)

    private
    var htables:(UnsafeHuffmanTable?,
                 UnsafeHuffmanTable?,
                 UnsafeHuffmanTable?,
                 UnsafeHuffmanTable?) = (nil, nil, nil, nil)

    func destroy()
    {
        qtables.0?.destroy()
        qtables.1?.destroy()
        qtables.2?.destroy()
        qtables.3?.destroy()

        htables.0?.destroy()
        htables.1?.destroy()
        htables.2?.destroy()
        htables.3?.destroy()
    }

    // restart is a naked marker so it takes no `stream` parameter. just like
    // ScanHeader.read(from:marker:) this function does not update the `marker`
    // variable because restart markers are followed by MCU data
    func restart(marker:UInt8) -> Bool
    {
        return 0xd0 ... 0xd7 ~= marker
    }

    mutating // todo: rewrite with buffers and no throws
    func update(from stream:UnsafeMutablePointer<FILE>, marker:inout UInt8) throws
    {
        while true
        {
            let data:UnsafeRawBufferPointer
            switch marker
            {
            case 0xdb: // define quantization table(s)
                print("quantization table")
                data = try readMarkerData(from: stream)
                guard let _:Void = self.updateQuantizationTables(from: data)
                else
                {
                    throw JPEGReadError.InvalidQuantizationTable
                }

            case 0xc4: // define huffman table(s)
                print("huffman table")
                data = try readMarkerData(from: stream)
                guard let _:Void = self.updateHuffmanTables(from: data)
                else
                {
                    throw JPEGReadError.InvalidHuffmanTable
                }

            case 0xdd: // define restart interval
                print("DRI")
                data = try readMarkerData(from: stream)

            case 0xfe: // comment
                print("comment")
                data = try readMarkerData(from: stream)

            default:
                return
            }

            defer
            {
                data.deallocate()
            }

            marker = try readNextMarker(from: stream)
        }
    }

    private mutating
    func updateQuantizationTables(from data:UnsafeRawBufferPointer) -> Void?
    {
        var i:Int = 0
        while (i < data.count)
        {
            let table:UnsafeQuantizationTable,
                flags:UInt8 = data[i]
            // `i` gets incremented halfway through so it’s easier to just store
            // the `flags` byte
            switch flags & 0xf0
            {
            case 0x00:
                guard i + 64 + 1 <= data.count
                else
                {
                    return nil
                }

                table = .createQ8(data: data.baseAddress! + i + 1)
                i += 64 + 1

            case 0x10:
                guard i + 128 + 1 <= data.count
                else
                {
                    return nil
                }

                table = .createQ16(data: data.baseAddress! + i + 1)
                i += 128 + 1

            default:
                // quantization table has invalid precision
                return nil
            }

            switch flags & 0x0f
            {
            case 0:
                qtables.0?.destroy()
                qtables.0 = table

            case 1:
                qtables.1?.destroy()
                qtables.1 = table

            case 2:
                qtables.2?.destroy()
                qtables.2 = table

            case 3:
                qtables.3?.destroy()
                qtables.3 = table

            default:
                // quantization table has invalid binding index (index must be in 0 ... 3)
                table.destroy()
                return nil
            }
        }

        return ()
    }

    private mutating
    func updateHuffmanTables(from data:UnsafeRawBufferPointer) -> Void?
    {
        guard var it:UnsafeRawPointer = data.baseAddress
        else
        {
            // only possible in an (invalid) malicious jpeg containing an empty
            // huffman marker
            return nil
        }

        let end:UnsafeRawPointer = it + data.count
        while (it < end)
        {
            guard it + 17 <= end
            else
            {
                // data buffer does not contain enough data
                return nil
            }

            let coefficientClass:UnsafeHuffmanTable.CoefficientClass,
                flags:UInt8 = it.load(as: UInt8.self)
            // `it` gets incremented halfway through so it’s easier to just store
            // the `flags` byte
            switch flags & 0xf0
            {
            case 0x00:
                coefficientClass = .DC

            case 0x10:
                coefficientClass = .AC

            default:
                // huffman table has invalid class
                return nil
            }

            it += 1

            // huffman tables have variable length that can only be determined
            // by examining the first 17 bytes of each table which means checks
            // have to be done midway through the parsing
            let leafCounts:UnsafePointer<UInt8> = it.bindMemory(to: UInt8.self, capacity: 16)
            it += 16
            
            // count the number of expected leaves 
            let leaves:Int = (0 ..< 16).reduce(0){ $0 + Int(leafCounts[$1]) }

            guard it + leaves <= end
            else
            {
                // data buffer does not contain enough data
                return nil
            }

            let leafValues:UnsafePointer<UInt8> = it.bindMemory(to: UInt8.self, capacity: leaves)

            guard let table:UnsafeHuffmanTable = .create(leafCounts: leafCounts,
                    leafValues: leafValues,
                    coefficientClass: coefficientClass)
            else 
            {
                return nil 
            }

            switch flags & 0x0f
            {
            case 0:
                htables.0?.destroy()
                htables.0 = table

            case 1:
                htables.1?.destroy()
                htables.1 = table

            case 2:
                htables.2?.destroy()
                htables.2 = table

            case 3:
                htables.3?.destroy()
                htables.3 = table

            default:
                // huffman table has invalid binding index (index must be in 0 ... 3)
                table.destroy()
                return nil
            }
        }

        return ()
    }
}

func readMCUs(from stream:UnsafeMutablePointer<FILE>, marker:inout UInt8) throws
    -> UnsafeRawVector
{
    var vector     = UnsafeRawVector(),
        byte:UInt8 = try readUInt8(from: stream)
    while true
    {
        if byte == 0xff
        {
            // this is the only exit point from this function so we can just
            // reuse the `inout marker` variable
            marker = try readUInt8(from: stream)
            if marker != 0x00
            {
                while marker == 0xff
                {
                    marker = try readUInt8(from: stream)
                }

                return vector
            }
        }

        vector.append(byte)
        byte = try readUInt8(from: stream)
    }
}

func decode(path:String) throws
{
    guard let stream:UnsafeMutablePointer<FILE> = fopen(resolvePath(path), "rb")
    else
    {
        throw JPEGReadError.FileError(resolvePath(path))
    }
    defer
    {
        fclose(stream)
    }
    
    // start of image marker
    guard try readNextMarker(from: stream) == 0xd8
    else
    {
        throw JPEGReadError.FiletypeError
    }

    var marker:UInt8 = try readNextMarker(from: stream)

    guard let _:JFIF = try .read(from: stream, marker: &marker)
    else
    {
        throw JPEGReadError.InvalidJFIFHeader
    }

    var context:UnsafeContext = .init()
    defer
    {
        context.destroy()
    }
    
    try context.update(from: stream, marker: &marker)

    guard var frameHeader:UnsafeFrameHeader = try .read(from: stream, marker: &marker)
    else
    {
        throw JPEGReadError.InvalidFrameHeader
    }

    var firstScan:Bool = true
    while marker != 0xd9 // end of image
    {
        try context.update(from: stream, marker: &marker)
        guard let scanHeader = try ScanHeader.read(from: stream, marker: marker)
        else
        {
            throw JPEGReadError.InvalidScanHeader
        }

        let mcuVector:UnsafeRawVector = try readMCUs(from: stream, marker: &marker)
        defer
        {
            mcuVector.deallocate()
        }

        if context.restartInterval > 0
        {
            while context.restart(marker: marker)
            {
                let mcuVector:UnsafeRawVector =
                    try readMCUs(from: stream, marker: &marker)
                defer
                {
                    mcuVector.deallocate()
                }
            }
        }

        if firstScan
        {
            try frameHeader.updateHeight(from: stream, marker: &marker)
            firstScan = false
        }
    }
    // the while loop already scanned the EOI marker
}
