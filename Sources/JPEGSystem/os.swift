/* This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/. */

import JPEG

#if os(macOS)
    import Darwin
#elseif os(Linux)
    import Glibc
#elseif os(Android)
    import Android
#else
    #warning("unsupported or untested platform (please open an issue at https://github.com/tayloraswift/swift-jpeg/issues)")
#endif

#if os(macOS) || os(Linux) || os(Android)

/// A namespace for platform-dependent functionality.
///
/// These APIs are only available on MacOS and Linux. However, the rest of the
/// framework is pure Swift and should support all Swift platforms.
public
enum System
{
    /// A namespace for file IO functionality.
    public
    enum File
    {
        #if os(Android)
        typealias Descriptor = OpaquePointer
        #else
        typealias Descriptor = UnsafeMutablePointer<FILE>
        #endif

        /// A type for reading data from files on disk.
        public
        struct Source
        {
            private
            let descriptor:Descriptor
        }

        /// A type for writing data to files on disk.
        public
        struct Destination
        {
            private
            let descriptor:Descriptor
        }
    }
}
extension System.File.Source
{
    /// Calls a closure with an interface for reading from the specified file.
    ///
    /// This method automatically closes the file when its closure argument returns.
    ///
    /// -   Parameter path:
    ///     The path to the file to open.
    ///
    /// -   Parameter body:
    ///     A closure with a ``Source`` parameter from which data in
    ///     the specified file can be read. This interface is only valid
    ///     for the duration of the method’s execution. The closure is
    ///     only executed if the specified file could be successfully
    ///     opened, otherwise this method will return `nil`. If `body` has a
    ///     return value and the specified file could be opened, this method
    ///     returns the return value of the closure.
    ///
    /// -   Returns:
    ///     The return value of the closure argument, or `nil` if the specified
    ///     file could not be opened.
    public static
    func open<R>(path:String, _ body:(inout Self) throws -> R)
        rethrows -> R?
    {
        guard let descriptor:System.File.Descriptor = fopen(path, "rb")
        else
        {
            return nil
        }

        var file:Self = .init(descriptor: descriptor)
        defer
        {
            fclose(file.descriptor)
        }

        return try body(&file)
    }

    /// Reads the specified number of bytes from this file interface.
    ///
    /// This method only returns an array if the exact number of bytes
    /// specified could be read. This method advances the file pointer.
    ///
    /// -   Parameter capacity:
    ///     The number of bytes to read.
    ///
    /// -   Returns:
    ///     An array containing the read data, or `nil` if the specified
    ///     number of bytes could not be read.
    public
    func read(count capacity:Int) -> [UInt8]?
    {
        let buffer:[UInt8] = .init(unsafeUninitializedCapacity: capacity)
        {
            (buffer:inout UnsafeMutableBufferPointer<UInt8>, count:inout Int) in

            #if os(Android)
            let baseAddress = buffer.baseAddress!
            #else
            let baseAddress = buffer.baseAddress
            #endif
            count = fread(baseAddress, MemoryLayout<UInt8>.stride,
                capacity, self.descriptor)
        }

        guard buffer.count == capacity
        else
        {
            return nil
        }

        return buffer
    }
    /// The size of the file, in bytes, or `nil` if the file is not a regular
    /// file or a link to a file.
    ///
    /// This property queries the file size using `stat`.
    public
    var count:Int?
    {
        let descriptor:Int32 = fileno(self.descriptor)
        guard descriptor != -1
        else
        {
            return nil
        }

        guard let status:stat =
        ({
            var status:stat = .init()
            guard fstat(descriptor, &status) == 0
            else
            {
                return nil
            }
            return status
        }())
        else
        {
            return nil
        }

        switch status.st_mode & S_IFMT
        {
        case S_IFREG, S_IFLNK:
            break
        default:
            return nil
        }

        return Int.init(status.st_size)
    }
}
extension System.File.Destination
{
    /// Calls a closure with an interface for writing to the specified file.
    ///
    /// This method automatically closes the file when its closure argument returns.
    ///
    /// -   Parameter path:
    ///     The path to the file to open.
    ///
    /// -   Parameter body:
    ///     A closure with a ``Destination`` parameter representing
    ///     the specified file to which data can be written to. This
    ///     interface is only valid for the duration of the method’s
    ///     execution. The closure is only executed if the specified file could
    ///     be successfully opened, otherwise this method will return `nil`.
    ///     If `body` has a return value and the specified file could be opened,
    ///     this method returns the return value of the closure.
    ///
    /// -   Returns:
    ///     The return value of the closure argument, or `nil` if the specified
    ///     file could not be opened.
    public static
    func open<R>(path:String, _ body:(inout Self) throws -> R)
        rethrows -> R?
    {
        guard let descriptor:System.File.Descriptor = fopen(path, "wb")
        else
        {
            return nil
        }

        var file:Self = .init(descriptor: descriptor)
        defer
        {
            fclose(file.descriptor)
        }

        return try body(&file)
    }

