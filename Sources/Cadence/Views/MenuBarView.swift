import SwiftUI

/// The text shown in the system menu bar: live `MM:SS` of the active task,
/// or "Cadence" when idle. Reads the store directly so it ticks every second.
@MainActor
struct MenuBarLabel: View {
    let store: TodoStore

    var body: some View {
        Text(store.menuBarTitle)
            .monospacedDigit()
    }
}

/// The popover that drops from the menu bar (`.window` style): active task,
/// its countdown, the break toggle, +5, and window/quit controls.
@MainActor
struct MenuBarView: View {
    @Environment(TodoStore.self) private var store
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let item = store.activeItem {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(Typography.strong)
                        .foregroundStyle(Palette.ink)
                        .lineLimit(1)
                    Text(timerString(item.remainingSeconds))
                        .font(Typography.heading)
                        .foregroundStyle(item.didFire ? Palette.accentRed : Palette.ink)
                        .monospacedDigit()
                    if item.didFire {
                        Text("Time's up").font(Typography.caption).foregroundStyle(Palette.accentRed)
                    } else if !item.hasStarted {
                        Text("Ready").font(Typography.caption).foregroundStyle(Palette.ash)
                    } else if store.isOnBreak {
                        Text("On a break").font(Typography.caption).foregroundStyle(Palette.ash)
                    }
                }

                HStack(spacing: 8) {
                    Button {
                        store.toggleComplete(item.id)
                    } label: {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 15))
                    }
                    .buttonStyle(SoftButtonStyle(height: 34))
                    .help("Mark done")
                    .accessibilityLabel("Mark \(item.title) done")

                    if !item.hasStarted {
                        Button("Start") { store.start() }
                            .buttonStyle(WhitePillButtonStyle())
                    } else {
                        Button(store.isOnBreak ? "Resume" : "Take a break") { store.toggleBreak() }
                            .buttonStyle(WhitePillButtonStyle())
                    }

                    if item.didFire {
                        Button("+5") { store.addFiveMinutes(item.id) }
                            .buttonStyle(SoftButtonStyle(height: 34))
                    }
                }
            } else {
                Text("Cadence")
                    .font(Typography.strong)
                    .foregroundStyle(Palette.ink)
                Text("No active task.")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.ash)
            }

            Hairline()

            HStack {
                Button("Open Window") { showMainWindow() }
                    .buttonStyle(.plain)
                    .font(Typography.body)
                    .foregroundStyle(Palette.body)
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.plain)
                    .font(Typography.body)
                    .foregroundStyle(Palette.mute)
            }
        }
        .padding(14)
        .frame(width: 240)
        .background {
            ZStack {
                VisualEffectBackground()
                Palette.glassTint
            }
            .ignoresSafeArea()
        }
        .background(PopoverGlassAccessor())
    }

    /// Focus the existing main window if one is open; otherwise open a fresh,
    /// centered one. Always brings Cadence to the front.
    private func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = store.mainWindow {
            if window.isMiniaturized { window.deminiaturize(nil) }
            window.makeKeyAndOrderFront(nil)
        } else {
            openWindow(id: "main")
        }
    }
}
