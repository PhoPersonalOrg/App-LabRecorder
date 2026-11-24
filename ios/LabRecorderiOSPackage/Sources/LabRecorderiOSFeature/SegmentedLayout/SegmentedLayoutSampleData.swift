import Foundation

enum SegmentedLayoutSampleData {
    static let preview = SegmentedLayoutModel(
        appTitle: "Lab Recorder",
        versionBadge: "LSL v1.16",
        hubSubtitle: "Apogee Lab Hub • Online",
        hud: SegmentedHUDModel(
            statusTitle: "STANDBY • READY",
            loggedDuration: "01:17:04 logged",
            rcsPort: "PORT 22345",
            duration: "00:00:00",
            dataSize: "0 KB",
            streamsSummary: "7 of 8 Active",
            isStandby: true
        ),
        streams: [
            SegmentedStreamRowModel(
                id: "epoc-x",
                name: "Epoc X",
                host: "Apogee",
                tag: "EEG • 14 Ch",
                tagStyle: .eeg,
                rateLabel: "128 Hz",
                isSelected: true,
                signal: .bars([0.4, 0.7, 1.0])
            ),
            SegmentedStreamRowModel(
                id: "epoc-motion",
                name: "Epoc X Motion",
                host: "Apogee",
                tag: "IMU / Gyro",
                tagStyle: .imu,
                rateLabel: "64 Hz",
                isSelected: true,
                signal: .bars([0.4, 0.7, 1.0])
            ),
            SegmentedStreamRowModel(
                id: "epoc-quality",
                name: "Epoc X eQuality",
                host: "Apogee",
                tag: "Contact Quality",
                tagStyle: .contactQuality,
                rateLabel: "4 Hz",
                isSelected: true,
                signal: .bars([0.55, 1.0])
            ),
            SegmentedStreamRowModel(
                id: "eventboard",
                name: "EventBoard",
                host: "Apogee",
                tag: "Markers / Triggers",
                tagStyle: .markers,
                rateLabel: "Irregular",
                isSelected: true,
                signal: .badge("TTL Synced")
            ),
            SegmentedStreamRowModel(
                id: "whisper",
                name: "WhisperLiveLogger",
                host: "Apogee",
                tag: "Audio / ASR",
                tagStyle: .asr,
                rateLabel: "16 kHz",
                isSelected: true,
                signal: .bars([0.85, 1.0])
            ),
            SegmentedStreamRowModel(
                id: "video",
                name: "VideoRecorderMarkers",
                host: "Apogee",
                tag: "Frame Timestamps",
                tagStyle: .video,
                rateLabel: "60 fps",
                isSelected: true,
                signal: .dot
            ),
            SegmentedStreamRowModel(
                id: "text",
                name: "TextLogger",
                host: "Apogee",
                tag: "Experiment Notes",
                tagStyle: .notes,
                rateLabel: nil,
                isSelected: true,
                signal: .dot
            ),
            SegmentedStreamRowModel(
                id: "mouse",
                name: "IOGraph_Mouse",
                host: "Apogee",
                tag: "Peripheral Input",
                tagStyle: .idle,
                rateLabel: "Excluded",
                isSelected: false,
                signal: .idleLabel("Idle")
            ),
        ],
        studyBids: SegmentedStudyBidsModel(
            studyRootDisplay: ".../LabRecorderStudies/sub-P001",
            freeSpaceLabel: "SSD 420 GB free",
            bidsEnabled: true,
            participant: "sub-P001",
            session: "ses-S001",
            task: "resting-state",
            modality: "eeg",
            runCounter: 1,
            rcsEnabled: true,
            templateTokens: ["%hostname", "%datetime", "%p (participant)", "%s (session)", "%b (task)"]
        ),
        outputFilename: "LabRecorder_Apogee_2026-11-24T130430.722Z_eeg.xdf",
        isRecording: false,
        isLocked: false
    )
}
