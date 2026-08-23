import SwiftUI
import Observation
import AppKit

/// The single source of truth. Owns the task queue, the cascading-timer logic,
/// pause state, persistence, and the completion chime.
///
/// Cascade rule: only the *first incomplete* item ("active") counts down. The first
/// task of a session must be started manually; once running, finishing or moving it
/// down auto-starts the next incomplete item so the queue flows without intervention.
@Observable
@MainActor
final class TodoStore {
    var items: [TodoItem] = []
    /// Global pause. While on break, no timer advances.
    var isOnBreak: Bool = false

    @ObservationIgnored private var ticker: Task<Void, Never>?
    @ObservationIgnored private let saveURL: URL
    @ObservationIgnored private let chime = NSSound(named: NSSound.Name("Glass"))
    /// The main window, registered by `WindowAccessor`, so the menu bar can
    /// focus it instead of opening a duplicate.
    @ObservationIgnored weak var mainWindow: NSWindow?

    init() {
        saveURL = Self.makeSaveURL()
        load()
        startTimer()
    }

    // MARK: - Derived state

    /// Index of the active (first incomplete, non-suggestion) item, if any.
    var activeIndex: Int? {
        items.firstIndex { !$0.isComplete && !$0.isSuggestion }
    }

    /// Unreviewed suggestions from Observatory, newest first.
    var suggestions: [TodoItem] {
        items.filter { $0.isSuggestion }
            .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
    }

    /// Array layout invariant: `[active queue..., completed..., suggestions...]`.
    /// This is the insertion point at the end of the active queue.
    var queueEnd: Int {
        items.firstIndex { $0.isComplete || $0.isSuggestion } ?? items.count
    }

    /// Insertion point at the end of the Done pile (before any suggestions).
    private var doneEnd: Int {
        items.firstIndex { $0.isSuggestion } ?? items.count
    }

    var activeItem: TodoItem? {
        guard let i = activeIndex else { return nil }
        return items[i]
    }

    /// The compact label shown in the macOS menu bar.
    var menuBarTitle: String {
        guard let item = activeItem else { return "Cadence" }
        return timerString(item.remainingSeconds)
    }

    // MARK: - Timer

