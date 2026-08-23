import AppKit

/// One-way write-back to the Observatory app over its URL scheme.
/// `observatory://action/<id>/<status>` — fails silently if Observatory isn't installed.
enum ObservatoryBridge {
    enum Status: String { case accepted, dismissed, done }

    static func report(actionID: String, status: Status) {
        guard let id = actionID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "observatory://action/\(id)/\(status.rawValue)")
        else { return }
        NSWorkspace.shared.open(url)
    }
}
