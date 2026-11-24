import SwiftUI

// MARK: - Streams Tab

struct SegmentedLayoutStreamsTab: View {
    @Binding var streams: [SegmentedStreamRowModel]
    var onRefresh: () -> Void

    var body: some View {
        // stitch-id: lsl-stream-selection
        VStack(alignment: .leading, spacing: LabRecorderDesignTokens.Spacing.md) {
            HStack {
                HStack(spacing: 6) {
                    Text("STREAMS TO RECORD")
                        .font(LabRecorderDesignTokens.Typography.section)
                        .tracking(1.2)
                        .foregroundStyle(LabRecorderDesignTokens.Colors.secondaryText)

                    Text("\(streams.count) FOUND")
                        .font(LabRecorderDesignTokens.Typography.monoMicro)
                        .foregroundStyle(LabRecorderDesignTokens.Colors.tagNeutralText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(LabRecorderDesignTokens.Colors.tagIdleFill)
                        .clipShape(RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.sm))
                }

                Spacer(minLength: 0)

                HStack(spacing: LabRecorderDesignTokens.Spacing.sm) {
                    Button("Select All") {
                        for index in streams.indices {
                            streams[index].isSelected = true
                        }
                    }
                    .font(LabRecorderDesignTokens.Typography.captionSemibold)
                    .foregroundStyle(LabRecorderDesignTokens.Colors.accent)

                    Text("|")
                        .font(LabRecorderDesignTokens.Typography.caption)
                        .foregroundStyle(LabRecorderDesignTokens.Colors.border)

                    Button("None") {
                        for index in streams.indices {
                            streams[index].isSelected = false
                        }
                    }
                    .font(LabRecorderDesignTokens.Typography.captionSemibold)
                    .foregroundStyle(LabRecorderDesignTokens.Colors.secondaryText)

                    Button(action: onRefresh) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(LabRecorderDesignTokens.Colors.tagNeutralText)
                            .frame(width: 24, height: 24)
                            .background(LabRecorderDesignTokens.Colors.tagIdleFill)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("updateStreams")
                    .accessibilityLabel("Update streams")
                }
            }
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach($streams) { $stream in
                    SegmentedLayoutStreamRow(model: $stream)
                    if stream.id != streams.last?.id {
                        Divider()
                            .background(LabRecorderDesignTokens.Colors.border)
                    }
                }
            }
            .background(LabRecorderDesignTokens.Colors.card)
            .overlay(
                RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.xl, style: .continuous)
                    .stroke(LabRecorderDesignTokens.Colors.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.xl, style: .continuous))
        }
    }
}

// MARK: - Study & BIDS Tab

struct SegmentedLayoutStudyBidsTab: View {
    @Binding var model: SegmentedStudyBidsModel

    private let modalities = ["eeg", "ieeg", "meg", "motion"]

