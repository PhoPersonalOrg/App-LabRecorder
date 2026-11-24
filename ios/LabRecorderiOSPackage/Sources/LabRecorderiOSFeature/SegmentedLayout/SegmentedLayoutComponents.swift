import SwiftUI

// MARK: - Header

struct SegmentedLayoutHeaderView: View {
    let title: String
    let versionBadge: String
    let hubSubtitle: String
    var onSettings: (() -> Void)?
    var onHelp: (() -> Void)?

    var body: some View {
        // stitch-id: app-header-navigation
        HStack(alignment: .center, spacing: LabRecorderDesignTokens.Spacing.md) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.md, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    LabRecorderDesignTokens.Colors.logoFrom,
                                    LabRecorderDesignTokens.Colors.logoMid,
                                    LabRecorderDesignTokens.Colors.logoTo,
                                ],
                                startPoint: .bottomLeading,
                                endPoint: .topTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .shadow(color: LabRecorderDesignTokens.Colors.logoMid.opacity(0.35), radius: 8, y: 2)

                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(LabRecorderDesignTokens.Typography.title)
                            .foregroundStyle(LabRecorderDesignTokens.Colors.primaryText)

                        Text(versionBadge)
                            .font(LabRecorderDesignTokens.Typography.versionBadge)
                            .foregroundStyle(LabRecorderDesignTokens.Colors.versionBadgeText)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(LabRecorderDesignTokens.Colors.versionBadgeFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.sm)
                                    .stroke(LabRecorderDesignTokens.Colors.versionBadgeBorder, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.sm))
                    }

                    Text(hubSubtitle)
                        .font(LabRecorderDesignTokens.Typography.hubSubtitle)
                        .foregroundStyle(LabRecorderDesignTokens.Colors.secondaryText)
                }
            }

            Spacer(minLength: 0)

            HStack(spacing: 4) {
                toolButton(systemName: "gearshape", accessibilityLabel: "Settings", action: onSettings)
                toolButton(systemName: "questionmark.circle", accessibilityLabel: "Help", action: onHelp)
            }
        }
        .padding(.horizontal, LabRecorderDesignTokens.Spacing.lg)
        .padding(.vertical, LabRecorderDesignTokens.Spacing.sm)
    }

    private func toolButton(systemName: String, accessibilityLabel: String, action: (() -> Void)?) -> some View {
        Button {
            action?()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(LabRecorderDesignTokens.Colors.secondaryText)
                .frame(width: 32, height: 32)
                .background(LabRecorderDesignTokens.Colors.toolButton)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - HUD

struct SegmentedLayoutHUDView: View {
    let model: SegmentedHUDModel

    var body: some View {
        // stitch-id: persistent-hud-telemetry
        VStack(spacing: LabRecorderDesignTokens.Spacing.sm) {
            HStack {
                HStack(spacing: LabRecorderDesignTokens.Spacing.sm) {
                    statusPill
                    Text(model.loggedDuration)
                        .font(LabRecorderDesignTokens.Typography.monoMicro)
                        .foregroundStyle(LabRecorderDesignTokens.Colors.secondaryText)
                }

                Spacer(minLength: 0)

                HStack(spacing: 6) {
                    Text("RCS:")
                        .font(LabRecorderDesignTokens.Typography.microSemibold)
                        .foregroundStyle(LabRecorderDesignTokens.Colors.secondaryText)
                    Text(model.rcsPort)
                        .font(LabRecorderDesignTokens.Typography.monoMicro)
                        .foregroundStyle(LabRecorderDesignTokens.Colors.emerald)
                }
                .padding(.horizontal, LabRecorderDesignTokens.Spacing.sm)
                .padding(.vertical, 2)
                .background(LabRecorderDesignTokens.Colors.border.opacity(0.6))
                .overlay(
                    Capsule().stroke(LabRecorderDesignTokens.Colors.borderSubtle, lineWidth: 1)
                )
                .clipShape(Capsule())
            }
            .padding(.bottom, LabRecorderDesignTokens.Spacing.sm)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(LabRecorderDesignTokens.Colors.border)
                    .frame(height: 1)
            }

            HStack(spacing: 0) {
                metric(title: "Duration", value: model.duration, accent: LabRecorderDesignTokens.Colors.primaryText)
                metric(title: "Data Size", value: model.dataSize, accent: LabRecorderDesignTokens.Colors.primaryText)
                    .overlay(alignment: .leading) {
                        Rectangle().fill(LabRecorderDesignTokens.Colors.border).frame(width: 1)
                    }
                    .overlay(alignment: .trailing) {
                        Rectangle().fill(LabRecorderDesignTokens.Colors.border).frame(width: 1)
                    }
                metric(title: "Streams", value: model.streamsSummary, accent: LabRecorderDesignTokens.Colors.cyan)
            }
            .padding(.top, LabRecorderDesignTokens.Spacing.sm)
        }
        .padding(10)
        .background(LabRecorderDesignTokens.Colors.hudPanel)
        .overlay(
            RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.lg, style: .continuous)
                .stroke(LabRecorderDesignTokens.Colors.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.lg, style: .continuous))
        .padding(.horizontal, LabRecorderDesignTokens.Spacing.lg)
        .padding(.bottom, 10)
    }

    private var statusPill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(LabRecorderDesignTokens.Colors.emerald)
                .frame(width: 6, height: 6)
                .overlay {
                    Circle()
                        .fill(LabRecorderDesignTokens.Colors.emerald.opacity(0.5))
                        .scaleEffect(1.8)
                        .opacity(model.isStandby ? 1 : 0)
                }
            Text(model.statusTitle)
                .font(LabRecorderDesignTokens.Typography.captionSemibold)
                .foregroundStyle(LabRecorderDesignTokens.Colors.emeraldMuted)
        }
        .padding(.horizontal, LabRecorderDesignTokens.Spacing.sm)
        .padding(.vertical, 2)
        .background(LabRecorderDesignTokens.Colors.standbyFill)
        .overlay(
            Capsule().stroke(LabRecorderDesignTokens.Colors.standbyBorder, lineWidth: 1)
        )
        .clipShape(Capsule())
    }

    private func metric(title: String, value: String, accent: Color) -> some View {
        VStack(spacing: 2) {
            Text(title.uppercased())
                .font(LabRecorderDesignTokens.Typography.micro)
                .foregroundStyle(LabRecorderDesignTokens.Colors.secondaryText)
                .tracking(0.2)
            Text(value)
                .font(LabRecorderDesignTokens.Typography.monoCaption)
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Segmented Tab Bar

struct SegmentedLayoutTabBar: View {
    @Binding var selection: SegmentedLayoutTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(SegmentedLayoutTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selection = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(LabRecorderDesignTokens.Typography.captionSemibold)
                        .foregroundStyle(
                            selection == tab
                                ? LabRecorderDesignTokens.Colors.primaryText
                                : LabRecorderDesignTokens.Colors.secondaryText
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background {
                            if selection == tab {
                                RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.md, style: .continuous)
                                    .fill(LabRecorderDesignTokens.Colors.border)
                                    .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(LabRecorderDesignTokens.Colors.card)
        .overlay(
            RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.lg, style: .continuous)
                .stroke(LabRecorderDesignTokens.Colors.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.lg, style: .continuous))
        .padding(.horizontal, LabRecorderDesignTokens.Spacing.lg)
        .padding(.bottom, LabRecorderDesignTokens.Spacing.sm)
    }
}

// MARK: - Stream Tag / Signal

struct StreamTagChip: View {
    let text: String
    let style: StreamTagStyle

    var body: some View {
        Text(text)
            .font(LabRecorderDesignTokens.Typography.micro)
            .foregroundStyle(palette.text)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(palette.fill)
            .overlay {
                if let border = palette.border {
                    RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.sm)
                        .stroke(border, lineWidth: 1)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.sm))
    }

    private var palette: (fill: Color, text: Color, border: Color?) {
        switch style {
        case .eeg:
            return (LabRecorderDesignTokens.Colors.tagEEGFill, LabRecorderDesignTokens.Colors.tagEEGText, LabRecorderDesignTokens.Colors.tagEEGBorder)
        case .imu:
            return (LabRecorderDesignTokens.Colors.tagIMUFill, LabRecorderDesignTokens.Colors.tagIMUText, LabRecorderDesignTokens.Colors.tagIMUBorder)
        case .contactQuality:
            return (LabRecorderDesignTokens.Colors.tagCQFill, LabRecorderDesignTokens.Colors.tagCQText, LabRecorderDesignTokens.Colors.tagCQBorder)
        case .markers:
            return (LabRecorderDesignTokens.Colors.tagMarkerFill, LabRecorderDesignTokens.Colors.tagMarkerText, LabRecorderDesignTokens.Colors.tagMarkerBorder)
        case .asr:
            return (LabRecorderDesignTokens.Colors.tagASRFill, LabRecorderDesignTokens.Colors.tagASRText, LabRecorderDesignTokens.Colors.tagASRBorder)
        case .video:
            return (LabRecorderDesignTokens.Colors.tagVideoFill, LabRecorderDesignTokens.Colors.tagVideoText, LabRecorderDesignTokens.Colors.tagVideoBorder)
        case .notes:
            return (LabRecorderDesignTokens.Colors.tagNeutralFill, LabRecorderDesignTokens.Colors.tagNeutralText, nil)
        case .idle:
            return (LabRecorderDesignTokens.Colors.tagIdleFill, LabRecorderDesignTokens.Colors.tagIdleText, nil)
        }
    }
}

struct StreamSignalAccessory: View {
    let signal: StreamSignalStyle

    var body: some View {
        switch signal {
        case .bars(let heights):
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(Array(heights.enumerated()), id: \.offset) { _, height in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(LabRecorderDesignTokens.Colors.green)
                        .frame(width: 4, height: max(6, 14 * height))
                }
            }
            .frame(height: 14, alignment: .bottom)
            .accessibilityLabel("Signal bars")
        case .badge(let text):
            Text(text)
                .font(LabRecorderDesignTokens.Typography.monoMicro)
                .foregroundStyle(LabRecorderDesignTokens.Colors.tagNeutralText)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(LabRecorderDesignTokens.Colors.tagIdleFill)
                .clipShape(RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.sm))
        case .dot:
            Circle()
                .fill(LabRecorderDesignTokens.Colors.emerald)
                .frame(width: 8, height: 8)
                .accessibilityLabel("Online")
        case .idleLabel(let text):
            Text(text)
                .font(LabRecorderDesignTokens.Typography.micro)
                .foregroundStyle(LabRecorderDesignTokens.Colors.idleText)
        }
    }
}

