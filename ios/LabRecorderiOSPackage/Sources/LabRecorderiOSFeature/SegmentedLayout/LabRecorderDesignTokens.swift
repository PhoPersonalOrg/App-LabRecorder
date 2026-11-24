import SwiftUI

enum LabRecorderDesignTokens {
    enum Colors {
        static let background = Color(hex: 0x0C0D0E)
        static let card = Color(hex: 0x1C1C1E)
        static let hudPanel = Color(hex: 0x161618)
        static let well = Color(hex: 0x121214)
        static let border = Color(hex: 0x2C2C2E)
        static let borderSubtle = Color.white.opacity(0.05)
        static let primaryText = Color.white
        static let secondaryText = Color(hex: 0xA3A3A3)
        static let mutedText = Color(hex: 0x8E8E93)
        static let idleText = Color(hex: 0x737373)
        static let accent = Color(hex: 0x007AFF)
        static let green = Color(hex: 0x34C759)
        static let emerald = Color(hex: 0x34D399)
        static let emeraldMuted = Color(hex: 0x6EE7B7)
        static let standbyFill = Color(hex: 0x022C22).opacity(0.85)
        static let standbyBorder = Color(hex: 0x10B981).opacity(0.30)
        static let cyan = Color(hex: 0x22D3EE)
        static let red = Color(hex: 0xFF3B30)
        static let orange = Color(hex: 0xFF9500)
        static let recordFrom = Color(hex: 0x10B981)
        static let recordTo = Color(hex: 0x16A34A)
        static let stopFrom = Color(hex: 0xDC2626)
        static let stopTo = Color(hex: 0xBE123C)
        static let toolButton = Color(hex: 0x262626).opacity(0.80)
        static let logoFrom = Color(hex: 0x0891B2)
        static let logoMid = Color(hex: 0x2563EB)
        static let logoTo = Color(hex: 0x4F46E5)
        static let versionBadgeFill = Color(hex: 0x10B981).opacity(0.15)
        static let versionBadgeText = Color(hex: 0x34D399)
        static let versionBadgeBorder = Color(hex: 0x10B981).opacity(0.20)
        static let tagEEGFill = Color(hex: 0x3B82F6).opacity(0.10)
        static let tagEEGText = Color(hex: 0x60A5FA)
        static let tagEEGBorder = Color(hex: 0x3B82F6).opacity(0.20)
        static let tagIMUFill = Color(hex: 0xA855F7).opacity(0.10)
        static let tagIMUText = Color(hex: 0xC084FC)
        static let tagIMUBorder = Color(hex: 0xA855F7).opacity(0.20)
        static let tagCQFill = Color(hex: 0xF59E0B).opacity(0.10)
        static let tagCQText = Color(hex: 0xFBBF24)
        static let tagCQBorder = Color(hex: 0xF59E0B).opacity(0.20)
        static let tagMarkerFill = Color(hex: 0x14B8A6).opacity(0.10)
        static let tagMarkerText = Color(hex: 0x5EEAD4)
        static let tagMarkerBorder = Color(hex: 0x14B8A6).opacity(0.20)
        static let tagASRFill = Color(hex: 0x6366F1).opacity(0.10)
        static let tagASRText = Color(hex: 0xA5B4FC)
        static let tagASRBorder = Color(hex: 0x6366F1).opacity(0.20)
        static let tagVideoFill = Color(hex: 0xF43F5E).opacity(0.10)
        static let tagVideoText = Color(hex: 0xFDA4AF)
        static let tagVideoBorder = Color(hex: 0xF43F5E).opacity(0.20)
        static let tagNeutralFill = Color(hex: 0x404040)
        static let tagNeutralText = Color(hex: 0xD4D4D4)
        static let tagIdleFill = Color(hex: 0x262626)
        static let tagIdleText = Color(hex: 0xA3A3A3)
        static let nearWhite = Color(hex: 0xE5E5E5)
        static let filenameWell = Color(hex: 0x111113)
    }

    enum Typography {
        static let title = Font.system(size: 16, weight: .bold)
        static let hubSubtitle = Font.system(size: 11, weight: .regular).monospaced()
        static let section = Font.system(size: 12, weight: .semibold)
        static let body = Font.system(size: 14, weight: .semibold)
        static let bodyMedium = Font.system(size: 14, weight: .medium)
        static let caption = Font.system(size: 11, weight: .regular)
        static let captionSemibold = Font.system(size: 11, weight: .semibold)
        static let micro = Font.system(size: 10, weight: .medium)
        static let microSemibold = Font.system(size: 10, weight: .semibold)
        static let monoMicro = Font.system(size: 10, weight: .medium).monospaced()
        static let monoCaption = Font.system(size: 12, weight: .bold).monospaced()
        static let monoBody = Font.system(size: 14, weight: .medium).monospaced()
        static let recordLabel = Font.system(size: 14, weight: .black)
        static let versionBadge = Font.system(size: 10, weight: .semibold)
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let bottomDockClearance: CGFloat = 180
    }

    enum Radii {
        static let xs: CGFloat = 2
        static let sm: CGFloat = 4
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let pill: CGFloat = 999
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