    var body: some View {
        // stitch-id: bids-metadata-and-storage
        VStack(alignment: .leading, spacing: LabRecorderDesignTokens.Spacing.md) {
            Text("STUDY & STORAGE (BIDS)")
                .font(LabRecorderDesignTokens.Typography.section)
                .tracking(1.2)
                .foregroundStyle(LabRecorderDesignTokens.Colors.secondaryText)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                studyRootRow
                divider
                bidsToggleRow
                divider
                metadataGrid
                divider
                runCounterRow
                divider
                rcsRow
            }
            .background(LabRecorderDesignTokens.Colors.card)
            .overlay(
                RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.xl, style: .continuous)
                    .stroke(LabRecorderDesignTokens.Colors.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.xl, style: .continuous))
        }
    }

    private var studyRootRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Study Root Path")
                    .font(LabRecorderDesignTokens.Typography.captionSemibold)
                    .foregroundStyle(LabRecorderDesignTokens.Colors.tagNeutralText)
                Spacer()
                Label("Browse Files...", systemImage: "folder")
                    .font(LabRecorderDesignTokens.Typography.captionSemibold)
                    .foregroundStyle(LabRecorderDesignTokens.Colors.accent)
            }

            HStack {
                Text(model.studyRootDisplay)
                    .font(LabRecorderDesignTokens.Typography.caption.monospaced())
                    .foregroundStyle(LabRecorderDesignTokens.Colors.tagNeutralText)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: LabRecorderDesignTokens.Spacing.sm)
                Text(model.freeSpaceLabel.uppercased())
                    .font(LabRecorderDesignTokens.Typography.monoMicro)
                    .foregroundStyle(LabRecorderDesignTokens.Colors.secondaryText)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(LabRecorderDesignTokens.Colors.tagIdleFill)
                    .clipShape(RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.sm))
            }
            .padding(.horizontal, LabRecorderDesignTokens.Spacing.md)
            .padding(.vertical, LabRecorderDesignTokens.Spacing.sm)
            .background(LabRecorderDesignTokens.Colors.well)
            .overlay(
                RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.lg, style: .continuous)
                    .stroke(LabRecorderDesignTokens.Colors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.lg, style: .continuous))
        }
        .padding(LabRecorderDesignTokens.Spacing.md)
    }

    private var bidsToggleRow: some View {
        VStack(alignment: .leading, spacing: LabRecorderDesignTokens.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("BIDS Standard Format")
                        .font(LabRecorderDesignTokens.Typography.captionSemibold)
                        .foregroundStyle(LabRecorderDesignTokens.Colors.nearWhite)
                    Text("Brain Imaging Data Structure mapping")
                        .font(LabRecorderDesignTokens.Typography.caption)
                        .foregroundStyle(LabRecorderDesignTokens.Colors.secondaryText)
                }
                Spacer()
                Toggle("", isOn: $model.bidsEnabled)
                    .labelsHidden()
                    .tint(LabRecorderDesignTokens.Colors.green)
            }

            Text("TEMPLATE STRING TOKENS:")
                .font(LabRecorderDesignTokens.Typography.microSemibold)
                .tracking(0.8)
                .foregroundStyle(LabRecorderDesignTokens.Colors.secondaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(model.templateTokens.enumerated()), id: \.offset) { index, token in
                        Text(token)
                            .font(LabRecorderDesignTokens.Typography.caption.monospaced())
                            .foregroundStyle(tokenAccent(at: index).text)
                            .padding(.horizontal, LabRecorderDesignTokens.Spacing.sm)
                            .padding(.vertical, 2)
                            .background(tokenAccent(at: index).fill)
                            .overlay {
                                if let border = tokenAccent(at: index).border {
                                    RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.md)
                                        .stroke(border, lineWidth: 1)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.md))
                    }
                }
            }
        }
        .padding(LabRecorderDesignTokens.Spacing.md)
    }

    private var metadataGrid: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                metaField(title: "Participant (%p)", text: $model.participant)
                Rectangle().fill(LabRecorderDesignTokens.Colors.border).frame(width: 1)
                metaField(title: "Session (%s)", text: $model.session)
            }
            Rectangle().fill(LabRecorderDesignTokens.Colors.border).frame(height: 1)
            HStack(spacing: 0) {
                metaField(title: "Task / Block (%b)", text: $model.task)
                Rectangle().fill(LabRecorderDesignTokens.Colors.border).frame(width: 1)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Modality (%m)")
                        .font(LabRecorderDesignTokens.Typography.microSemibold)
                        .tracking(0.3)
                        .foregroundStyle(LabRecorderDesignTokens.Colors.secondaryText)
                        .textCase(.uppercase)
                    Picker("Modality", selection: $model.modality) {
                        ForEach(modalities, id: \.self) { value in
                            Text(value).tag(value)
                        }
                    }
                    .labelsHidden()
                    .tint(LabRecorderDesignTokens.Colors.cyan)
                }
                .padding(LabRecorderDesignTokens.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var runCounterRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Run Counter")
                    .font(LabRecorderDesignTokens.Typography.captionSemibold)
                    .foregroundStyle(LabRecorderDesignTokens.Colors.nearWhite)
                Text("Sequential acquisition index")
                    .font(LabRecorderDesignTokens.Typography.caption)
                    .foregroundStyle(LabRecorderDesignTokens.Colors.secondaryText)
            }
            Spacer()
            HStack(spacing: 0) {
                Button {
                    if model.runCounter > 1 { model.runCounter -= 1 }
                } label: {
                    Text("−")
                        .font(.system(size: 16, weight: .bold))
                        .frame(width: 32, height: 28)
                }
                Text("\(model.runCounter)")
                    .font(LabRecorderDesignTokens.Typography.monoBody)
                    .foregroundStyle(LabRecorderDesignTokens.Colors.primaryText)
                    .frame(width: 36)
                Button {
                    model.runCounter += 1
                } label: {
                    Text("+")
                        .font(.system(size: 16, weight: .bold))
                        .frame(width: 32, height: 28)
                }
            }
            .foregroundStyle(LabRecorderDesignTokens.Colors.primaryText)
            .padding(2)
            .background(LabRecorderDesignTokens.Colors.border)
            .overlay(
                RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.md)
                    .stroke(LabRecorderDesignTokens.Colors.borderSubtle.opacity(2), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.md))
        }
        .padding(LabRecorderDesignTokens.Spacing.md)
    }

    private var rcsRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Enable RCS Network Remote")
                    .font(LabRecorderDesignTokens.Typography.captionSemibold)
                    .foregroundStyle(LabRecorderDesignTokens.Colors.nearWhite)
                Text("Accept TCP/LSL commands on Port 22345")
                    .font(LabRecorderDesignTokens.Typography.caption)
                    .foregroundStyle(LabRecorderDesignTokens.Colors.secondaryText)
            }
            Spacer()
            Toggle("", isOn: $model.rcsEnabled)
                .labelsHidden()
                .tint(LabRecorderDesignTokens.Colors.green)
        }
        .padding(LabRecorderDesignTokens.Spacing.md)
    }

    private var divider: some View {
        Rectangle()
            .fill(LabRecorderDesignTokens.Colors.border)
            .frame(height: 1)
    }

    private func metaField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(LabRecorderDesignTokens.Typography.microSemibold)
                .tracking(0.3)
                .foregroundStyle(LabRecorderDesignTokens.Colors.secondaryText)
                .textCase(.uppercase)
            TextField("", text: text)
                .font(LabRecorderDesignTokens.Typography.monoBody)
                .foregroundStyle(LabRecorderDesignTokens.Colors.primaryText)
        }
        .padding(LabRecorderDesignTokens.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func tokenAccent(at index: Int) -> (fill: Color, text: Color, border: Color?) {
        switch index {
        case 0:
            return (LabRecorderDesignTokens.Colors.tagEEGFill, LabRecorderDesignTokens.Colors.tagEEGText, LabRecorderDesignTokens.Colors.tagEEGBorder)
        case 1:
            return (LabRecorderDesignTokens.Colors.tagASRFill, LabRecorderDesignTokens.Colors.tagASRText, LabRecorderDesignTokens.Colors.tagASRBorder)
        case 2:
            return (LabRecorderDesignTokens.Colors.tagIMUFill, LabRecorderDesignTokens.Colors.tagIMUText, LabRecorderDesignTokens.Colors.tagIMUBorder)
        default:
            return (LabRecorderDesignTokens.Colors.tagIdleFill, LabRecorderDesignTokens.Colors.secondaryText, nil)
        }
    }
}

