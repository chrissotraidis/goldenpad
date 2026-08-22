import Foundation
import SwiftUI

#if GOLDENPAD_RECOMP_AOT_LINKED
@_silgen_name("goldenpad_recomp_import_rom")
private func goldenPadRecompImportROM(
    _ sourcePath: UnsafePointer<CChar>,
    _ patchPath: UnsafePointer<CChar>,
    _ outputPath: UnsafePointer<CChar>
) -> Int32

@_silgen_name("goldenpad_recomp_validate_tlbfree_rom")
private func goldenPadRecompValidateTLBFreeROM(_ romPath: UnsafePointer<CChar>) -> Int32
#endif

@MainActor
final class RecompPrototypeROMStore: ObservableObject {
    enum State {
        case checking
        case needsROM
        case importing
        case ready
        case failed(String)
    }

    @Published private(set) var state: State = .checking
    @Published var isImporterPresented = false

    private let fileManager = FileManager.default
    private let destinationURL: URL
    private var pendingOpenURL: URL?

    init() {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        destinationURL = documents.appendingPathComponent("GoldenEye_TLBFREE.z64")
        refresh()
    }

    var isReady: Bool {
        if case .ready = state {
            return true
        }
        return false
    }

    func presentImporter() {
        isImporterPresented = true
    }

    func handleSelection(_ result: Result<URL, Error>) {
        switch result {
        case let .success(url):
            importROM(from: url)
        case let .failure(error):
            if (error as NSError).code != NSUserCancelledError {
                state = .failed("The ROM picker could not open that file. Please try again.")
            }
        }
    }

    func handleOpenURL(_ url: URL) {
        switch state {
        case .checking:
            pendingOpenURL = url
        case .needsROM, .failed:
            importROM(from: url)
        case .importing, .ready:
            return
        }
    }

    private func refresh() {
        guard fileManager.fileExists(atPath: destinationURL.path) else {
            state = .needsROM
            return
        }
        state = .checking
        let destinationURL = destinationURL
        Task {
            let valid = await Task.detached(priority: .userInitiated) {
                Self.validateROM(at: destinationURL)
            }.value
            if valid {
                pendingOpenURL = nil
                state = .ready
            } else if let pendingOpenURL {
                self.pendingOpenURL = nil
                importROM(from: pendingOpenURL)
            } else {
                state = .failed("GoldenPad couldn't verify the game copy stored on this device. Choose your original NTSC-U GoldenEye 007 ROM to recreate it. Your original file will not be changed.")
            }
        }
    }