    private func startTimer() {
        ticker?.cancel()
        // Created in a @MainActor context, so the task inherits main-actor
        // isolation and `tick()` is safe to call directly.
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                self?.tick()
            }
        }
    }

    private func tick() {
        guard !isOnBreak, let i = activeIndex else { return }
        guard items[i].hasStarted, !items[i].didFire, items[i].remainingSeconds > 0 else { return }

        items[i].remainingSeconds -= 1
        if items[i].remainingSeconds == 0 {
            items[i].didFire = true
            chime?.play()
        }
        save()
    }

    // MARK: - Intents

    func addTask(_ rawTitle: String, minutes: Int = 20) {
        let title = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let item = TodoItem(title: title, durationSeconds: max(60, minutes * 60))
        // Insert above completed tasks so it joins the active queue.
        items.insert(item, at: queueEnd)
        save()
    }

    // MARK: - Suggestions (Observatory inbox)

    /// Park a suggested task in the inbox. Never enters the cascade until accepted.
    /// Deduped on `sourceID`.
    func addSuggestion(title rawTitle: String, minutes: Int, notes: String?, sourceID: String?, sourceURL: String?) {
        let title = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        if let sourceID, items.contains(where: { $0.sourceID == sourceID }) { return }
        var item = TodoItem(title: title, durationSeconds: max(60, minutes * 60))
        item.isSuggestion = true
        item.hasStarted = false
        item.notes = notes?.isEmpty == false ? notes : nil
        item.sourceID = sourceID
        item.sourceURL = sourceURL
        items.append(item)
        save()
    }

    /// Move a suggestion into the bottom of the active queue and tell Observatory.
    func acceptSuggestion(_ id: UUID) {
        guard let i = items.firstIndex(where: { $0.id == id }), items[i].isSuggestion else { return }
        var item = items.remove(at: i)
        item.isSuggestion = false
        item.hasStarted = false
        item.isComplete = false
        item.completedAt = nil
        item.remainingSeconds = item.durationSeconds
        items.insert(item, at: queueEnd)
        save()
        if let sid = item.sourceID { ObservatoryBridge.report(actionID: sid, status: .accepted) }
    }

    /// Drop a suggestion and tell Observatory.
    func dismissSuggestion(_ id: UUID) {
        guard let i = items.firstIndex(where: { $0.id == id }), items[i].isSuggestion else { return }
        let item = items.remove(at: i)
        save()
        if let sid = item.sourceID { ObservatoryBridge.report(actionID: sid, status: .dismissed) }
    }

    func toggleComplete(_ id: UUID) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        // Capture before mutating: were we finishing the running top task?
        let wasActiveRunning = (i == activeIndex) && items[i].hasStarted && !items[i].isComplete

        var item = items.remove(at: i)
        item.didFire = false
        item.hasStarted = false
        item.remainingSeconds = item.durationSeconds
        if item.isComplete {
            // Un-complete -> rejoin the bottom of the active queue (keeps the
            // completed items contiguous at the end of the array).
            item.isComplete = false
            item.completedAt = nil
            items.insert(item, at: queueEnd)
        } else {
            // Complete -> stamp the time and sink into the Done pile.
            item.isComplete = true
            item.completedAt = Date()
            items.insert(item, at: doneEnd)
            // Cascade: finishing the running task auto-starts the next one.
            autoStartNext(after: wasActiveRunning)
            if let sid = item.sourceID { ObservatoryBridge.report(actionID: sid, status: .done) }
        }
        save()
    }

    /// Remove every completed task from the Done list.
    func clearCompleted() {
        items.removeAll { $0.isComplete }
        save()
    }

    /// `+5 min` on a fired item: extend and resume.
    func addFiveMinutes(_ id: UUID) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        items[i].remainingSeconds += 5 * 60
        items[i].didFire = false
        save()
    }

    /// Send an item to the bottom of the *active* queue (above completed),
    /// resetting its timer. The next item becomes active.
    func moveToBottom(_ id: UUID) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        let wasActiveRunning = (i == activeIndex) && items[i].hasStarted
        let movedId = id

        var item = items.remove(at: i)
        item.remainingSeconds = item.durationSeconds
        item.didFire = false
        item.hasStarted = false
        item.isComplete = false
        item.completedAt = nil
        items.insert(item, at: queueEnd)

        // Cascade — but only if there's a *different* task to advance to (don't
        // silently restart the same task when it's the only one in the queue).
        if activeItem?.id != movedId {
            autoStartNext(after: wasActiveRunning)
        }
        save()
    }

    /// If we just advanced away from a running task, start the new active one so
    /// the queue keeps flowing. Respects an in-progress break (won't tick until
    /// resumed). The first task of a session still requires a manual Start.
    private func autoStartNext(after wasActiveRunning: Bool) {
        guard wasActiveRunning, let n = activeIndex else { return }
        items[n].hasStarted = true
        items[n].didFire = false
    }

    /// Promote an item to the top so it becomes active next.
    func moveToTop(_ id: UUID) {
        guard let i = items.firstIndex(where: { $0.id == id }), i != 0 else { return }
        var item = items.remove(at: i)
        item.isComplete = false
        item.completedAt = nil
        item.hasStarted = false
        items.insert(item, at: 0)
        save()
    }

    func delete(_ id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }

    func setDuration(_ id: UUID, minutes: Int) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        let seconds = max(60, minutes * 60)
        let wasFull = items[i].remainingSeconds == items[i].durationSeconds
        items[i].durationSeconds = seconds
        // If the timer hasn't really started, keep remaining in sync; otherwise clamp.
        if wasFull || items[i].remainingSeconds > seconds {
            items[i].remainingSeconds = seconds
        }
        items[i].didFire = false
        save()
    }

    /// Explicitly start the active task's countdown (it never auto-runs).
    func start() {
        guard let i = activeIndex else { return }
        items[i].hasStarted = true
        items[i].didFire = false
        isOnBreak = false
        save()
    }

    func toggleBreak() {
        isOnBreak.toggle()
    }

    /// Drag-reorder within the "up next" sub-list (offsets are slice-relative).
    func moveTail(_ offsets: IndexSet, to destination: Int, base: Int) {
        let shifted = IndexSet(offsets.map { $0 + base })
        items.move(fromOffsets: shifted, toOffset: destination + base)
        save()
    }

    // MARK: - Persistence

    private static func makeSaveURL() -> URL {
        let fm = FileManager.default
        let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Cadence", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("todos.json")
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let decoded = try? JSONDecoder().decode([TodoItem].self, from: data)
        else { return }
        items = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: saveURL, options: .atomic)
    }
}
