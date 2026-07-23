import SwiftUI

/// Cadence v2 type ramp — the native macOS system font (SF Pro), with SF Pro
/// Rounded reserved for the big countdown to give it a soft, friendly read in
/// the Display-Buddy idiom.
enum Typography {
    /// Big hero countdown — rounded, tabular digits applied at the call site.
    static var timer: Font { .system(size: 46, weight: .semibold, design: .rounded) }
    /// Menu-bar countdown.
    static var heading: Font { .system(size: 28, weight: .semibold, design: .rounded) }
    /// Card / task titles.
    static var title: Font { .system(size: 15, weight: .semibold) }
    /// Emphasis / button labels.
    static var strong: Font { .system(size: 13, weight: .medium) }
    /// Default body / row text.
    static var body: Font { .system(size: 13, weight: .regular) }
    /// Keycaps, section headers, smallest utility text.
    static var keycap: Font { .system(size: 11, weight: .medium) }
    /// Captions / hints.
    static var caption: Font { .system(size: 12, weight: .regular) }
}