// MARK: - Stream Row

struct SegmentedLayoutStreamRow: View {
    @Binding var model: SegmentedStreamRowModel

    var body: some View {
        Button {
            model.isSelected.toggle()
        } label: {
            HStack(spacing: LabRecorderDesignTokens.Spacing.md) {
                Image(systemName: model.isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(
                        model.isSelected
                            ? LabRecorderDesignTokens.Colors.accent
                            : LabRecorderDesignTokens.Colors.secondaryText
                    )
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: LabRecorderDesignTokens.Spacing.sm) {
                        Text(model.name)
                            .font(model.isSelected ? LabRecorderDesignTokens.Typography.body : LabRecorderDesignTokens.Typography.bodyMedium)
                            .foregroundStyle(
                                model.isSelected
                                    ? LabRecorderDesignTokens.Colors.emerald
                                    : LabRecorderDesignTokens.Colors.secondaryText
                            )
                        Text("(\(model.host))")
                            .font(LabRecorderDesignTokens.Typography.caption)
                            .foregroundStyle(
                                model.isSelected
                                    ? LabRecorderDesignTokens.Colors.secondaryText
                                    : LabRecorderDesignTokens.Colors.idleText
                            )
                    }

                    HStack(spacing: LabRecorderDesignTokens.Spacing.sm) {
                        StreamTagChip(text: model.tag, style: model.tagStyle)
                        if let rateLabel = model.rateLabel {
                            Text(rateLabel)
                                .font(LabRecorderDesignTokens.Typography.monoMicro)
                                .foregroundStyle(
                                    model.isSelected
                                        ? LabRecorderDesignTokens.Colors.secondaryText
                                        : LabRecorderDesignTokens.Colors.idleText
                                )
                        }
                    }
                    .padding(.top, 2)
                }

                Spacer(minLength: 0)

                StreamSignalAccessory(signal: model.signal)
            }
            .padding(LabRecorderDesignTokens.Spacing.md)
            .contentShape(Rectangle())
            .opacity(model.isSelected ? 1 : 0.85)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(model.name), \(model.isSelected ? "selected" : "not selected")")
    }
}

