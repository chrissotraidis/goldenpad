import SwiftUI

@main
struct GoldenPadRecompPrototypeApp: App {
    @StateObject private var surface = RecompPrototypeSurface()

    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .bottomLeading) {
                RecompPrototypeMetalCanvas(surface: surface)
                    .ignoresSafeArea()
                Text(surface.status)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 8))
                    .padding()
            }
        }
    }
}