// MARK: - Telemetry Tab

struct SegmentedLayoutTelemetryTab: View {
    let hud: SegmentedHUDModel
    let outputFilename: String

    var body: some View {
        // stitch-id: recording-live-telemetry
        VStack(alignment: .leading, spacing: LabRecorderDesignTokens.Spacing.md) {
            Text("TELEMETRY & STORAGE DETAILS")
                .font(LabRecorderDesignTokens.Typography.section)
                .tracking(1.2)
                .foregroundStyle(LabRecorderDesignTokens.Colors.secondaryText)
                .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: LabRecorderDesignTokens.Spacing.md) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("STATE & OUTPUT")
                            .font(LabRecorderDesignTokens.Typography.captionSemibold)
                            .tracking(0.8)
                            .foregroundStyle(LabRecorderDesignTokens.Colors.secondaryText)
                        HStack(spacing: LabRecorderDesignTokens.Spacing.sm) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(LabRecorderDesignTokens.Colors.emerald)
                                    .frame(width: 8, height: 8)
                                Text(hud.statusTitle)
                                    .font(LabRecorderDesignTokens.Typography.captionSemibold)
                                    .foregroundStyle(LabRecorderDesignTokens.Colors.emeraldMuted)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 2)
                            .background(LabRecorderDesignTokens.Colors.standbyFill)
                            .overlay(Capsule().stroke(LabRecorderDesignTokens.Colors.standbyBorder, lineWidth: 1))
                            .clipShape(Capsule())

