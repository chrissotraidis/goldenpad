enum RecompTouchFireSource: String, CaseIterable, Hashable {
    case primary
    case secondary
}

struct RecompTouchFireState: Equatable {
    private(set) var activeSources: Set<RecompTouchFireSource> = []

    var isPressed: Bool {
        !activeSources.isEmpty
    }

    mutating func setPressed(_ pressed: Bool, source: RecompTouchFireSource) {
        if pressed {
            activeSources.insert(source)
        } else {
            activeSources.remove(source)
        }
    }

    mutating func reset() {
        activeSources.removeAll(keepingCapacity: true)
    }
}
