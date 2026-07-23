import SwiftUI
import AppKit

/// Real frosted-glass: an `NSVisualEffectView` blurring whatever is *behind the
/// window* (the desktop / other apps). The macOS 14 equivalent of the look that
/// Apple's macOS 26 `.glassEffect()` ships natively.
struct VisualEffectBackground: NSViewRepresentable {
    // `.underWindowBackground` adapts to light/dark and lets the desktop frost
    // through — the Display-Buddy glass look in both modes.
    var material: NSVisualEffectView.Material = .underWindowBackground
    var blending: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blending
        view.state = .active
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.blendingMode = blending
        view.state = .active
    }
}

/// Makes the host `NSWindow` transparent so the behind-window blur shows through,
/// hides the title bar chrome, and lets the whole panel be dragged like a Raycast
/// HUD. Added as a zero-size `.background` so it can reach `view.window`.
struct WindowAccessor: NSViewRepresentable {
    /// Called with the resolved window so callers can keep a reference.
    var onResolve: (NSWindow) -> Void = { _ in }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var didCenter = false
    }

    func makeNSView(context: Context) -> NSView {
        NSView()
    }

    // Reapply on every update — SwiftUI resets the window's opacity/background
    // during layout, so a one-shot in makeNSView doesn't stick.
    func updateNSView(_ nsView: NSView, context: Context) {
        let coordinator = context.coordinator
        DispatchQueue.main.async {
            guard let window = nsView.window else { return }
            window.isOpaque = false
            window.backgroundColor = .clear
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isMovableByWindowBackground = true
            window.styleMask.insert(.fullSizeContentView)
            window.hasShadow = true

            // Center each freshly created window exactly once (not on every
            // layout pass, so the user can still move it).
            if !coordinator.didCenter {
                coordinator.didCenter = true
                window.center()
            }
            onResolve(window)
        }
    }
}

/// Minimal transparency for the `MenuBarExtra` popover panel so the behind-window
/// blur shows through. Unlike `WindowAccessor`, it leaves the panel's chrome and
/// drag behavior alone (a popover should not be draggable).
struct PopoverGlassAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { NSView() }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = nsView.window else { return }
            window.isOpaque = false
            window.backgroundColor = .clear
        }
    }
}
