import SwiftUI

/// A 1px hairline divider.
struct Hairline: View {
    var body: some View {
        Rectangle().fill(Palette.hairline).frame(height: 1)
    }
}

/// A rounded translucent panel — the core grouping element of the layout.
struct Card<Content: View>: View {
    var padding: CGFloat = 14
    var radius: CGFloat = 14
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.cardFill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Palette.hairline, lineWidth: 1)
            )
    }
}

/// Small duration / utility chip.
struct Keycap<Label: View>: View {
    @ViewBuilder var label: () -> Label

    var body: some View {
        label()
            .font(Typography.keycap)
            .foregroundStyle(Palette.mute)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Palette.controlFill, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(Palette.hairline, lineWidth: 1)
            )
    }
}

/// The primary action pill — high-contrast monochrome (dark on light / white on dark).
struct WhitePillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.strong)
            .foregroundStyle(Palette.onPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .background(
                configuration.isPressed ? Palette.primaryPressed : Palette.primary,
                in: RoundedRectangle(cornerRadius: 9, style: .continuous)
            )
            .contentShape(Rectangle())
    }
}

/// Display-Buddy-style segmented / soft button: translucent control fill + hairline.
struct SoftButtonStyle: ButtonStyle {
    var height: CGFloat = 30

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.strong)
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 11)
            .frame(height: height)
            .background(
                configuration.isPressed ? Palette.controlPressed : Palette.controlFill,
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Palette.hairline, lineWidth: 1)
            )
            .contentShape(Rectangle())
    }
}

/// A non-interactive Display-Buddy capsule slider used for the countdown progress.
struct SliderProgress: View {
    var fraction: Double
    var tint: Color? = nil

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let fw = max(0, min(w, w * fraction))
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.sliderTrack).frame(height: 8)
                Capsule().fill(tint ?? Palette.sliderFill).frame(width: fw, height: 8)
                Circle()
                    .fill(Palette.knob)
                    .frame(width: 14, height: 14)
                    .shadow(color: .black.opacity(0.18), radius: 1.5, y: 0.5)
                    .offset(x: min(max(fw - 7, 0), w - 14))
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .frame(height: 14)
        .accessibilityHidden(true)
    }
}
