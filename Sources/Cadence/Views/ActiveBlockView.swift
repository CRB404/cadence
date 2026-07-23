import SwiftUI

/// The active-task card: title + a big rounded countdown + a Display-Buddy
/// capsule slider, with the start/break control and time's-up actions grouped
/// inside the same card.
@MainActor
struct ActiveBlockView: View {
    @Environment(TodoStore.self) private var store

    var body: some View {
        Card {
            if let item = store.activeItem {
                VStack(alignment: .leading, spacing: 12) {
                    titleRow(item)
                    countdown(item)
                    SliderProgress(
                        fraction: item.fractionRemaining,
                        tint: item.didFire ? Palette.accentRed : nil
                    )
                    controls(item)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("All clear")
                        .font(Typography.title)
                        .foregroundStyle(Palette.mute)
                    Text("Add a task below to begin.")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.ash)
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func titleRow(_ item: TodoItem) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(item.title)
                .font(Typography.title)
                .foregroundStyle(Palette.ink)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            Button {
                store.toggleComplete(item.id)
            } label: {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 18))
                    .foregroundStyle(Palette.ash)
            }
            .buttonStyle(.plain)
            .help("Mark done")
            .accessibilityLabel("Mark \(item.title) done")
        }
    }

    private func countdown(_ item: TodoItem) -> some View {
        Text(timerString(item.remainingSeconds))
            .font(Typography.timer)
            .foregroundStyle(item.didFire ? Palette.accentRed : Palette.ink)
            .monospacedDigit()
            .accessibilityLabel(item.didFire ? "Time's up" : "Time remaining")
            .accessibilityValue(timerString(item.remainingSeconds))
    }

    @ViewBuilder
    private func controls(_ item: TodoItem) -> some View {
        if item.didFire {
            HStack(spacing: 8) {
                Button("Done") { store.toggleComplete(item.id) }
                    .buttonStyle(SoftButtonStyle())
                Button("+5 min") { store.addFiveMinutes(item.id) }
                    .buttonStyle(SoftButtonStyle())
                Button("Move down") { store.moveToBottom(item.id) }
                    .buttonStyle(SoftButtonStyle())
            }
        } else if !item.hasStarted {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    durationEditor(item)
                    Text("Adjust, then Start")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.ash)
                }
                Button("Start") { store.start() }
                    .buttonStyle(WhitePillButtonStyle())
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Button(store.isOnBreak ? "Resume" : "Take a break") { store.toggleBreak() }
                    .buttonStyle(WhitePillButtonStyle())
                if store.isOnBreak {
                    Text("On a break")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.ash)
                }
            }
        }
    }

    private static let presets = [5, 10, 15, 20, 25, 30, 45, 60]

    private func durationEditor(_ item: TodoItem) -> some View {
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
        .accessibilityLabel("Set duration for \(item.title)")
    }
}
