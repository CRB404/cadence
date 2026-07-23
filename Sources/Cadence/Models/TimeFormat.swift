import Foundation

/// Formats a second count as `M:SS` (or `MM:SS`, `H:MM:SS` for longer spans).
func timerString(_ totalSeconds: Int) -> String {
    let s = max(0, totalSeconds)
    let hours = s / 3600
    let minutes = (s % 3600) / 60
    let seconds = s % 60
    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
    return String(format: "%d:%02d", minutes, seconds)
}

/// Compact duration label for the keycap chip, e.g. `20m`, `1h`, `1h30`.
func durationLabel(_ totalSeconds: Int) -> String {
    let minutes = totalSeconds / 60
    if minutes < 60 { return "\(minutes)m" }
    let h = minutes / 60
    let m = minutes % 60
    return m == 0 ? "\(h)h" : "\(h)h\(m)"
}

/// Short "how long ago" label for completed tasks, e.g. `now`, `5m`, `2h`, `3d`.
func relativeTime(_ date: Date?) -> String {
    guard let date else { return "" }
    let seconds = Int(Date().timeIntervalSince(date))
    if seconds < 60 { return "now" }
    if seconds < 3600 { return "\(seconds / 60)m" }
    if seconds < 86_400 { return "\(seconds / 3600)h" }
    return "\(seconds / 86_400)d"
}
