import Foundation
import SwiftUI
import UIKit

enum RecompTouchDeviceClass: String, CaseIterable, Codable {
    case phone
    case tablet

    static var current: RecompTouchDeviceClass {
        UIDevice.current.userInterfaceIdiom == .pad ? .tablet : .phone
    }

    var title: String {
        switch self {
        case .phone: "iPhone"
        case .tablet: "iPad"
        }
    }

    var layoutTitle: String {
        switch self {
        case .phone: "iPhone Touch Layout"
        case .tablet: "iPad Touch Layout"
        }
    }

    var referenceCanvas: CGSize {
        switch self {
        case .phone: CGSize(width: 844, height: 390)
        case .tablet: CGSize(width: 1_366, height: 1_024)
        }
    }

    var referenceControlScale: CGFloat {
        switch self {
        case .phone: 0.82
        case .tablet: 1.18
        }
    }
}

enum RecompTouchControlID: String, CaseIterable, Codable, Identifiable {
    case move, look, fire, aim, action, crouch, weapon, pause

    var id: String { rawValue }

    var label: String {
        switch self {
        case .move: "MOVE"
        case .look: "LOOK"
        case .fire: "FIRE"
        case .aim: "AIM"
        case .action: "ACTION"
        case .crouch: "DUCK"
        case .weapon: "WEAPON"
        case .pause: "START"
        }
    }

    var n64Mask: UInt16 {
        switch self {
        case .move, .look: 0
        case .fire: 0x2000
        case .aim: 0x0010
        case .action: 0x4000
        case .crouch: 0
        case .weapon: 0x8000
        case .pause: 0x1000
        }
    }

    var tint: Color {
        switch self {
        case .fire, .aim: .gray
        case .weapon: .blue
        case .action: .green
        case .crouch: .yellow
        case .pause: .red
        default: .cyan
        }
    }

    var baseSize: CGSize {
        switch self {
        case .move: CGSize(width: 300, height: 260)
        case .look: CGSize(width: 320, height: 220)
        case .pause: CGSize(width: 64, height: 64)
        default: CGSize(width: 70, height: 70)
        }
    }

    var usesRoundedRectangle: Bool {
        self == .move || self == .look
    }
}

struct RecompTouchPlacement: Identifiable, Codable, Equatable {
    var id: RecompTouchControlID
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var opacity: CGFloat? = nil

    var resolvedOpacity: CGFloat {
        opacity ?? 0.72
    }

    func sanitized() -> RecompTouchPlacement {
        var copy = self
        copy.x = min(max(copy.x, 0), 1)
        copy.y = min(max(copy.y, 0), 1)
        copy.scale = min(max(copy.scale, 0.55), 1.60)
        if let opacity = copy.opacity {
            copy.opacity = min(max(opacity, 0.20), 1)
        }
        return copy
    }
}

enum RecompTouchLayoutDefaults {
    static func placements(for deviceClass: RecompTouchDeviceClass) -> [RecompTouchPlacement] {
        switch deviceClass {
        case .tablet:
            return [
                placement(.move, 0.13, 0.82, 1.14),
                placement(.look, 0.78, 0.72),
                placement(.fire, 0.91, 0.71, 1.16),
                placement(.aim, 0.91, 0.58),
                placement(.action, 0.91, 0.84, 0.94),
                placement(.crouch, 0.81, 0.89, 0.82),
                placement(.weapon, 0.71, 0.89, 0.82),
                placement(.pause, 0.972, 0.14, 0.78),
            ]
        case .phone:
            return [
                // Accepted on a physical iPhone 14 in landscape. Keep these
                // as the clean-install foundation; user edits remain separate.
                placement(.move, 0.188389, 0.726667),
                placement(.look, 0.781991, 0.687179, 0.70),
                placement(.fire, 0.938389, 0.573504, 1.10),
                placement(.aim, 0.942733, 0.408547, 0.95),
                placement(.action, 0.932070, 0.744444, 0.90),
                placement(.crouch, 0.909953, 0.898291, 0.78),
                placement(.weapon, 0.845182, 0.940171, 0.78),
                placement(.pause, 0.946288, 0.240171, 0.85),
            ]
        }
    }

    private static func placement(
        _ id: RecompTouchControlID,
        _ x: CGFloat,
        _ y: CGFloat,
        _ scale: CGFloat = 1
    ) -> RecompTouchPlacement {
        RecompTouchPlacement(id: id, x: x, y: y, scale: scale)
    }
}

