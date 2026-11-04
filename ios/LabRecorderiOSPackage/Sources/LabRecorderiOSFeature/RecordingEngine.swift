import Foundation

/// Coordinates multi-stream LSL recording into a single XDF file: headers phase, streaming phase, boundary chunks, then footers.
public final class RecordingEngine: @unchecked Sendable {
    public static let boundaryInterval: TimeInterval = 10.0
    public static let chunkPollInterval: TimeInterval = 0.5

    private let filePath: String
    private let streamInfos: [LSLStreamInfo]
    private var writer: XDFWriter?
    private var streamIds: [String: StreamId] = [:]
    private let writeQueue = DispatchQueue(label: "RecordingEngine.write")
    private var boundaryTask: Task<Void, Never>?
    private var streamTasks: [Task<Void, Never>] = []
    private let lock = NSLock()
    private var _stopped = false

    public init(filePath: String, streamInfos: [LSLStreamInfo]) {
        self.filePath = filePath
        self.streamInfos = streamInfos
    }

    /// Start recording: create file, open inlets, write stream headers, then pull samples until stop.
    public func start() async throws {
        stopped = false
        let w = try XDFWriter(filePath: filePath)
        writer = w
        var nextStreamId: StreamId = 1
        for info in streamInfos {
            let key = "\(info.name)|\(info.hostname)|\(info.sourceId)"
            streamIds[key] = nextStreamId
            nextStreamId += 1
        }

        // Open inlets first so we can write full stream headers (with extended description).
        var opened: [(info: LSLStreamInfo, inlet: LSLInlet)] = []
        for info in streamInfos {
            let inlet = LSLInlet(streamInfo: info)
            try await inlet.openStream()
            opened.append((inlet.streamInfo, inlet))
            let key = "\(info.name)|\(info.hostname)|\(info.sourceId)"
            guard let streamId = streamIds[key] else { continue }
            w.writeStreamHeader(streamId: streamId, content: inlet.streamInfo.asXml)
        }

        streamTasks = opened.map { pair in
            Task {
                await self.recordOpenedStream(info: pair.info, inlet: pair.inlet)
            }
        }
        boundaryTask = Task {
            await runBoundaryLoop()
        }
    }

    /// Stop recording: signal stop, wait for stream tasks, write footers, close file.
    public func stop() async {
        stopped = true
        for t in streamTasks {
            t.cancel()
        }
        for t in streamTasks {
            _ = await t.result
        }
        streamTasks = []
        boundaryTask?.cancel()
        _ = await boundaryTask?.result
        boundaryTask = nil
        guard let w = writer else { return }
        for info in streamInfos {
            guard let streamId = streamIds["\(info.name)|\(info.hostname)|\(info.sourceId)"] else { continue }
            let footer = "<?xml version=\"1.0\"?><info><first_timestamp>0</first_timestamp><last_timestamp>0</last_timestamp><sample_count>0</sample_count><clock_offsets></clock_offsets></info>"
            w.writeStreamFooter(streamId: streamId, content: footer)
        }
        try? w.close()
        writer = nil
    }

    private func recordOpenedStream(info: LSLStreamInfo, inlet: LSLInlet) async {
        defer { inlet.close() }
        let key = "\(info.name)|\(info.hostname)|\(info.sourceId)"
        guard let streamId = streamIds[key] else { return }
        let nChannels = info.channelCount
        while !stopped && !Task.isCancelled {
            guard let chunk = await inlet.pullChunk(maxSamples: 100, timeout: Self.chunkPollInterval) else {
                try? await Task.sleep(nanoseconds: 50_000_000)
                continue
            }
            writeQueue.sync {
                guard let writer = self.writer else { return }
                switch chunk {
                case .float32(let timestamps, let samples):
                    try? writer.writeDataChunk(streamId: streamId, timestamps: timestamps, samples: samples, nChannels: nChannels)
                case .double64(let timestamps, let samples):
                    try? writer.writeDataChunk(streamId: streamId, timestamps: timestamps, samples: samples, nChannels: nChannels)
                case .int32(let timestamps, let samples):
                    try? writer.writeDataChunk(streamId: streamId, timestamps: timestamps, samples: samples, nChannels: nChannels)
                case .int16(let timestamps, let samples):
                    try? writer.writeDataChunk(streamId: streamId, timestamps: timestamps, samples: samples, nChannels: nChannels)
                case .int8(let timestamps, let samples):
                    try? writer.writeDataChunk(streamId: streamId, timestamps: timestamps, samples: samples, nChannels: nChannels)
                case .string:
                    break
                }
            }
        }
    }

    private var stopped: Bool {
        get { lock.lock(); defer { lock.unlock() }; return _stopped }
        set { lock.lock(); _stopped = newValue; lock.unlock() }
    }

    private func runBoundaryLoop() async {
        while !stopped && !Task.isCancelled {
            try? await Task.sleep(nanoseconds: UInt64(Self.boundaryInterval * 1_000_000_000))
            guard !stopped, !Task.isCancelled else { break }
            writeQueue.sync {
                self.writer?.writeBoundaryChunk()
            }
        }
    }
}
