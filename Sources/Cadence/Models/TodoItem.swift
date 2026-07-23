import Foundation

/// A single task with its own countdown. Default duration is 20 minutes.
struct TodoItem: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var durationSeconds: Int
    var remainingSeconds: Int
    var isComplete: Bool
    /// True once the timer has hit 0:00 and is awaiting a +5 / move decision.
    var didFire: Bool
    /// False until the user explicitly presses Start — the timer never auto-runs.
    var hasStarted: Bool
    /// When the task was marked complete — drives the Done list's recency order.
    var completedAt: Date?

    init(title: String, durationSeconds: Int = 20 * 60) {
        self.id = UUID()
        self.title = title
        self.durationSeconds = durationSeconds
        self.remainingSeconds = durationSeconds
        self.isComplete = false
        self.didFire = false
        self.hasStarted = false
        self.completedAt = nil
    }

    // Backward-compatible decoding: tolerate JSON saved before newer fields existed.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        durationSeconds = try c.decode(Int.self, forKey: .durationSeconds)
        remainingSeconds = try c.decode(Int.self, forKey: .remainingSeconds)
        isComplete = try c.decodeIfPresent(Bool.self, forKey: .isComplete) ?? false
        didFire = try c.decodeIfPresent(Bool.self, forKey: .didFire) ?? false
        hasStarted = try c.decodeIfPresent(Bool.self, forKey: .hasStarted) ?? false
        completedAt = try c.decodeIfPresent(Date.self, forKey: .completedAt)
    }

    /// Progress from 1 (full) to 0 (elapsed).
    var fractionRemaining: Double {
        guard durationSeconds > 0 else { return 0 }
        return max(0, min(1, Double(remainingSeconds) / Double(durationSeconds)))
    }
}
