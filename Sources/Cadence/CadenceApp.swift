import SwiftUI

@main
@MainActor
struct CadenceApp: App {
    @State private var store = TodoStore()

    var body: some Scene {
        WindowGroup(id: "main") {
            TodoListView()
                .environment(store)
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
}
