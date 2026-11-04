import Foundation
import lsl

/// Sample chunk pulled from an LSL inlet; format matches stream's channel_format.
public enum LSLSampleChunk: Sendable {
    case float32(timestamps: [Double], samples: [Float])
    case double64(timestamps: [Double], samples: [Double])
    case int32(timestamps: [Double], samples: [Int32])
    case int16(timestamps: [Double], samples: [Int16])
    case int8(timestamps: [Double], samples: [Int8])
    case string(timestamps: [Double], samples: [[String]])
}

/// Inlet for consuming an LSL stream via liblsl.
public final class LSLInlet: @unchecked Sendable {
    public private(set) var streamInfo: LSLStreamInfo
    private var inlet: lsl_inlet?
    private let openTimeout: TimeInterval = 5.0

    public init(streamInfo: LSLStreamInfo) {
        self.streamInfo = streamInfo
    }

    /// Open the stream connection and refresh full stream metadata for XDF headers.
    public func openStream() async throws {
        try await Task.detached(priority: .userInitiated) { [self] in
            try self.openStreamBlocking()
        }.value
    }

    private func openStreamBlocking() throws {
        guard let handle = streamInfo.handle else {
            throw NSError(domain: "LSLInlet", code: -2, userInfo: [NSLocalizedDescriptionKey: "Missing native stream info handle"])
        }
        guard let created = lsl_create_inlet(handle.raw, 360, 0, 1) else {
            throw NSError(domain: "LSLInlet", code: -3, userInfo: [NSLocalizedDescriptionKey: "lsl_create_inlet failed"])
        }
        var ec: Int32 = 0
        lsl_open_stream(created, openTimeout, &ec)
        if ec != 0 {
            lsl_destroy_inlet(created)
            throw NSError(domain: "LSLInlet", code: Int(ec), userInfo: [NSLocalizedDescriptionKey: "lsl_open_stream failed (\(ec))"])
        }
        // Prefer full info (includes extended description) for the XDF stream header.
        if let full = lsl_get_fullinfo(created, openTimeout, &ec), ec == 0 {
            streamInfo = LSLStreamInfo(consuming: full)
        }
        inlet = created
    }

    /// Pull a chunk of samples. Returns nil on timeout or empty buffer.
    public func pullChunk(maxSamples: Int = 100, timeout: TimeInterval = 0.5) async -> LSLSampleChunk? {
        await Task.detached(priority: .userInitiated) { [self] in
            self.pullChunkBlocking(maxSamples: maxSamples, timeout: timeout)
        }.value
    }

    private func pullChunkBlocking(maxSamples: Int, timeout: TimeInterval) -> LSLSampleChunk? {
        guard let inlet else { return nil }
        let channelCount = Int(streamInfo.channelCount)
        guard channelCount > 0 else { return nil }
        let maxSamp = max(1, maxSamples)
        var timestamps = [Double](repeating: 0, count: maxSamp)
        var ec: Int32 = 0

        switch streamInfo.channelFormat {
        case .float32:
            var data = [Float](repeating: 0, count: maxSamp * channelCount)
            let written = data.withUnsafeMutableBufferPointer { dPtr in
                timestamps.withUnsafeMutableBufferPointer { tPtr in
                    lsl_pull_chunk_f(
                        inlet,
                        dPtr.baseAddress,
                        tPtr.baseAddress,
                        UInt(dPtr.count),
                        UInt(tPtr.count),
                        timeout,
                        &ec
                    )
                }
            }
            guard ec == 0, written > 0 else { return nil }
            let nSamples = Int(written) / channelCount
            return .float32(timestamps: Array(timestamps.prefix(nSamples)), samples: Array(data.prefix(nSamples * channelCount)))
        case .double64:
            var data = [Double](repeating: 0, count: maxSamp * channelCount)
            let written = data.withUnsafeMutableBufferPointer { dPtr in
                timestamps.withUnsafeMutableBufferPointer { tPtr in
                    lsl_pull_chunk_d(
                        inlet,
                        dPtr.baseAddress,
                        tPtr.baseAddress,
                        UInt(dPtr.count),
                        UInt(tPtr.count),
                        timeout,
                        &ec
                    )
                }
            }
            guard ec == 0, written > 0 else { return nil }
            let nSamples = Int(written) / channelCount
            return .double64(timestamps: Array(timestamps.prefix(nSamples)), samples: Array(data.prefix(nSamples * channelCount)))
        case .int32:
            var data = [Int32](repeating: 0, count: maxSamp * channelCount)
            let written = data.withUnsafeMutableBufferPointer { dPtr in
                timestamps.withUnsafeMutableBufferPointer { tPtr in
                    lsl_pull_chunk_i(
                        inlet,
                        dPtr.baseAddress,
                        tPtr.baseAddress,
                        UInt(dPtr.count),
                        UInt(tPtr.count),
                        timeout,
                        &ec
                    )
                }
            }
            guard ec == 0, written > 0 else { return nil }
            let nSamples = Int(written) / channelCount
            return .int32(timestamps: Array(timestamps.prefix(nSamples)), samples: Array(data.prefix(nSamples * channelCount)))
        case .int16:
            var data = [Int16](repeating: 0, count: maxSamp * channelCount)
            let written = data.withUnsafeMutableBufferPointer { dPtr in
                timestamps.withUnsafeMutableBufferPointer { tPtr in
                    lsl_pull_chunk_s(
                        inlet,
                        dPtr.baseAddress,
                        tPtr.baseAddress,
                        UInt(dPtr.count),
                        UInt(tPtr.count),
                        timeout,
                        &ec
                    )
                }
            }
            guard ec == 0, written > 0 else { return nil }
            let nSamples = Int(written) / channelCount
            return .int16(timestamps: Array(timestamps.prefix(nSamples)), samples: Array(data.prefix(nSamples * channelCount)))
        case .int8:
            var data = [Int8](repeating: 0, count: maxSamp * channelCount)
            let written = data.withUnsafeMutableBufferPointer { dPtr in
                timestamps.withUnsafeMutableBufferPointer { tPtr in
                    lsl_pull_chunk_c(
                        inlet,
                        dPtr.baseAddress,
                        tPtr.baseAddress,
                        UInt(dPtr.count),
                        UInt(tPtr.count),
                        timeout,
                        &ec
                    )
                }
            }
            guard ec == 0, written > 0 else { return nil }
            let nSamples = Int(written) / channelCount
            return .int8(timestamps: Array(timestamps.prefix(nSamples)), samples: Array(data.prefix(nSamples * channelCount)))
        case .string, .undefined:
            return nil
        }
    }

    public func close() {
        if let inlet {
            lsl_close_stream(inlet)
            lsl_destroy_inlet(inlet)
        }
        inlet = nil
    }

    deinit {
        close()
    }
}
