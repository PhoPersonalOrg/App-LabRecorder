import Foundation
import lsl

/// Resolves LSL streams on the local network via liblsl.
public actor LSLResolver {
    /// Resolve streams for up to `waitTime` seconds.
    public func resolveStreams(waitTime: Double = 1.0) async -> [LSLStreamInfo] {
        await Task.detached(priority: .userInitiated) {
            Self.resolveBlocking(waitTime: waitTime)
        }.value
    }

    private static func resolveBlocking(waitTime: Double) -> [LSLStreamInfo] {
        var buffer = [lsl_streaminfo?](repeating: nil, count: 64)
        let count = buffer.withUnsafeMutableBufferPointer { ptr -> Int32 in
            guard let base = ptr.baseAddress else { return 0 }
            return lsl_resolve_all(base, UInt32(ptr.count), waitTime)
        }
        guard count > 0 else { return [] }
        var results: [LSLStreamInfo] = []
        results.reserveCapacity(Int(count))
        for i in 0..<Int(count) {
            guard let raw = buffer[i] else { continue }
            results.append(LSLStreamInfo(consuming: raw))
        }
        return results
    }
}