                            Text(hud.loggedDuration)
                                .font(LabRecorderDesignTokens.Typography.caption.monospaced())
                                .foregroundStyle(LabRecorderDesignTokens.Colors.secondaryText)
                        }
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Text("RCS:")
                            .font(LabRecorderDesignTokens.Typography.microSemibold)
                            .foregroundStyle(LabRecorderDesignTokens.Colors.secondaryText)
                        Text(hud.rcsPort)
                            .font(LabRecorderDesignTokens.Typography.monoMicro)
                            .foregroundStyle(LabRecorderDesignTokens.Colors.emerald)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(LabRecorderDesignTokens.Colors.border.opacity(0.6))
                    .overlay(Capsule().stroke(LabRecorderDesignTokens.Colors.borderSubtle, lineWidth: 1))
                    .clipShape(Capsule())
                }

                HStack(spacing: LabRecorderDesignTokens.Spacing.sm) {
                    telemetryWell(title: "Duration", value: hud.duration, accent: LabRecorderDesignTokens.Colors.primaryText)
                    telemetryWell(title: "Data Size", value: hud.dataSize, accent: LabRecorderDesignTokens.Colors.nearWhite)
                    telemetryWell(title: "Streams", value: hud.streamsSummary, accent: LabRecorderDesignTokens.Colors.cyan)
                }
                .padding(.top, LabRecorderDesignTokens.Spacing.sm)
                .overlay(alignment: .top) {
                    Rectangle().fill(LabRecorderDesignTokens.Colors.border.opacity(0.8)).frame(height: 1)
                }

                HStack(spacing: LabRecorderDesignTokens.Spacing.sm) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(LabRecorderDesignTokens.Colors.idleText)
                    Text(outputFilename)
                        .font(LabRecorderDesignTokens.Typography.caption.monospaced())
                        .foregroundStyle(LabRecorderDesignTokens.Colors.tagNeutralText)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .padding(.horizontal, LabRecorderDesignTokens.Spacing.md)
                .padding(.vertical, LabRecorderDesignTokens.Spacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LabRecorderDesignTokens.Colors.filenameWell)
                .overlay(
                    RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.lg, style: .continuous)
                        .stroke(LabRecorderDesignTokens.Colors.border.opacity(0.8), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.lg, style: .continuous))
            }
            .padding(LabRecorderDesignTokens.Spacing.lg)
            .background(
                LinearGradient(
                    colors: [LabRecorderDesignTokens.Colors.card, LabRecorderDesignTokens.Colors.hudPanel],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.xl, style: .continuous)
                    .stroke(LabRecorderDesignTokens.Colors.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.xl, style: .continuous))
        }
    }

    private func telemetryWell(title: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(LabRecorderDesignTokens.Typography.micro)
                .foregroundStyle(LabRecorderDesignTokens.Colors.secondaryText)
            Text(value)
                .font(LabRecorderDesignTokens.Typography.monoBody)
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LabRecorderDesignTokens.Colors.well)
        .overlay(
            RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.lg, style: .continuous)
                .stroke(LabRecorderDesignTokens.Colors.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.lg, style: .continuous))
    }
}

#Preview("Streams Tab") {
    @Previewable @State var streams = SegmentedLayoutSampleData.preview.streams
    ScrollView {
        SegmentedLayoutStreamsTab(streams: $streams, onRefresh: {})
            .padding()
    }
    .background(LabRecorderDesignTokens.Colors.background)
}

#Preview("Study BIDS Tab") {
    @Previewable @State var model = SegmentedLayoutSampleData.preview.studyBids
    ScrollView {
        SegmentedLayoutStudyBidsTab(model: $model)
            .padding()
    }
    .background(LabRecorderDesignTokens.Colors.background)
}
