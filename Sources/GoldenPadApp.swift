import SwiftUI
import UniformTypeIdentifiers

@main
struct GoldenPadApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var platform = PlatformCoordinator()

    var body: some Scene {
        WindowGroup {
            FoundationView()
                .environmentObject(platform)
                .onChange(of: scenePhase, initial: true) { _, phase in
                    platform.handle(scenePhase: phase)
                }
        }
    }
}

private struct FoundationView: View {
    @EnvironmentObject private var platform: PlatformCoordinator
    @State private var isImporterPresented = false
    @State private var validation: ROMValidationState = .notSelected
    @State private var performedAutomationValidation = false

    var body: some View {
        ZStack {
            MetalCanvas()
                .ignoresSafeArea()

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

                        Text(platform.statusSummary)
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
        .preferredColorScheme(.dark)
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            validateSelection(result)
        }
        .task {
            await runAutomationValidationIfRequested()
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
                validation = .invalid("The file picker failed: \(error.localizedDescription)")
            }
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

        guard
            !performedAutomationValidation,
            let path = argumentPath ?? ProcessInfo.processInfo.environment["GOLDENPAD_VALIDATE_ROM_PATH"]
        else { return }

        performedAutomationValidation = true
        validation = .validating
        validation = await Task.detached(priority: .userInitiated) {
            ROMValidator.validate(url: URL(fileURLWithPath: path))
        }.value
    }
}

enum ROMValidationState {
    case notSelected
    case validating
    case valid(byteOrder: String)
    case invalid(String)

    var title: String {
        switch self {
        case .notSelected: "Retail data required"
        case .validating: "Validating privately…"
        case .valid: "Supported retail revision"
        case .invalid: "Unsupported file"
        }
    }

    var detail: String {
        switch self {
        case .notSelected:
            "Choose your legally obtained original US retail dump. The file is read only for validation and is not bundled with the app."
        case .validating:
            "Normalizing byte order and checking the retail SHA-1 entirely on this device."
        case let .valid(byteOrder):
            "Validation passed (\(byteOrder)). Core integration is the next project gate; this foundation build does not start the game."
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
