import SwiftUI

/// A command-palette-style row in the "up next" list: complete toggle, title,
/// and an editable duration keycap. Reorder via drag; more actions via menu.
@MainActor
struct TodoRowView: View {
    @Environment(TodoStore.self) private var store
    let item: TodoItem

    private static let presets = [5, 10, 15, 20, 25, 30, 45, 60]

    var body: some View {
        HStack(spacing: 8) {
            Button {
                store.toggleComplete(item.id)
            } label: {
                Image(systemName: item.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundStyle(item.isComplete ? Palette.accentGreen : Palette.ash)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isComplete ? "Mark \(item.title) not done" : "Complete \(item.title)")

            Text(item.title)
                .font(Typography.body)
                .strikethrough(item.isComplete, color: Palette.mute)
                .foregroundStyle(item.isComplete ? Palette.mute : Palette.body)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 6)

            if item.isComplete {
                Text(relativeTime(item.completedAt))
                    .font(Typography.keycap)
                    .foregroundStyle(Palette.ash)
            } else {
                durationMenu
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .contentShape(Rectangle())
        .contextMenu {
            Button("Bump to top") { store.moveToTop(item.id) }
            Button("Move to bottom") { store.moveToBottom(item.id) }
            Divider()
            Button("Delete", role: .destructive) { store.delete(item.id) }
        }
    }

    private var durationMenu: some View {
        Menu {
            ForEach(Self.presets, id: \.self) { minutes in
                Button("\(minutes) min") { store.setDuration(item.id, minutes: minutes) }
            }
        } label: {
            Keycap { Text(durationLabel(item.durationSeconds)) }
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .accessibilityLabel("Duration for \(item.title)")
    }
}
