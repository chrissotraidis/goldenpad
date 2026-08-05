import SwiftUI
import UniformTypeIdentifiers

private extension UTType {
    static let goldenPadN64ROM = UTType(
        importedAs: "com.chrissotraidis.goldenpad.n64-rom",
        conformingTo: .data
    )
}

@_silgen_name("goldenpad_mgb64_core_identity")
private func goldenPadMGB64CoreIdentity() -> UnsafePointer<CChar>

@_silgen_name("goldenpad_mgb64_core_probe")
private func goldenPadMGB64CoreProbe() -> UInt32

@_silgen_name("goldenpad_mgb64_audio_output_probe")
private func goldenPadMGB64AudioOutputProbe() -> Int32

@_silgen_name("goldenpad_mgb64_audio_callback_stats")
private func goldenPadMGB64AudioCallbackStats(
    _ callbacks: UnsafeMutablePointer<UInt64>?,
    _ requestedFrames: UnsafeMutablePointer<UInt64>?,
    _ renderedFrames: UnsafeMutablePointer<UInt64>?,
    _ shortfallFrames: UnsafeMutablePointer<UInt64>?
)

private enum MGB64CoreInfo {
    static let status: String = {
        let identity = String(cString: goldenPadMGB64CoreIdentity())
        let probe = goldenPadMGB64CoreProbe()
        return "\(identity) • probe 0x\(String(probe, radix: 16))"
    }()
}

@main
struct GoldenPadApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var input = InputCoordinator()
    @StateObject private var platform = PlatformCoordinator()
    @StateObject private var renderSurface = AppleRenderSurface()

    var body: some Scene {
        WindowGroup {
            FoundationView()
                .environmentObject(input)
                .environmentObject(platform)
                .environmentObject(renderSurface)
                .onChange(of: scenePhase, initial: true) { _, phase in
                    platform.handle(scenePhase: phase)
                    renderSurface.setActive(phase == .active)
                    if phase != .active {
                        input.releaseTouchInput()
                    }
                }
                .onChange(of: platform.settings, initial: true) { _, settings in
                    input.configure(settings: settings)
                    renderSurface.configure(resolution: settings.renderResolution)
                }
        }
    }
}

private struct FoundationView: View {
    @EnvironmentObject private var input: InputCoordinator
    @EnvironmentObject private var platform: PlatformCoordinator
    @EnvironmentObject private var renderSurface: AppleRenderSurface
    @State private var isImporterPresented = false
    @State private var validation: ROMValidationState = .notSelected
    @State private var performedAutomationValidation = false

