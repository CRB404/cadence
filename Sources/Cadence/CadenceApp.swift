import SwiftUI

@main
@MainActor
struct CadenceApp: App {
    @State private var store = TodoStore()

    var body: some Scene {
        WindowGroup(id: "main") {
            TodoListView()
                .environment(store)
                .onOpenURL(perform: handle)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 300, height: 540)

        MenuBarExtra {
            MenuBarView()
                .environment(store)
        } label: {
            MenuBarLabel(store: store)
        }
        .menuBarExtraStyle(.window)
    }

    /// `cadence://add?title=…&minutes=20&notes=…&sourceId=…&sourceUrl=…`
    private func handle(_ url: URL) {
        guard url.scheme == "cadence", url.host == "add",
              let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { return }
        let q = Dictionary(uniqueKeysWithValues: (comps.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        guard let title = q["title"], !title.isEmpty else { return }
        store.addSuggestion(
            title: title,
            minutes: Int(q["minutes"] ?? "") ?? 20,
            notes: q["notes"],
            sourceID: q["sourceId"],
            sourceURL: q["sourceUrl"]
        )
    }
}
