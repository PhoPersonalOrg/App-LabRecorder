import Foundation

enum SegmentedLayoutTab: String, CaseIterable, Identifiable, Sendable {
    case streams = "Streams"
    case studyBids = "Study & BIDS"
    case telemetry = "Telemetry/Storage"

    var id: String { rawValue }
}

enum StreamSignalStyle: Sendable, Equatable {
    case bars([CGFloat])
    case badge(String)
    case dot
    case idleLabel(String)
}

enum StreamTagStyle: Sendable, Equatable {
    case eeg
    case imu
    case contactQuality
    case markers
    case asr
    case video
    case notes
    case idle
}

struct SegmentedStreamRowModel: Identifiable, Sendable, Equatable {
    let id: String
    var name: String
    var host: String
    var tag: String
    var tagStyle: StreamTagStyle
    var rateLabel: String?
    var isSelected: Bool
    var signal: StreamSignalStyle
}

struct SegmentedHUDModel: Sendable, Equatable {
    var statusTitle: String
    var loggedDuration: String
    var rcsPort: String
    var duration: String
    var dataSize: String
    var streamsSummary: String
    var isStandby: Bool
}

struct SegmentedStudyBidsModel: Sendable, Equatable {
    var studyRootDisplay: String
    var freeSpaceLabel: String
    var bidsEnabled: Bool
    var participant: String
    var session: String
    var task: String
    var modality: String
    var runCounter: Int
    var rcsEnabled: Bool
    var templateTokens: [String]
}

struct SegmentedLayoutModel: Sendable, Equatable {
    var appTitle: String
    var versionBadge: String
    var hubSubtitle: String
    var hud: SegmentedHUDModel
    var streams: [SegmentedStreamRowModel]
    var studyBids: SegmentedStudyBidsModel
    var outputFilename: String
    var isRecording: Bool
    var isLocked: Bool
}