    var body: some View {
        ZStack {
            MetalCanvas(surface: renderSurface, input: input)
                .ignoresSafeArea()

            if validation.gameStarted {
                GameplayTouchControls()
            } else {
                setupShell
            }
        }
        .preferredColorScheme(.dark)
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.goldenPadN64ROM],
            allowsMultipleSelection: false
        ) { result in
            validateSelection(result)
        }
        .onOpenURL { url in
            validateImportedURL(url)
        }
        .task {
            await runAutomationValidationIfRequested()
        }
        .onChange(of: validation.gameStarted) { _, started in
            guard started else { return }
            Task {
                await reportNativePCMWhenReady()
            }
        }
    }

    private func reportNativePCMWhenReady() async {
        for elapsedSeconds in 1...30 {
            do {
                try await Task.sleep(for: .seconds(1))
            } catch {
                return
            }
            if goldenPadMGB64AudioOutputProbe() == 1 {
                var callbacks: UInt64 = 0
                var requestedFrames: UInt64 = 0
                var renderedFrames: UInt64 = 0
                var shortfallFrames: UInt64 = 0
                goldenPadMGB64AudioCallbackStats(
                    &callbacks,
                    &requestedFrames,
                    &renderedFrames,
                    &shortfallFrames
                )
                print(
                    "[GoldenPad] Native PCM output probe: PASS " +
                    "after \(elapsedSeconds)s"
                )
                print(
                    "[GoldenPad] Audio callback health: callbacks=\(callbacks) " +
                    "requested=\(requestedFrames) rendered=\(renderedFrames) " +
                    "shortfall=\(shortfallFrames)"
                )
                return
            }
        }
        print("[GoldenPad] Native PCM output probe: FAIL timeout=30s")
    }

    private var setupShell: some View {
        ZStack {
            LinearGradient(
                colors: [.black.opacity(0.18), .black.opacity(0.78)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Spacer(minLength: max(24, geometry.safeAreaInsets.top))

                        Text("GOLDENPAD")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .tracking(3.2)
                            .foregroundStyle(.white.opacity(0.72))

                        Text("Native Apple ARM64 foundation")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("A clean mobile shell for a retail-ROM-powered native port. No game data is included or retained by this build.")
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .foregroundStyle(.white.opacity(0.78))
                            .fixedSize(horizontal: false, vertical: true)

                        validationCard

                        HStack(spacing: 10) {
                            Label("Metal", systemImage: "cube.transparent")
                            Label("iPhone + iPad", systemImage: "rectangle.on.rectangle")
                            Label("Asset-free", systemImage: "checkmark.shield")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.66))
                        .labelStyle(.titleAndIcon)

                        Text("\(platform.statusSummary)  •  \(renderSurface.status)")
                            .font(.caption2.monospaced())
                            .foregroundStyle(.white.opacity(0.46))

                        Text(MGB64CoreInfo.status)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.white.opacity(0.46))

                        TouchInputLab()

                        Text(input.diagnosticSummary)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.white.opacity(0.46))

                        Spacer(minLength: max(24, geometry.safeAreaInsets.bottom))
                    }
                    .frame(maxWidth: 720, alignment: .leading)
                    .padding(.horizontal, horizontalPadding(for: geometry.size.width))
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }

    private var validationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: validation.symbol)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(validation.tint)
                    .frame(width: 34)

                VStack(alignment: .leading, spacing: 5) {
                    Text(validation.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(validation.detail)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.68))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button {
                isImporterPresented = true
            } label: {
                Label("Select retail ROM", systemImage: "doc.badge.plus")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.32, green: 0.76, blue: 0.64))
            .accessibilityHint("Choose a Z64, V64, N64, or ROM file from Files")
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
    }

    private func horizontalPadding(for width: CGFloat) -> CGFloat {
        width < 600 ? 22 : 42
    }

    private func validateSelection(_ result: Result<[URL], Error>) {
        guard case let .success(urls) = result, let url = urls.first else {
            if case let .failure(error) = result {
                let cocoaError = error as NSError
                guard cocoaError.domain != NSCocoaErrorDomain ||
                        cocoaError.code != NSUserCancelledError else { return }
                validation = .invalid("The file picker failed: \(error.localizedDescription)")
            }
            return
        }

        validateImportedURL(url)
    }

    private func validateImportedURL(_ url: URL) {
        guard !validation.gameStarted else {
            print("[GoldenPad] Ignored ROM import while the native game is already running")
            return
        }
        validation = .validating

        Task {
            let state = await Task.detached(priority: .userInitiated) {
                ROMValidator.validate(url: url)
            }.value

            await MainActor.run {
                validation = state
            }
        }
    }

    private func runAutomationValidationIfRequested() async {
        let arguments = ProcessInfo.processInfo.arguments
        let argumentPath: String? = if let flag = arguments.firstIndex(of: "--validate-rom"),
                                      arguments.indices.contains(flag + 1) {
            arguments[flag + 1]
        } else {
            nil
        }
        let documentName: String? = if let flag = arguments.firstIndex(of: "--validate-rom-document"),
                                       arguments.indices.contains(flag + 1) {
            arguments[flag + 1]
        } else {
            nil
        }
        let validationURL: URL? = if let path = argumentPath
            ?? ProcessInfo.processInfo.environment["GOLDENPAD_VALIDATE_ROM_PATH"] {
            URL(fileURLWithPath: path)
        } else if let documentName,
                  let documents = FileManager.default.urls(
                    for: .documentDirectory,
                    in: .userDomainMask
                  ).first {
            documents.appendingPathComponent(documentName)
        } else {
            automaticROMDocumentURL()
        }

        guard
            !performedAutomationValidation,
            let validationURL
        else { return }

        performedAutomationValidation = true
        validation = .validating
        validation = await Task.detached(priority: .userInitiated) {
            ROMValidator.validate(url: validationURL)
        }.value
    }

    private func automaticROMDocumentURL() -> URL? {
        guard let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else { return nil }

        let supportedExtensions = Set(["z64", "v64", "n64", "rom"])
        return try? FileManager.default
            .contentsOfDirectory(
                at: documents,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            .filter { supportedExtensions.contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .first
    }
}

enum ROMValidationState {
    case notSelected
    case validating
    case valid(byteOrder: String, coreLoaded: Bool, gameStarted: Bool)
    case invalid(String)

    var title: String {
        switch self {
        case .notSelected: "Retail data required"
        case .validating: "Validating privately…"
        case .valid: "Supported retail revision"
        case .invalid: "Unsupported file"
        }
    }

    var gameStarted: Bool {
        if case let .valid(_, _, started) = self {
            return started
        }
        return false
    }

    var detail: String {
        switch self {
        case .notSelected:
            "Choose your legally obtained original US retail dump. The file is read only for validation and is not bundled with the app."
        case .validating:
            "Normalizing byte order and checking the retail SHA-1 entirely on this device."
        case let .valid(byteOrder, coreLoaded, gameStarted):
            if gameStarted {
                "Validation passed (\(byteOrder)). The native game loop is running from a private in-memory copy; no retail bytes were written to the app or repository."
            } else if coreLoaded {
                "Validation passed (\(byteOrder)). A private in-memory copy is available to the native core; no retail bytes were written to the app or repository."
            } else {
                "Validation passed (\(byteOrder)). This foundation build does not retain the selected file or start the game."
            }
        case let .invalid(reason):
            reason
        }
    }

    var symbol: String {
        switch self {
        case .notSelected: "externaldrive.badge.questionmark"
        case .validating: "hourglass"
        case .valid: "checkmark.seal.fill"
        case .invalid: "xmark.octagon.fill"
        }
    }

    var tint: Color {
        switch self {
        case .notSelected: .white.opacity(0.72)
        case .validating: .yellow
        case .valid: Color(red: 0.32, green: 0.76, blue: 0.64)
        case .invalid: .red
        }
    }
}
