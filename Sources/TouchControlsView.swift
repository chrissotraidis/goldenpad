import SwiftUI
import simd

struct TouchInputLab: View {
    @EnvironmentObject private var input: InputCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("TOUCH INPUT LAB")
                        .font(.caption2.weight(.bold))
                        .tracking(1.4)
                    Text("Feeds the same normalized snapshot as a controller.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.58))
                }
                Spacer()
                Image(systemName: "hand.draw")
                    .foregroundStyle(.white.opacity(0.52))
            }

            HStack(alignment: .center, spacing: 14) {
                VirtualStick(title: "MOVE", systemImage: "figure.walk") {
                    input.updateMovement($0)
                }

                VirtualStick(title: "LOOK", systemImage: "eye") {
                    input.updateLook($0)
                }

                VStack(spacing: 10) {
                    MomentaryAction(title: "FIRE", systemImage: "bolt.fill", tint: .orange) {
                        input.setTouchButton(.fire, pressed: $0)
                    }
                    MomentaryAction(title: "AIM", systemImage: "scope", tint: .mint) {
                        input.setTouchButton(.aim, pressed: $0)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 112)
        }
        .padding(18)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        }
    }
}

private struct VirtualStick: View {
    let title: String
    let systemImage: String
    let onChange: (SIMD2<Float>) -> Void

    @State private var normalized = SIMD2<Float>.zero

    var body: some View {
        GeometryReader { geometry in
            let diameter = min(geometry.size.width, geometry.size.height)
            let travel = diameter * 0.27

            ZStack {
                Circle()
                    .fill(.black.opacity(0.28))
                Circle()
                    .stroke(.white.opacity(0.12), lineWidth: 1)
                Circle()
                    .fill(.white.opacity(0.14))
                    .frame(width: diameter * 0.46, height: diameter * 0.46)
                    .overlay {
                        Image(systemName: systemImage)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.74))
                    }
                    .offset(
                        x: CGFloat(normalized.x) * travel,
                        y: CGFloat(-normalized.y) * travel
                    )

                Text(title)
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.48))
                    .offset(y: diameter * 0.38)
            }
            .frame(width: diameter, height: diameter)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        let radius = max(diameter / 2, 1)
                        var vector = SIMD2<Float>(
                            Float((value.location.x - center.x) / radius),
                            Float((center.y - value.location.y) / radius)
                        )
                        let magnitude = simd_length(vector)
                        if magnitude > 1 {
                            vector /= magnitude
                        }
                        normalized = vector
                        onChange(vector)
                    }
                    .onEnded { _ in
                        normalized = .zero
                        onChange(.zero)
                    }
            )
            .accessibilityLabel("\(title.lowercased()) touch stick")
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MomentaryAction: View {
    let title: String
    let systemImage: String
    let tint: Color
    let onChange: (Bool) -> Void

    @State private var pressed = false

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption2.weight(.bold))
            .foregroundStyle(pressed ? .black : .white.opacity(0.82))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                pressed ? tint : .white.opacity(0.1),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !pressed else { return }
                        pressed = true
                        onChange(true)
                    }
                    .onEnded { _ in
                        pressed = false
                        onChange(false)
                    }
            )
            .accessibilityAddTraits(.isButton)
    }
}