// MARK: - Bottom Bar

struct SegmentedLayoutBottomBar: View {
    let isRecording: Bool
    let isLocked: Bool
    var onLock: () -> Void
    var onPrimary: () -> Void
    var onStop: () -> Void

    var body: some View {
        // stitch-id: floating-action-trigger
        VStack(spacing: LabRecorderDesignTokens.Spacing.md) {
            HStack(spacing: LabRecorderDesignTokens.Spacing.md) {
                Button(action: onLock) {
                    Image(systemName: isLocked ? "lock.fill" : "lock")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(LabRecorderDesignTokens.Colors.secondaryText)
                        .frame(width: 48, height: 48)
                        .background(LabRecorderDesignTokens.Colors.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.xl, style: .continuous)
                                .stroke(LabRecorderDesignTokens.Colors.border.opacity(0.8), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.xl, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isLocked ? "Unlock controls" : "Lock controls")

                Button(action: onPrimary) {
                    HStack(spacing: LabRecorderDesignTokens.Spacing.sm) {
                        Circle()
                            .fill(isRecording ? Color.white : Color.black)
                            .frame(width: 12, height: 12)
                        Text(isRecording ? "STOP RECORDING" : "START RECORDING")
                            .font(LabRecorderDesignTokens.Typography.recordLabel)
                            .tracking(0.6)
                            .foregroundStyle(isRecording ? Color.white : Color.black)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        LinearGradient(
                            colors: isRecording
                                ? [LabRecorderDesignTokens.Colors.stopFrom, LabRecorderDesignTokens.Colors.stopTo]
                                : [LabRecorderDesignTokens.Colors.recordFrom, LabRecorderDesignTokens.Colors.recordTo],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.xl, style: .continuous))
                    .shadow(
                        color: (isRecording ? LabRecorderDesignTokens.Colors.stopFrom : LabRecorderDesignTokens.Colors.recordFrom)
                            .opacity(0.35),
                        radius: 12,
                        y: 4
                    )
                }
                .buttonStyle(.plain)
                .disabled(isLocked)
                .accessibilityIdentifier("startRecording")
                .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")

                Button(action: onStop) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(isRecording ? LabRecorderDesignTokens.Colors.red.opacity(0.85) : LabRecorderDesignTokens.Colors.idleText)
                        .frame(width: 16, height: 16)
                        .frame(width: 48, height: 48)
                        .background(LabRecorderDesignTokens.Colors.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.xl, style: .continuous)
                                .stroke(LabRecorderDesignTokens.Colors.border.opacity(0.8), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: LabRecorderDesignTokens.Radii.xl, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!isRecording || isLocked)
                .accessibilityIdentifier("stopRecording")
                .accessibilityLabel("Stop acquisition")
            }
        }
        .padding(LabRecorderDesignTokens.Spacing.lg)
        .background(.ultraThinMaterial.opacity(0.001))
        .background(LabRecorderDesignTokens.Colors.background.opacity(0.92))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(LabRecorderDesignTokens.Colors.card)
                .frame(height: 1)
        }
    }
}

#Preview("Header") {
    SegmentedLayoutHeaderView(
        title: SegmentedLayoutSampleData.preview.appTitle,
        versionBadge: SegmentedLayoutSampleData.preview.versionBadge,
        hubSubtitle: SegmentedLayoutSampleData.preview.hubSubtitle
    )
    .background(LabRecorderDesignTokens.Colors.background)
}

#Preview("HUD") {
    SegmentedLayoutHUDView(model: SegmentedLayoutSampleData.preview.hud)
        .background(LabRecorderDesignTokens.Colors.background)
}

#Preview("Bottom Bar") {
    SegmentedLayoutBottomBar(
        isRecording: false,
        isLocked: false,
        onLock: {},
        onPrimary: {},
        onStop: {}
    )
    .background(LabRecorderDesignTokens.Colors.background)
}