enum RecompTouchLayoutGeometry {
    static func renderedSize(
        for placement: RecompTouchPlacement,
        canvas: CGSize,
        deviceClass: RecompTouchDeviceClass
    ) -> CGSize {
        let reference = deviceClass.referenceCanvas
        let canvasScale = min(
            canvas.width / max(reference.width, 1),
            canvas.height / max(reference.height, 1)
        )
        let scale = max(canvasScale, 0.01)
            * deviceClass.referenceControlScale
            * placement.scale
        return CGSize(
            width: placement.id.baseSize.width * scale,
            height: placement.id.baseSize.height * scale
        )
    }

    static func constrained(
        _ placement: RecompTouchPlacement,
        canvas: CGSize,
        deviceClass: RecompTouchDeviceClass
    ) -> RecompTouchPlacement {
        var copy = placement.sanitized()
        guard canvas.width > 0, canvas.height > 0 else { return copy }
        let size = renderedSize(for: copy, canvas: canvas, deviceClass: deviceClass)
        let halfX = min(size.width / canvas.width / 2, 0.49)
        let halfY = min(size.height / canvas.height / 2, 0.49)
        copy.x = min(max(copy.x, halfX), 1 - halfX)
        copy.y = min(max(copy.y, halfY), 1 - halfY)
        return copy
    }
}

@MainActor
final class RecompTouchLayoutStore: ObservableObject {
    @Published private var savedLayouts: [RecompTouchDeviceClass: [RecompTouchPlacement]] = [:]

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let decoder = JSONDecoder()
        for deviceClass in RecompTouchDeviceClass.allCases {
            guard let data = defaults.data(forKey: storageKey(for: deviceClass)),
                  let placements = try? decoder.decode([RecompTouchPlacement].self, from: data) else {
                continue
            }
            savedLayouts[deviceClass] = placements.map { $0.sanitized() }
        }
    }

    func placements(for deviceClass: RecompTouchDeviceClass) -> [RecompTouchPlacement] {
        let defaults = RecompTouchLayoutDefaults.placements(for: deviceClass)
        let saved = Dictionary(
            uniqueKeysWithValues: (savedLayouts[deviceClass] ?? []).map { ($0.id, $0) }
        )
        return defaults.map { saved[$0.id]?.sanitized() ?? $0 }
    }

    func hasCustomLayout(for deviceClass: RecompTouchDeviceClass) -> Bool {
        savedLayouts[deviceClass] != nil
    }

    func save(_ placements: [RecompTouchPlacement], for deviceClass: RecompTouchDeviceClass) {
        let resolved = RecompTouchLayoutDefaults.placements(for: deviceClass).compactMap { original in
            placements.first(where: { $0.id == original.id })?.sanitized()
        }
        guard resolved.count == RecompTouchControlID.allCases.count else { return }
        savedLayouts[deviceClass] = resolved
        if let data = try? JSONEncoder().encode(resolved) {
            defaults.set(data, forKey: storageKey(for: deviceClass))
        }
    }

    func reset(_ deviceClass: RecompTouchDeviceClass) {
        savedLayouts.removeValue(forKey: deviceClass)
        defaults.removeObject(forKey: storageKey(for: deviceClass))
    }

    private func storageKey(for deviceClass: RecompTouchDeviceClass) -> String {
        switch deviceClass {
        case .phone: "recomp.touchLayout.phone.v1"
        case .tablet: "recomp.touchLayout.tablet.v1"
        }
    }
}

struct RecompPrototypeLiveTouchLayoutEditor: View {
    @ObservedObject var store: RecompTouchLayoutStore
    let deviceClass: RecompTouchDeviceClass
    let onCancel: () -> Void
    let onDone: () -> Void

    @State private var placements: [RecompTouchPlacement] = []
    @State private var selectedID: RecompTouchControlID?
    @State private var canvasSize = CGSize.zero