    /// Write the bytes in the given array to this file interface.
    ///
    /// This method only returns `()` if the entire array argument could
    /// be written. This method advances the file pointer.
    ///
    /// -   Parameter buffer:
    ///     The data to write.
    ///
    /// -   Returns:
    ///     A ``Void`` tuple if the entire array argument could be written,
    ///     or `nil` otherwise.
    public
    func write(_ buffer:[UInt8]) -> Void?
    {
        let count:Int = buffer.withUnsafeBufferPointer
        {
            #if os(Android)
            let baseAddress = $0.baseAddress!
            #else
            let baseAddress = $0.baseAddress
            #endif
            return fwrite(baseAddress, MemoryLayout<UInt8>.stride,
                $0.count, self.descriptor)
        }

        guard count == buffer.count
        else
        {
            return nil
        }

        return ()
    }
}

// declare conformance (as a formality)
extension System.File.Source:JPEG.Bytestream.Source
{
}
extension System.File.Destination:JPEG.Bytestream.Destination
{
}
// file-based encoding and decoding apis
extension JPEG.Data.Spectral
{
    /// Decompresses a spectral image from the given file path.
    ///
    /// Calling this function is equivalent to calling ``System.File.Source.open(path:_:)``
    /// with the closure parameter set to ``decompress(stream:)``.
    ///
    /// This function is only available on MacOS and Linux platforms.
    ///
    /// -   Parameter path:
    ///     A file path.
    ///
    /// -   Returns:
    ///     The decompressed image, or `nil` if the file could not be opened at
    ///     the given file path.
    public static
    func decompress(path:String) throws -> Self?
    {
        return try System.File.Source.open(path: path, Self.decompress(stream:))
    }
    /// Compresses a spectral image to the given file path.
    ///
    /// All metadata records in this image will be emitted at the beginning of
    /// the outputted file, in the order they appear in the ``metadata`` array.
    ///
    /// Calling this function is equivalent to calling ``System.File.Destination.open(path:_:)``
    /// with the closure parameter set to ``compress(stream:)``.
    ///
    /// This function is only available on MacOS and Linux platforms.
    ///
    /// -   Parameter path:
    ///     A file path.
    ///
    /// -   Returns:
    ///     A ``Void`` tuple, or `nil` if the file could not be opened at
    ///     the given file path.
    public
    func compress(path:String) throws -> Void?
    {
        return try System.File.Destination.open(path: path, self.compress(stream:))
    }
}
extension JPEG.Data.Planar
{
    /// Decompresses a planar image from the given file path.
    ///
    /// This function is a convenience function which calls ``Spectral.decompress(path:)``
    /// to obtain a spectral image, and then calls ``Spectral/idct()`` on the
    /// output to return a planar image.
    ///
    /// This function is only available on MacOS and Linux platforms.
    ///
    /// -   Parameter path:
    ///     A file path.
    ///
    /// -   Returns:
    ///     The decompressed image, or `nil` if the file could not be opened at
    ///     the given file path.
    public static
    func decompress(path:String) throws -> Self?
    {
        guard let spectral:JPEG.Data.Spectral<Format> = try .decompress(path: path)
        else
        {
            return nil
        }
        return spectral.idct()
    }
    /// Compresses a planar image to the given file path.
    ///
    /// All metadata records in this image will be emitted at the beginning of
    /// the outputted file, in the order they appear in the ``metadata`` array.
    ///
    /// This function is a convenience function which calls ``fdct(quanta:)``
    /// to obtain a spectral image, and then calls ``Spectral/compress(path:)``
    /// on the output.
    ///
    /// This function is only available on MacOS and Linux platforms.
    ///
    /// -   Parameter path:
    ///     A file path.
    ///
    /// -   Parameter quanta:
    ///     The quantum values for each quanta key used by this image’s ``layout``,
    ///     including quanta keys used only by non-recognized components. Each
    ///     array of quantum values must have exactly 64 elements. The quantization
    ///     tables created from these values will be encoded using integers with a bit width
    ///     determined by this image’s `layout.format.precision`,
    ///     and all the values must be in the correct range for that bit width.
    ///
    /// -   Returns:
    ///     A ``Void`` tuple, or `nil` if the file could not be opened at
    ///     the given file path.
    public
    func compress(path:String, quanta:[JPEG.Table.Quantization.Key: [UInt16]]) throws
        -> Void?
    {
        return try self.fdct(quanta: quanta).compress(path: path)
    }
}
extension JPEG.Data.Rectangular
{
    /// Decompresses a rectangular image from the given file path.
    ///
    /// This function is a convenience function which calls ``Planar.decompress(path:)``
    /// to obtain a planar image, and then calls ``Planar/interleaved(cosite:)``
    /// on the output to return a rectangular image.
    ///
    /// This function is only available on MacOS and Linux platforms.
    ///
    /// -   Parameter path:
    ///     A file path.
    ///
    /// -   Parameter cosited:
    ///     The upsampling method to use. Setting this parameter to `true` co-sites
    ///     the samples; setting it to `false` centers them instead.
    ///
    ///     The default value is `false`.
    ///
    /// -   Returns:
    ///     The decompressed image, or `nil` if the file could not be opened at
    ///     the given file path.
    public static
    func decompress(path:String, cosite cosited:Bool = false) throws -> Self?
    {
        guard let planar:JPEG.Data.Planar<Format> = try .decompress(path: path)
        else
        {
            return nil
        }

        return planar.interleaved(cosite: cosited)
    }
    /// Compresses a rectangular image to the given file path.
    ///
    /// All metadata records in this image will be emitted at the beginning of
    /// the outputted file, in the order they appear in the ``metadata`` array.
    ///
    /// This function is a convenience function which calls ``decomposed()``
    /// to obtain a planar image, and then calls ``Planar/compress(path:quanta:)``
    /// on the output.
    ///
    /// This function is only available on MacOS and Linux platforms.
    ///
    /// -   Parameter path:
    ///     A file path.
    ///
    /// -   Parameter quanta:
    ///     The quantum values for each quanta key used by this image’s ``layout``,
    ///     including quanta keys used only by non-recognized components. Each
    ///     array of quantum values must have exactly 64 elements. The quantization
    ///     tables created from these values will be encoded using integers with a bit width
    ///     determined by this image’s `layout.format.precision`,
    ///     and all the values must be in the correct range for that bit width.
    ///
    /// -   Returns:
    ///     A ``Void`` tuple, or `nil` if the file could not be opened at
    ///     the given file path.
    public
    func compress(path:String, quanta:[JPEG.Table.Quantization.Key: [UInt16]]) throws
        -> Void?
    {
        try self.decomposed().compress(path: path, quanta: quanta)
    }
}

#endif
