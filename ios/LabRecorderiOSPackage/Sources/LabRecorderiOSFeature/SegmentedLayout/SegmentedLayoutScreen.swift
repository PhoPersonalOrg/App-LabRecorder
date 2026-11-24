import SwiftUI

/// Stitch screen: Lab Recorder - Segmented Layout
/// Project `15853052594003468744` / screen `568ec19f8f734677b29b6651beb5a498`
public struct SegmentedLayoutScreen: View {
    @Binding private var activeRecordingPath: String

    @State private var model: SegmentedLayoutModel
    @State private var selectedTab: SegmentedLayoutTab = .streams
    @State private var isRefreshing = false
    @State private var studyRoot: String = ""
    @State private var pathTemplate: String = "LabRecorder_%datetime_eeg.xdf"
    @State private var recordingEngine: RecordingEngine?
    @State private var recordingPath: String = ""
    @State private var recordingStartTime: Date?
    @State private var recordingElapsedSeconds: Int = 0
    @State private var recordingFileSizeKB: Int64 = 0
    public init(activeRecordingPath: Binding<String> = .constant("")) {
        _activeRecordingPath = activeRecordingPath
        _model = State(initialValue: SegmentedLayoutSampleData.preview)
    }

    init(activeRecordingPath: Binding<String> = .constant(""), model: SegmentedLayoutModel) {
        _activeRecordingPath = activeRecordingPath
        _model = State(initialValue: model)
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            LabRecorderDesignTokens.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                stickyHeader

                ScrollView {
                    tabContent
                        .padding(.horizontal, LabRecorderDesignTokens.Spacing.lg)
                        .padding(.top, LabRecorderDesignTokens.Spacing.md)
                        .padding(.bottom, LabRecorderDesignTokens.Spacing.bottomDockClearance)
                }
            }

