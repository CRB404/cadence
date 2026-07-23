import SwiftUI
import AppKit

/// Cadence v2 — a light/dark, Display-Buddy-inspired palette. Every token is
/// adaptive: it resolves to a light value over the frosted-glass window in light
/// mode and a dark value in dark mode. Depth comes from translucent cards over
/// the window vibrancy; color stays largely monochrome.
enum Palette {
    // MARK: Text ladder
    static let ink = dyn(0x1C1C1E, 1, 0xF4F4F6, 1)        // primary
    static let body = dyn(0x46464A, 1, 0xCDCDCD, 1)       // secondary
    static let mute = dyn(0x6E6E73, 1, 0x9C9C9D, 1)       // tertiary
    static let ash = dyn(0x9A9AA0, 1, 0x6A6B6C, 1)        // quaternary / icons

    // MARK: Separators
    static let hairline = dyn(0x000000, 0.08, 0xFFFFFF, 0.10)
    static let hairlineStrong = dyn(0x000000, 0.14, 0xFFFFFF, 0.18)

    // MARK: Surfaces (translucent over the window vibrancy)
    /// Window tint laid over the visual-effect material.
    static let glassTint = dyn(0xFFFFFF, 0.10, 0x07080A, 0.20)
    /// Card fill — the grouped rounded panels.
    static let cardFill = dyn(0xFFFFFF, 0.55, 0xFFFFFF, 0.06)
    /// Softer fill for the add field.
    static let cardFillSoft = dyn(0xFFFFFF, 0.42, 0xFFFFFF, 0.04)
    /// Control fill — pills, segmented buttons, keycaps.
    static let controlFill = dyn(0xFFFFFF, 0.72, 0xFFFFFF, 0.07)
    static let controlPressed = dyn(0xFFFFFF, 0.92, 0xFFFFFF, 0.13)

    // Back-compat aliases used by older call sites.
    static let surfaceElevated = controlFill
    static let surfaceCard = controlPressed
    static let glassFill = cardFill
    static let glassFillSoft = cardFillSoft

    // MARK: Primary action (high-contrast monochrome pill)
    static let primary = dyn(0x1C1C1E, 1, 0xFFFFFF, 1)
    static let primaryPressed = dyn(0x000000, 1, 0xE8E8E8, 1)
    static let onPrimary = dyn(0xFFFFFF, 1, 0x000000, 1)

    // MARK: Accents
    static let accent = dyn(0x007AFF, 1, 0x0A84FF, 1)
    static let accentSoft = dyn(0x007AFF, 0.14, 0x0A84FF, 0.22)
    static let accentRed = dyn(0xFF3B30, 1, 0xFF6161, 1)
    static let accentRedSoft = dyn(0xFF3B30, 0.12, 0xFF6161, 0.16)
    static let accentGreen = dyn(0x34C759, 1, 0x59D499, 1)

    // MARK: Slider (Display-Buddy capsule)
    static let sliderTrack = dyn(0x787880, 0.20, 0xFFFFFF, 0.10)
    static let sliderFill = dyn(0xFFFFFF, 0.95, 0xFFFFFF, 0.55)
    static let knob = dyn(0xFFFFFF, 1, 0xFFFFFF, 1)

    // MARK: Helpers
    private static func dyn(_ lHex: UInt, _ lA: CGFloat, _ dHex: UInt, _ dA: CGFloat) -> Color {
        let light = ns(lHex, lA)
        let dark = ns(dHex, dA)
        return Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        })
    }

    private static func ns(_ hex: UInt, _ a: CGFloat) -> NSColor {
        NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: a)
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
