import SwiftUI
import AppKit

/// A row in the "Suggested" inbox: title (linked to its source when available),
/// optional notes, duration keycap, and explicit Accept / Dismiss actions.
@MainActor
struct SuggestionRowView: View {
    @Environment(TodoStore.self) private var store
    let item: TodoItem

    private var sourceLink: URL? { item.sourceURL.flatMap(URL.init(string:)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                title
                Spacer(minLength: 6)
                Keycap { Text(durationLabel(item.durationSeconds)) }
            }
            if let notes = item.notes {
                Text(notes)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.mute)
                    .lineLimit(2)
            }
            HStack(spacing: 6) {
                Button("Accept") { store.acceptSuggestion(item.id) }
                    .buttonStyle(SoftButtonStyle(height: 24))
                Button("Dismiss") { store.dismissSuggestion(item.id) }
                    .buttonStyle(.plain)
                    .font(Typography.keycap)
                    .foregroundStyle(Palette.mute)
                    .padding(.horizontal, 6)
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var title: some View {
        if let url = sourceLink {
            Button { NSWorkspace.shared.open(url) } label: {
                Text(item.title)
                    .font(Typography.body)
                    .foregroundStyle(Palette.body)
                    .underline(true, color: Palette.hairlineStrong)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .buttonStyle(.plain)
            .help(url.absoluteString)
        } else {
            Text(item.title)
                .font(Typography.body)
                .foregroundStyle(Palette.body)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}