            SegmentedLayoutBottomBar(
                isRecording: model.isRecording,
                isLocked: model.isLocked,
                onLock: { model.isLocked.toggle() },
                onPrimary: { toggleRecording() },
                onStop: { stopRecording() }
            )
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if studyRoot.isEmpty,
               let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path {
                studyRoot = doc
                model.studyBids.studyRootDisplay = shortenedPath(doc)
            }
            refreshHUDDerivedFields()
        }
        .task(id: model.isRecording) {
            guard model.isRecording else { return }
            while model.isRecording {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run {
                    if let start = recordingStartTime {
                        recordingElapsedSeconds = Int(Date().timeIntervalSince(start))
                    }
                    if !recordingPath.isEmpty,
                       let attrs = try? FileManager.default.attributesOfItem(atPath: recordingPath),
                       let size = attrs[.size] as? Int64 {
                        recordingFileSizeKB = size / 1024
                    }
                    refreshHUDDerivedFields()
                }
            }
        }
    }

    private var stickyHeader: some View {
        VStack(spacing: 0) {
            SegmentedLayoutHeaderView(
                title: model.appTitle,
                versionBadge: model.versionBadge,
                hubSubtitle: model.hubSubtitle
            )
            SegmentedLayoutHUDView(model: model.hud)
            SegmentedLayoutTabBar(selection: $selectedTab)
        }
        .background {
            LabRecorderDesignTokens.Colors.background.opacity(0.92)
                .background(.ultraThinMaterial.opacity(0.35))
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(LabRecorderDesignTokens.Colors.card)
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .streams:
            SegmentedLayoutStreamsTab(
                streams: $model.streams,
                onRefresh: { refreshStreams() }
            )
        case .studyBids:
            SegmentedLayoutStudyBidsTab(model: $model.studyBids)
        case .telemetry:
            SegmentedLayoutTelemetryTab(
                hud: model.hud,
                outputFilename: displayOutputFilename
            )
        }
    }

    private var displayOutputFilename: String {
        if model.isRecording, !recordingPath.isEmpty {
            return (recordingPath as NSString).lastPathComponent
        }
        return model.outputFilename
    }

    private var selectedCount: Int {
        model.streams.filter(\.isSelected).count
    }

    private func refreshStreams() {
        Task { await refreshStreamsAsync() }
    }

    private func refreshStreamsAsync() async {
        isRefreshing = true
        defer { isRefreshing = false }
        let resolver = LSLResolver()
        let infos = await resolver.resolveStreams(waitTime: 2.0)
        guard !infos.isEmpty else { return }
        let previousSelection = Dictionary(uniqueKeysWithValues: model.streams.map { ($0.id, $0.isSelected) })
        model.streams = infos.map { info in
            let sid = "\(info.name)|\(info.hostname)|\(info.sourceId)"
            return SegmentedStreamRowModel(
                id: sid,
                name: info.name,
                host: info.hostname,
                tag: info.type.isEmpty ? "LSL Stream" : info.type,
                tagStyle: .notes,
                rateLabel: nil,
                isSelected: previousSelection[sid] ?? true,
                signal: .dot
            )
        }
        refreshHUDDerivedFields()
    }

    private func toggleRecording() {
        if model.isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        guard !model.isLocked else { return }
        let selected = model.streams.filter(\.isSelected)
        guard !selected.isEmpty else { return }

        // Live recording requires refreshed LSL stream infos.
        Task {
            let resolver = LSLResolver()
            let infos = await resolver.resolveStreams(waitTime: 1.5)
            let selectedNames = Set(selected.map(\.name))
            let matched = infos.filter { selectedNames.contains($0.name) }
            guard !matched.isEmpty else {
                await MainActor.run {
                    // Preview / design mode: toggle visual recording state with sample data.
                    model.isRecording = true
                    model.hud.isStandby = false
                    model.hud.statusTitle = "RECORDING • LIVE"
                    recordingStartTime = Date()
                    recordingElapsedSeconds = 0
                    refreshHUDDerivedFields()
                }
                return
            }

            await MainActor.run {
                let path = resolvedPath
                let parent = (path as NSString).deletingLastPathComponent
                try? FileManager.default.createDirectory(atPath: parent, withIntermediateDirectories: true)
                let engine = RecordingEngine(filePath: path, streamInfos: matched)
                recordingEngine = engine
                recordingPath = path
                activeRecordingPath = path
                recordingStartTime = Date()
                recordingElapsedSeconds = 0
                recordingFileSizeKB = 0
                model.isRecording = true
                model.hud.isStandby = false
                model.hud.statusTitle = "RECORDING • LIVE"
                model.outputFilename = (path as NSString).lastPathComponent
                refreshHUDDerivedFields()
                Task { try? await engine.start() }
            }
        }
    }

    private func stopRecording() {
        guard !model.isLocked else { return }
        guard let engine = recordingEngine else {
            model.isRecording = false
            model.hud.isStandby = true
            model.hud.statusTitle = "STANDBY • READY"
            recordingStartTime = nil
            activeRecordingPath = ""
            refreshHUDDerivedFields()
            return
        }
        Task {
            await engine.stop()
            await MainActor.run {
                recordingEngine = nil
                recordingPath = ""
                activeRecordingPath = ""
                recordingStartTime = nil
                model.isRecording = false
                model.hud.isStandby = true
                model.hud.statusTitle = "STANDBY • READY"
                refreshHUDDerivedFields()
            }
        }
    }

    private var resolvedPath: String {
        let root = studyRoot.isEmpty
            ? (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? "")
            : studyRoot
        let replaced = pathTemplate
            .replacingOccurrences(of: "%datetime", with: iso8601FilenameSafe())
            .replacingOccurrences(of: "%date", with: dateToken())
            .replacingOccurrences(of: "%time", with: timeToken())
            .replacingOccurrences(of: "%hostname", with: hostnameToken())
        return (root as NSString).appendingPathComponent(replaced)
    }

    private func refreshHUDDerivedFields() {
        let minutes = recordingElapsedSeconds / 60
        let secs = recordingElapsedSeconds % 60
        let hours = minutes / 60
        let mins = minutes % 60
        model.hud.duration = String(format: "%02d:%02d:%02d", hours, mins, secs)
        model.hud.dataSize = "\(recordingFileSizeKB) KB"
        let active = selectedCount
        let total = model.streams.count
        model.hud.streamsSummary = "\(active) of \(total) Active"
    }

    private func shortenedPath(_ path: String) -> String {
        let parts = path.split(separator: "/").suffix(2)
        guard !parts.isEmpty else { return path }
        return ".../" + parts.joined(separator: "/")
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

#Preview("Segmented Layout") {
    SegmentedLayoutScreen()
}

#Preview("Recording State") {
    var model = SegmentedLayoutSampleData.preview
    model.isRecording = true
    model.hud.isStandby = false
    model.hud.statusTitle = "RECORDING • LIVE"
    model.hud.duration = "00:04:12"
    model.hud.dataSize = "2.4 MB"
    return SegmentedLayoutScreen(model: model)
}