    private var selectedIndex: Int? {
        placements.firstIndex { $0.id == selectedID }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(placements) { placement in
                    editorControl(placement, canvas: geometry.size)
                }

                editorPanel(canvas: geometry.size)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 18)
            }
            .coordinateSpace(name: "recomp-live-touch-layout")
            .onAppear { canvasSize = geometry.size }
            .onChange(of: geometry.size) { _, value in canvasSize = value }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(deviceClass.layoutTitle)
        .onAppear {
            guard placements.isEmpty else { return }
            placements = store.placements(for: deviceClass)
            selectedID = placements.first?.id
        }
    }

    private func editorPanel(canvas: CGSize) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Button("Cancel", action: onCancel)
                Spacer()
                VStack(spacing: 1) {
                    Text("EDIT TOUCH CONTROLS")
                        .font(.caption2.weight(.bold))
                        .tracking(1.2)
                    Text("Drag directly on the game")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Reset") {
                    placements = RecompTouchLayoutDefaults.placements(for: deviceClass)
                    selectedID = placements.first?.id
                }
                Button("Done") {
                    store.save(placements, for: deviceClass)
                    onDone()
                }
                .fontWeight(.semibold)
            }

            if let index = selectedIndex {
                HStack(spacing: 12) {
                    Text(placements[index].id.label)
                        .font(.caption.weight(.bold))
                        .frame(width: 62, alignment: .leading)
                    Slider(
                        value: Binding(
                            get: { placements[index].scale },
                            set: { updateSelectedScale($0) }
                        ),
                        in: 0.55...1.60,
                        step: 0.05
                    )
                    .accessibilityLabel("\(placements[index].id.label) size")
                    Text("\(Int((placements[index].scale * 100).rounded()))%")
                        .font(.caption.monospacedDigit())
                        .frame(width: 42, alignment: .trailing)
                }

                HStack(spacing: 12) {
                    Text("OPACITY")
                        .font(.caption.weight(.bold))
                        .frame(width: 62, alignment: .leading)
                    Slider(
                        value: Binding(
                            get: { placements[index].resolvedOpacity },
                            set: { updateSelectedOpacity($0) }
                        ),
                        in: 0.20...1,
                        step: 0.05
                    )
                    .accessibilityLabel("\(placements[index].id.label) opacity")
                    Text("\(Int((placements[index].resolvedOpacity * 100).rounded()))%")
                        .font(.caption.monospacedDigit())
                        .frame(width: 42, alignment: .trailing)
                }
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(width: min(500, max(canvas.width - 240, 320)))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.20), lineWidth: 1)
        }
    }

    @ViewBuilder
    private func editorControl(
        _ placement: RecompTouchPlacement,
        canvas: CGSize
    ) -> some View {
        let constrained = RecompTouchLayoutGeometry.constrained(
            placement,
            canvas: canvas,
            deviceClass: deviceClass
        )
        let size = RecompTouchLayoutGeometry.renderedSize(
            for: constrained,
            canvas: canvas,
            deviceClass: deviceClass
        )

        ZStack {
            switch placement.id {
            case .move:
                RecompStick(title: placement.id.label, symbol: "figure.walk") { _ in }
                    .allowsHitTesting(false)
            case .look:
                RecompLookSurface { _ in }
                    .allowsHitTesting(false)
            case .aim:
                RecompToggleButton(
                    title: placement.id.label,
                    tint: placement.id.tint,
                    activeTint: .yellow,
                    isOn: false
                ) {}
                .allowsHitTesting(false)
            default:
                RecompMomentaryButton(title: placement.id.label, tint: placement.id.tint) { _ in }
                    .allowsHitTesting(false)
            }
        }
        .frame(width: size.width, height: size.height)
        .opacity(max(constrained.resolvedOpacity, 0.30))
        .overlay {
            if placement.id.usesRoundedRectangle {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(selectedID == placement.id ? Color.yellow : .clear, lineWidth: 3)
            } else {
                Circle()
                    .stroke(selectedID == placement.id ? Color.yellow : .clear, lineWidth: 3)
            }
        }
        .contentShape(Rectangle())
        .position(x: canvas.width * constrained.x, y: canvas.height * constrained.y)
        .highPriorityGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .named("recomp-live-touch-layout"))
                .onChanged { value in
                    selectedID = placement.id
                    updatePlacement(
                        id: placement.id,
                        x: value.location.x / max(canvas.width, 1),
                        y: value.location.y / max(canvas.height, 1)
                    )
                }
        )
        .accessibilityLabel(placement.id.label)
        .accessibilityHint("Drag to move; use the size and opacity sliders at the top")
    }

    private func updatePlacement(id: RecompTouchControlID, x: CGFloat, y: CGFloat) {
        guard let index = placements.firstIndex(where: { $0.id == id }) else { return }
        placements[index].x = x
        placements[index].y = y
        placements[index] = RecompTouchLayoutGeometry.constrained(
            placements[index],
            canvas: canvasSize,
            deviceClass: deviceClass
        )
    }

    private func updateSelectedScale(_ scale: CGFloat) {
        guard let index = selectedIndex else { return }
        placements[index].scale = scale
        placements[index] = RecompTouchLayoutGeometry.constrained(
            placements[index],
            canvas: canvasSize,
            deviceClass: deviceClass
        )
    }

    private func updateSelectedOpacity(_ opacity: CGFloat) {
        guard let index = selectedIndex else { return }
        placements[index].opacity = min(max(opacity, 0.20), 1)
    }
}
