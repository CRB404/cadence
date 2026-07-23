import SwiftUI

/// The main window: a small header, the active-task card, grouped "Up Next" and
/// "Done" cards, and a rounded add field — a light/dark frosted-glass panel in
/// the Display-Buddy idiom.
@MainActor
struct TodoListView: View {
    @Environment(TodoStore.self) private var store
    @State private var newTitle = ""
    @FocusState private var addFocused: Bool
    @AppStorage("appearance") private var appearance = "system"

    private var tailBase: Int { (store.activeIndex ?? -1) + 1 }

    private var firstCompleted: Int {
        store.items.firstIndex { $0.isComplete } ?? store.items.count
    }

    private var upcomingItems: [TodoItem] {
        guard tailBase < firstCompleted else { return [] }
        return Array(store.items[tailBase..<firstCompleted])
    }

    private var doneItems: [TodoItem] {
        store.items
            .filter { $0.isComplete }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    private var hasActive: Bool { store.activeItem != nil }

    var body: some View {
        VStack(spacing: 8) {
            header
            ActiveBlockView()
            if hasActive && !upcomingItems.isEmpty { upNextCard }
            if !doneItems.isEmpty { doneCard }
            addField
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 10)
        .frame(width: 300)
        .background {
            ZStack {
                VisualEffectBackground()
                Palette.glassTint
            }
            .ignoresSafeArea()
        }
        .background(WindowAccessor(onResolve: { store.mainWindow = $0 }))
        .onAppear(perform: applyAppearance)
        .onChange(of: appearance) { applyAppearance() }
    }

    private var header: some View {
        HStack {
            Text("Cadence")
                .font(Typography.strong)
                .foregroundStyle(Palette.mute)
            Spacer()
            Button(action: cycleAppearance) {
                Image(systemName: appearanceIcon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Palette.mute)
            }
            .buttonStyle(.plain)
            .help("Appearance: \(appearance.capitalized)")
            .accessibilityLabel("Cycle appearance")
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
        .padding(.bottom, 2)
    }

    private var appearanceIcon: String {
        switch appearance {
        case "light": return "sun.max"
        case "dark": return "moon"
        default: return "circle.lefthalf.filled"
        }
    }

    private func cycleAppearance() {
        appearance = appearance == "system" ? "light" : (appearance == "light" ? "dark" : "system")
    }

    private func applyAppearance() {
        switch appearance {
        case "light": NSApp.appearance = NSAppearance(named: .aqua)
        case "dark": NSApp.appearance = NSAppearance(named: .darkAqua)
        default: NSApp.appearance = nil
        }
    }

    private var upNextCard: some View {
        Card(padding: 8) {
            VStack(alignment: .leading, spacing: 4) {
                sectionHeader("Up Next", count: upcomingItems.count) { EmptyView() }
                upNextList
            }
        }
    }

    private var doneCard: some View {
        Card(padding: 8) {
            VStack(alignment: .leading, spacing: 4) {
                sectionHeader("Done", count: doneItems.count) {
                    Button("Clear") { store.clearCompleted() }
                        .buttonStyle(.plain)
                        .font(Typography.keycap)
                        .foregroundStyle(Palette.accent)
                }
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(doneItems) { TodoRowView(item: $0) }
                    }
                }
                .frame(height: min(CGFloat(doneItems.count) * 30 + 2, 140))
            }
        }
    }

    private func sectionHeader<Trailing: View>(
        _ title: String,
        count: Int,
        @ViewBuilder action: () -> Trailing
    ) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(Typography.keycap)
                .foregroundStyle(Palette.mute)
            Text("\(count)")
                .font(Typography.keycap)
                .foregroundStyle(Palette.ash)
            Spacer()
            action()
        }
        .padding(.horizontal, 4)
        .padding(.top, 2)
    }

    @ViewBuilder
    private var upNextList: some View {
        List {
            ForEach(upcomingItems) { item in
                TodoRowView(item: item)
                    .listRowInsets(EdgeInsets(top: 1, leading: 2, bottom: 1, trailing: 2))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .onMove { offsets, destination in
                store.moveTail(offsets, to: destination, base: tailBase)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, 30)
        .frame(height: min(CGFloat(upcomingItems.count) * 32 + 4, 200))
    }

    private var addField: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Palette.ash)
            TextField("Add a task…", text: $newTitle)
                .textFieldStyle(.plain)
                .font(Typography.body)
                .foregroundStyle(Palette.ink)
                .focused($addFocused)
                .onSubmit(add)
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(Palette.controlFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Palette.hairline, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { addFocused = true }
    }

    private func add() {
        store.addTask(newTitle)
        newTitle = ""
        addFocused = true
    }
}
