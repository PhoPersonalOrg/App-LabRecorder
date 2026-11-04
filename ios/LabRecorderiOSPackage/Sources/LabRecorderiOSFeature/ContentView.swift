import SwiftUI

public struct ContentView: View {
    @State private var streamItems: [StreamItem] = []
    @State private var isRefreshing = false
    @State private var studyRoot: String = ""
    @State private var pathTemplate: String = "LabRecorder_%datetime_eeg.xdf"
    @State private var isRecording = false
    @State private var recordingElapsedSeconds: Int = 0
    @State private var recordingFileSizeKB: Int64 = 0
    @State private var recordingEngine: RecordingEngine?
    @State private var recordingPath: String = ""
    @State private var recordingStartTime: Date?

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section("Record from Streams") {
                    if streamItems.isEmpty && !isRefreshing {
                        Text("No streams found. Tap Update to discover LSL streams on the network.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(Array(streamItems.enumerated()), id: \.element.id) { index, item in
                        StreamRowView(item: item, isSelected: $streamItems[index].isSelected)
                    }
                    Button(action: refreshStreams) {
                        Label("Update", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .accessibilityIdentifier("updateStreams")
                    .disabled(isRefreshing)
                }

                Section("Saving to") {
                    TextField("Study root", text: $studyRoot)
                    TextField("File name / Template", text: $pathTemplate)
                    if !resolvedPath.isEmpty {
                        Text(resolvedPath)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    HStack(spacing: 16) {
                        Button(action: startRecording) {
                            Label("Start", systemImage: "record.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("startRecording")
                        .disabled(isRecording || streamItems.filter(\.isSelected).isEmpty)

                        Button(action: stopRecording) {
                            Label("Stop", systemImage: "stop.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("stopRecording")
                        .disabled(!isRecording)
                    }
                }

                if isRecording {
                    Section("Status") {
                        Text(statusMessage)
                    }
                }
            }
            .navigationTitle("Lab Recorder")
            .task(id: isRecording) {
                guard isRecording else { return }
                while isRecording {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    await MainActor.run {
                        if let start = recordingStartTime {
                            recordingElapsedSeconds = Int(Date().timeIntervalSince(start))
                        }
                        if !recordingPath.isEmpty, let attrs = try? FileManager.default.attributesOfItem(atPath: recordingPath), let size = attrs[.size] as? Int64 {
                            recordingFileSizeKB = size / 1024
                        }
                    }
                }
            }
            .refreshable {
                await refreshStreamsAsync()
            }
            .onAppear {
                if studyRoot.isEmpty, let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path {
                    studyRoot = doc
                }
            }
        }
    }

    private var resolvedPath: String {
        let root = studyRoot.isEmpty ? (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? "") : studyRoot
        let replaced = pathTemplate
            .replacingOccurrences(of: "%datetime", with: iso8601FilenameSafe())
            .replacingOccurrences(of: "%date", with: dateToken())
            .replacingOccurrences(of: "%time", with: timeToken())
            .replacingOccurrences(of: "%hostname", with: hostnameToken())
        return (root as NSString).appendingPathComponent(replaced)
    }

    private var statusMessage: String {
        let minutes = recordingElapsedSeconds / 60
        let secs = recordingElapsedSeconds % 60
        let path = recordingPath.isEmpty ? resolvedPath : recordingPath
        return "Recording to \(path) (\(String(format: "%d:%02d", minutes, secs)); \(recordingFileSizeKB) kb)"
    }

    private func refreshStreams() {
        Task { await refreshStreamsAsync() }
    }

    private func refreshStreamsAsync() async {
        isRefreshing = true
        defer { isRefreshing = false }
        let resolver = LSLResolver()
        let infos = await resolver.resolveStreams(waitTime: 2.0)
        let newItems = infos.map { info in
            let sid = "\(info.name)|\(info.hostname)|\(info.sourceId)"
            let wasSelected = streamItems.first { $0.id == sid }?.isSelected ?? false
            return StreamItem(id: sid, name: info.name, type: info.type, host: info.hostname, isSelected: wasSelected, streamInfo: info)
        }
        streamItems = newItems
    }

    private func startRecording() {
        let selected = streamItems.filter(\.isSelected).compactMap(\.streamInfo)
        guard !selected.isEmpty else { return }
        let path = resolvedPath
        let parent = (path as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: parent, withIntermediateDirectories: true)
        let engine = RecordingEngine(filePath: path, streamInfos: selected)
        recordingEngine = engine
        recordingPath = path
        recordingStartTime = Date()
        recordingElapsedSeconds = 0
        recordingFileSizeKB = 0
        isRecording = true
        Task {
            try? await engine.start()
        }
    }

    private func stopRecording() {
        guard let engine = recordingEngine else { isRecording = false; return }
        Task {
            await engine.stop()
            await MainActor.run {
                recordingEngine = nil
                recordingPath = ""
                recordingStartTime = nil
                isRecording = false
            }
        }
    }

    private func iso8601FilenameSafe() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")
    }

    private func dateToken() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.string(from: Date())
    }

    private func timeToken() -> String {
        let f = DateFormatter()
        f.dateFormat = "HH-mm-ss"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.string(from: Date())
    }

    private func hostnameToken() -> String {
        let invalid = CharacterSet(charactersIn: "<>:\"/\\|?* \n\r")
        return ProcessInfo.processInfo.hostName
            .unicodeScalars
            .map { invalid.contains($0) ? "_" : String($0) }
            .joined()
    }
}

struct StreamItem: Identifiable {
    let id: String
    let name: String
    let type: String
    let host: String
    var isSelected: Bool
    let streamInfo: LSLStreamInfo?
}

struct StreamRowView: View {
    let item: StreamItem
    @Binding var isSelected: Bool

    var body: some View {
        HStack {
            Text("\(item.name) (\(item.host))")
            Spacer()
            Toggle("", isOn: $isSelected)
                .labelsHidden()
        }
    }
}

#Preview {
    ContentView()
}
