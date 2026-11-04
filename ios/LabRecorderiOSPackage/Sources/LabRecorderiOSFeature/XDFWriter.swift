import Foundation

/// XDF chunk tags; must match C++ xdfwriter for file compatibility.
public enum XDFChunkTag: UInt16 {
    case fileheader = 1
    case streamheader = 2
    case samples = 3
    case clockoffset = 4
    case boundary = 5
    case streamfooter = 6
}

public typealias StreamId = UInt32

/// Thread-safe XDF file writer. Writes magic, file header, then stream headers, sample chunks, clock offsets, boundaries, and stream footers.
public final class XDFWriter: @unchecked Sendable {
    private let fileHandle: FileHandle
    private let lock = NSLock()
    private let boundaryUUID: [UInt8] = [0x43, 0xA5, 0x46, 0xDC, 0xCB, 0xF5, 0x41, 0x0F, 0xB3, 0x0E, 0xD5, 0x46, 0x73, 0x83, 0xCB, 0xE4]

    public init(fileURL: URL) throws {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
        FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        guard let handle = try? FileHandle(forWritingTo: fileURL) else {
            throw NSError(domain: "XDFWriter", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not open file for writing"])
        }
        self.fileHandle = handle
        try writeMagicAndFileHeader()
    }

    public convenience init(filePath: String) throws {
        try self.init(fileURL: URL(fileURLWithPath: filePath))
    }

    private func writeMagicAndFileHeader() throws {
        lock.lock()
        defer { lock.unlock() }
        writeString("XDF:")
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.timeZone = TimeZone.current
        let datetime = formatter.string(from: Date())
        let header = "<?xml version=\"1.0\"?>\n  <info>\n    <version>1.0</version>\n    <datetime>\(datetime)</datetime>\n  </info>"
        writeChunk(tag: .fileheader, content: header, streamId: nil)
    }

    private func writeVarlenInt(_ val: UInt64) {
        if val < 256 {
            writeUInt8(1)
            writeUInt8(UInt8(val))
        } else if val <= 4_294_967_295 {
            writeUInt8(4)
            writeUInt32(UInt32(val))
        } else {
            writeUInt8(8)
            writeUInt64(val)
        }
    }

    private func writeUInt8(_ v: UInt8) {
        fileHandle.write(Data([v]))
    }

    private func writeUInt16(_ v: UInt16) {
        var le = v.littleEndian
        fileHandle.write(Data(bytes: &le, count: 2))
    }

    private func writeUInt32(_ v: UInt32) {
        var le = v.littleEndian
        fileHandle.write(Data(bytes: &le, count: 4))
    }

    private func writeUInt64(_ v: UInt64) {
        var le = v.littleEndian
        fileHandle.write(Data(bytes: &le, count: 8))
    }

    private func writeDouble(_ v: Double) {
        var le = v.bitPattern.littleEndian
        fileHandle.write(Data(bytes: &le, count: 8))
    }

    private func writeString(_ s: String) {
        fileHandle.write(Data(s.utf8))
    }

    private func writeChunkHeader(tag: XDFChunkTag, contentLength: Int, streamId: StreamId?) {
        var len = contentLength + 2
        if streamId != nil { len += 4 }
        writeVarlenInt(UInt64(len))
        writeUInt16(tag.rawValue)
        if let sid = streamId { writeUInt32(sid) }
    }

    private func writeChunk(tag: XDFChunkTag, content: String, streamId: StreamId?) {
        let data = Data(content.utf8)
        writeChunkHeader(tag: tag, contentLength: data.count, streamId: streamId)
        fileHandle.write(data)
    }

    public func writeStreamHeader(streamId: StreamId, content: String) {
        lock.lock()
        defer { lock.unlock() }
        writeChunk(tag: .streamheader, content: content, streamId: streamId)
    }

    public func writeStreamFooter(streamId: StreamId, content: String) {
        lock.lock()
        defer { lock.unlock() }
        writeChunk(tag: .streamfooter, content: content, streamId: streamId)
    }

    public func writeStreamOffset(streamId: StreamId, collectionTime: Double, offset: Double) {
        lock.lock()
        defer { lock.unlock() }
        writeChunkHeader(tag: .clockoffset, contentLength: 16, streamId: streamId)
        writeDouble(collectionTime - offset)
        writeDouble(offset)
    }

    public func writeBoundaryChunk() {
        lock.lock()
        defer { lock.unlock() }
        writeChunkHeader(tag: .boundary, contentLength: boundaryUUID.count, streamId: nil)
        fileHandle.write(Data(boundaryUUID))
    }

    private func writeTimestamp(_ ts: Double) {
        if ts == 0 {
            writeUInt8(0)
        } else {
            writeUInt8(8)
            writeDouble(ts)
        }
    }

    private func appendTimestamp(to data: inout Data, _ ts: Double) {
        if ts == 0 {
            data.append(0)
        } else {
            data.append(8)
            var le = ts.bitPattern.littleEndian
            data.append(Data(bytes: &le, count: 8))
        }
    }

    /// Write a Samples chunk (float32). timestamps.count must equal samples.count / nChannels.
    public func writeDataChunk(streamId: StreamId, timestamps: [Double], samples: [Float], nChannels: UInt32) throws {
        let nSamples = UInt32(timestamps.count)
        guard nSamples > 0, samples.count == timestamps.count * Int(nChannels) else { return }
        var content = Data()
        content.append(4)
        var nLe = nSamples.littleEndian
        content.append(Data(bytes: &nLe, count: 4))
        for i in 0..<timestamps.count {
            appendTimestamp(to: &content, timestamps[i])
            let base = i * Int(nChannels)
            for c in 0..<nChannels {
                var v = samples[base + Int(c)].bitPattern.littleEndian
                content.append(Data(bytes: &v, count: 4))
            }
        }
        lock.lock()
        defer { lock.unlock() }
        writeChunkHeader(tag: .samples, contentLength: content.count, streamId: streamId)
        fileHandle.write(content)
    }

    /// Write a Samples chunk (double64).
    public func writeDataChunk(streamId: StreamId, timestamps: [Double], samples: [Double], nChannels: UInt32) throws {
        let nSamples = UInt32(timestamps.count)
        guard nSamples > 0, samples.count == timestamps.count * Int(nChannels) else { return }
        var content = Data()
        content.append(4)
        var nLe = nSamples.littleEndian
        content.append(Data(bytes: &nLe, count: 4))
        for i in 0..<timestamps.count {
            appendTimestamp(to: &content, timestamps[i])
            let base = i * Int(nChannels)
            for c in 0..<nChannels {
                var v = samples[base + Int(c)].bitPattern.littleEndian
                content.append(Data(bytes: &v, count: 8))
            }
        }
        lock.lock()
        defer { lock.unlock() }
        writeChunkHeader(tag: .samples, contentLength: content.count, streamId: streamId)
        fileHandle.write(content)
    }

    /// Write a Samples chunk (int32).
    public func writeDataChunk(streamId: StreamId, timestamps: [Double], samples: [Int32], nChannels: UInt32) throws {
        let nSamples = UInt32(timestamps.count)
        guard nSamples > 0, samples.count == timestamps.count * Int(nChannels) else { return }
        var content = Data()
        content.append(4)
        var nLe = nSamples.littleEndian
        content.append(Data(bytes: &nLe, count: 4))
        for i in 0..<timestamps.count {
            appendTimestamp(to: &content, timestamps[i])
            let base = i * Int(nChannels)
            for c in 0..<nChannels {
                var v = samples[base + Int(c)].littleEndian
                content.append(Data(bytes: &v, count: 4))
            }
        }
        lock.lock()
        defer { lock.unlock() }
        writeChunkHeader(tag: .samples, contentLength: content.count, streamId: streamId)
        fileHandle.write(content)
    }

    /// Write a Samples chunk (int16).
    public func writeDataChunk(streamId: StreamId, timestamps: [Double], samples: [Int16], nChannels: UInt32) throws {
        let nSamples = UInt32(timestamps.count)
        guard nSamples > 0, samples.count == timestamps.count * Int(nChannels) else { return }
        var content = Data()
        content.append(4)
        var nLe = nSamples.littleEndian
        content.append(Data(bytes: &nLe, count: 4))
        for i in 0..<timestamps.count {
            appendTimestamp(to: &content, timestamps[i])
            let base = i * Int(nChannels)
            for c in 0..<nChannels {
                var v = samples[base + Int(c)].littleEndian
                content.append(Data(bytes: &v, count: 2))
            }
        }
        lock.lock()
        defer { lock.unlock() }
        writeChunkHeader(tag: .samples, contentLength: content.count, streamId: streamId)
        fileHandle.write(content)
    }

    /// Write a Samples chunk (int8).
    public func writeDataChunk(streamId: StreamId, timestamps: [Double], samples: [Int8], nChannels: UInt32) throws {
        let nSamples = UInt32(timestamps.count)
        guard nSamples > 0, samples.count == timestamps.count * Int(nChannels) else { return }
        var content = Data()
        content.append(4)
        var nLe = nSamples.littleEndian
        content.append(Data(bytes: &nLe, count: 4))
        for i in 0..<timestamps.count {
            appendTimestamp(to: &content, timestamps[i])
            let base = i * Int(nChannels)
            for c in 0..<nChannels {
                content.append(UInt8(bitPattern: samples[base + Int(c)]))
            }
        }
        lock.lock()
        defer { lock.unlock() }
        writeChunkHeader(tag: .samples, contentLength: content.count, streamId: streamId)
        fileHandle.write(content)
    }

    public func close() throws {
        lock.lock()
        defer { lock.unlock() }
        try fileHandle.close()
    }

    deinit {
        try? fileHandle.close()
    }
}