    private func importROM(from sourceURL: URL) {
        if case .importing = state {
            return
        }
        state = .importing
        let destinationURL = destinationURL
        let patchURL = Bundle.main.url(
                forResource: "vanilla_to_tlbfree",
                withExtension: "gep1"
            )
        Task {
            guard let patchURL else {
                state = .failed("This build is missing its ROM conversion data. Please reinstall GoldenPad.")
                return
            }

            let accessed = sourceURL.startAccessingSecurityScopedResource()
            defer {
                if accessed {
                    sourceURL.stopAccessingSecurityScopedResource()
                }
            }

            let temporaryURL = destinationURL.deletingLastPathComponent()
                .appendingPathComponent(".GoldenEye_TLBFREE.importing-\(UUID().uuidString).z64")
            defer { try? fileManager.removeItem(at: temporaryURL) }

            do {
                try fileManager.createDirectory(
                    at: destinationURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
            } catch {
                state = .failed("GoldenPad could not prepare its private Documents folder.")
                return
            }

            let result = await Task.detached(priority: .userInitiated) {
                Self.convertROM(source: sourceURL, patch: patchURL, output: temporaryURL)
            }.value
            guard result == 0 else {
                state = .failed(Self.message(for: result))
                return
            }

            let valid = await Task.detached(priority: .userInitiated) {
                Self.validateROM(at: temporaryURL)
            }.value
            guard valid else {
                state = .failed("The converted ROM failed final verification. Your existing game file was not changed.")
                return
            }

            do {
                try fileManager.setAttributes(
                    [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                    ofItemAtPath: temporaryURL.path
                )
                var resourceValues = URLResourceValues()
                resourceValues.isExcludedFromBackup = true
                var protectedURL = temporaryURL
                try protectedURL.setResourceValues(resourceValues)
            } catch {
                state = .failed("The ROM was converted, but GoldenPad could not protect its private copy. Your existing game file was not changed.")
                return
            }

            do {
                if fileManager.fileExists(atPath: destinationURL.path) {
                    _ = try fileManager.replaceItemAt(
                        destinationURL,
                        withItemAt: temporaryURL,
                        backupItemName: nil,
                        options: .usingNewMetadataOnly
                    )
                } else {
                    try fileManager.moveItem(at: temporaryURL, to: destinationURL)
                }
                state = .ready
            } catch {
                state = .failed("The ROM was converted, but GoldenPad could not save it. Your existing game file was not changed.")
            }
        }
    }

    nonisolated private static func convertROM(source: URL, patch: URL, output: URL) -> Int32 {
        #if GOLDENPAD_RECOMP_AOT_LINKED
        return source.path.withCString { sourcePath in
            patch.path.withCString { patchPath in
                output.path.withCString { outputPath in
                    goldenPadRecompImportROM(sourcePath, patchPath, outputPath)
                }
            }
        }
        #else
        return 1
        #endif
    }

    nonisolated private static func validateROM(at url: URL) -> Bool {
        #if GOLDENPAD_RECOMP_AOT_LINKED
        return url.path.withCString { goldenPadRecompValidateTLBFreeROM($0) == 1 }
        #else
        return false
        #endif
    }

    nonisolated private static func message(for result: Int32) -> String {
        switch result {
        case 2:
            return "GoldenPad could not read that file. Copy it to Files and try again."
        case 3:
            return "That file is not a supported Nintendo 64 ROM format. Choose a .z64, .v64, .n64, or .rom file."
        case 4:
            return "That is not the supported NTSC-U GoldenEye 007 ROM. GoldenPad will not modify or accept another revision."
        case 5, 6:
            return "This build's ROM conversion data is missing or invalid. Please reinstall GoldenPad."
        case 7:
            return "The converted ROM did not match the required TLB-free build. Your existing game file was not changed."
        case 8:
            return "GoldenPad could not write the temporary converted ROM. Check available storage and try again."
        default:
            return "This build cannot import a ROM. Please reinstall GoldenPad and try again."
        }
    }
}

struct RecompPrototypeROMSetupView: View {
    @ObservedObject var store: RecompPrototypeROMStore

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "shippingbox.and.arrow.backward")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.yellow)
                    .accessibilityHidden(true)
                Text("Set Up GoldenPad")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Text(message)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.82))
                    .frame(maxWidth: 600)

                if showsProgress {
                    ProgressView()
                        .tint(.yellow)
                        .controlSize(.large)
                } else {
                    Button("Choose Original ROM…") {
                        store.presentImporter()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.yellow)
                    .foregroundStyle(.black)
                    .controlSize(.large)
                }

                Text("GoldenPad converts and verifies a private copy on this device. The file you select stays in its original location.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.58))
                    .frame(maxWidth: 640)
            }
            .padding(32)
        }
    }

    private var showsProgress: Bool {
        switch store.state {
        case .checking, .importing:
            true
        case .needsROM, .ready, .failed:
            false
        }
    }

    private var message: String {
        switch store.state {
        case .checking:
            return "Checking for your game…"
        case .needsROM:
            return "Choose your original NTSC-U GoldenEye 007 ROM to begin. GoldenPad will prepare the required game copy on this device."
        case .importing:
            return "Verifying and preparing your private game copy…"
        case .ready:
            return "Your game is ready."
        case let .failed(message):
            return message
        }
    }
}
