import Foundation

enum TouchDeviceClass: String, Codable, Sendable {
    case phone
    case tablet
}

enum TouchControlID: String, Codable, CaseIterable, Identifiable, Sendable {
    case move
    case look
    case fire
    case aim
    case interact
    case reload
    case crouch
    case weapon
    case pause
    case n64A
    case n64B
    case n64Z
    case n64L
    case n64R
    case n64Start
    case n64CUp
    case n64CDown
    case n64CLeft
    case n64CRight
    case n64DUp
    case n64DDown
    case n64DLeft
    case n64DRight

    var id: String { rawValue }

    var label: String {
        switch self {
        case .move: "MOVE"
        case .look: "LOOK"
        case .fire: "FIRE"
        case .aim: "AIM"
        case .interact: "ACTION"
        case .reload: "LOAD"
        case .crouch: "DUCK"
        case .weapon: "WEAPON"
        case .pause: "PAUSE"
        case .n64A: "A"
        case .n64B: "B"
        case .n64Z: "Z"
        case .n64L: "L"
        case .n64R: "R"
        case .n64Start: "START"
        case .n64CUp: "C↑"
        case .n64CDown: "C↓"
        case .n64CLeft: "C←"
        case .n64CRight: "C→"
        case .n64DUp: "↑"
        case .n64DDown: "↓"
        case .n64DLeft: "←"
        case .n64DRight: "→"
        }
    }

    var isStick: Bool { self == .move || self == .look }
    var canHide: Bool { self != .move }
}

struct TouchControlPlacement: Codable, Equatable, Identifiable, Sendable {
    var id: TouchControlID
    var x: Double
    var y: Double
    var scale: Double = 1
    var isHidden = false

    func sanitized() -> TouchControlPlacement {
        var copy = self
        copy.x = copy.x.clamped(to: 0.04...0.96)
        copy.y = copy.y.clamped(to: 0.08...0.92)
        copy.scale = copy.scale.clamped(to: 0.70...1.50)
        if !copy.id.canHide {
            copy.isHidden = false
        }
        return copy
    }
}

struct TouchLayoutOverrides: Codable, Equatable, Sendable {
    var placements: [TouchControlPlacement] = []
}

enum TouchLayoutDefaults {
    static func placements(
        preset: ControlPreset,
        deviceClass: TouchDeviceClass
    ) -> [TouchControlPlacement] {
        let tablet = deviceClass == .tablet
        switch preset {
        case .modern, .southpaw:
            let southpaw = preset == .southpaw
            let moveX = southpaw ? (tablet ? 0.87 : 0.86) : (tablet ? 0.13 : 0.14)
            let lookX = southpaw ? (tablet ? 0.22 : 0.29) : (tablet ? 0.78 : 0.71)
            // Keep the action rail close to the look surface, but clear of a
            // landscape phone's rounded edge.
            let fireX = southpaw
                ? (tablet ? 0.09 : 0.13)
                : (tablet ? 0.91 : 0.87)
            let weaponX = southpaw
                ? (tablet ? 0.29 : 0.35)
                : (tablet ? 0.71 : 0.65)
            let crouchX = southpaw
                ? (tablet ? 0.19 : 0.24)
                : (tablet ? 0.81 : 0.76)
            return [
                placement(.move, moveX, tablet ? 0.82 : 0.80, tablet ? 1.14 : 1.08),
                placement(.look, lookX, tablet ? 0.72 : 0.68),
                placement(.fire, fireX, tablet ? 0.71 : 0.69, 1.16),
                placement(.aim, fireX, tablet ? 0.58 : 0.55),
                placement(.interact, fireX, tablet ? 0.84 : 0.83, 0.94),
                placement(.crouch, crouchX, tablet ? 0.89 : 0.85, 0.82),
                placement(.weapon, weaponX, tablet ? 0.89 : 0.85, 0.82),
            ]
        case .classic:
            return [
                placement(.move, tablet ? 0.17 : 0.19, tablet ? 0.72 : 0.70, tablet ? 1.18 : 1),
                placement(.n64A, 0.87, 0.69, 1.08),
                placement(.n64B, 0.79, 0.78),
                placement(.n64Z, 0.72, 0.64),
                placement(.n64L, 0.72, 0.87, 0.82),
                placement(.n64R, 0.88, 0.87, 0.82),
                placement(.n64Start, 0.50, 0.16, 0.78),
                placement(.n64CUp, 0.89, 0.31, 0.74),
                placement(.n64CDown, 0.89, 0.48, 0.74),
                placement(.n64CLeft, 0.84, 0.40, 0.74),
                placement(.n64CRight, 0.94, 0.40, 0.74),
                placement(.n64DUp, 0.10, 0.34, 0.70),
                placement(.n64DDown, 0.10, 0.51, 0.70),
                placement(.n64DLeft, 0.05, 0.43, 0.70),
                placement(.n64DRight, 0.15, 0.43, 0.70),
            ]
        }
    }

    static func resolved(
        preset: ControlPreset,
        deviceClass: TouchDeviceClass,
        overrides: TouchLayoutOverrides?
    ) -> [TouchControlPlacement] {
        var placements = Dictionary(
            uniqueKeysWithValues: self.placements(preset: preset, deviceClass: deviceClass)
                .map { ($0.id, $0) }
        )
        for override in overrides?.placements ?? [] where placements[override.id] != nil {
            placements[override.id] = override.sanitized()
        }
        return self.placements(preset: preset, deviceClass: deviceClass).compactMap {
            placements[$0.id]?.sanitized()
        }
    }

    private static func placement(
        _ id: TouchControlID,
        _ x: Double,
        _ y: Double,
        _ scale: Double = 1
    ) -> TouchControlPlacement {
        TouchControlPlacement(id: id, x: x, y: y, scale: scale)
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
