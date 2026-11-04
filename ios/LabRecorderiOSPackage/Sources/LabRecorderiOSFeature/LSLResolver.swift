import Foundation
import lsl

/// Resolves LSL streams on the local network via liblsl.
public actor LSLResolver {
    /// Resolve streams for up to `waitTime` seconds.
    public func resolveStreams(waitTime: Double = 2.0) async -> [LSLStreamInfo] {
        await Task.detached(priority: .userInitiated) {
            Self.resolveBlocking(waitTime: waitTime)
        }.value
    }

    private static func resolveBlocking(waitTime: Double) -> [LSLStreamInfo] {
        let capacity = 64
        let buffer = UnsafeMutablePointer<lsl_streaminfo?>.allocate(capacity: capacity)
        defer { buffer.deallocate() }
        buffer.initialize(repeating: nil, count: capacity)
        let count = lsl_resolve_all(buffer, UInt32(capacity), waitTime)
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
