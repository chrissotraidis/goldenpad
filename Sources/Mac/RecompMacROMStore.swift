import AppKit
import Foundation
import UniformTypeIdentifiers

@_silgen_name("goldenpad_recomp_validate_tlbfree_rom")
private func goldenPadRecompValidateTLBFreeROM(_ path: UnsafePointer<CChar>) -> Int32

@_silgen_name("goldenpad_recomp_import_rom")
private func goldenPadRecompImportROM(
    _ source: UnsafePointer<CChar>,
    _ patch: UnsafePointer<CChar>,
    _ output: UnsafePointer<CChar>
) -> Int32

@MainActor
final class RecompMacROMStore: ObservableObject {
    @Published private(set) var romURL: URL?
    @Published private(set) var status = "Choose your original NTSC-U GoldenEye 007 ROM. GoldenPad prepares the required copy automatically."
    @Published private(set) var isImporting = false

    let supportURL: URL
    private let patchURL: URL?

    init(supportURL: URL? = nil,
         patchURL: URL? = Bundle.main.url(forResource: "vanilla_to_tlbfree", withExtension: "gep1")) {
        let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        self.supportURL = supportURL ?? applicationSupport.appendingPathComponent("GoldenPad", isDirectory: true)
        self.patchURL = patchURL
        refresh()
    }

    func refresh() {
        let candidate = storedROMURL
        guard FileManager.default.fileExists(atPath: candidate.path) else {
            romURL = nil
            return
        }
        if validate(candidate) {
            romURL = candidate
            status = "Compatible GoldenEye input ready."
        } else {
            romURL = nil
            status = "The stored input is not the expected GoldenEye TLBFREE ROM."
        }
    }

    func chooseROM() {
        guard !isImporting else { return }
        let panel = NSOpenPanel()
        panel.title = "Choose GoldenEye 007 ROM"
        panel.message = "Choose your original NTSC-U .z64, .v64, .n64, or .rom file. GoldenPad converts and verifies a private copy; your original is unchanged."
        panel.prompt = "Import"
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = ["z64", "v64", "n64", "rom"].compactMap { UTType(filenameExtension: $0) }

        guard panel.runModal() == .OK, let source = panel.url else { return }
        Task { await importROM(from: source) }
    }

    private var storedROMURL: URL {
        supportURL
            .appendingPathComponent("ROMs", isDirectory: true)
            .appendingPathComponent("GoldenEye_TLBFREE.z64")
    }

    func importROM(from source: URL) async {
        guard !isImporting else { return }
        isImporting = true
        defer { isImporting = false }
        let securityScoped = source.startAccessingSecurityScopedResource()
        defer {
            if securityScoped { source.stopAccessingSecurityScopedResource() }
        }

        let fileManager = FileManager.default
        let romDirectory = storedROMURL.deletingLastPathComponent()
        let temporary = romDirectory.appendingPathComponent(".GoldenEye_TLBFREE.importing-\(UUID().uuidString)")
        defer { try? fileManager.removeItem(at: temporary) }
        status = "Verifying and preparing your private game copy…"
        do {
            try fileManager.createDirectory(at: romDirectory, withIntermediateDirectories: true)
            // Already converted inputs remain usable even if the conversion resource is missing.
            let patch = patchURL
            let result = await Task.detached(priority: .userInitiated) {
                source.path.withCString { sourcePath in
                    (patch?.path ?? "").withCString { patchPath in
                        temporary.path.withCString { outputPath in
                            goldenPadRecompImportROM(sourcePath, patchPath, outputPath)
                        }
                    }
                }
            }.value
            guard result == 0 else {
                status = Self.message(for: result)
                return
            }
            guard validate(temporary) else {
                status = "The prepared ROM failed final verification. Your existing game file was not changed."
                return
            }
            if fileManager.fileExists(atPath: storedROMURL.path) {
                _ = try fileManager.replaceItemAt(storedROMURL, withItemAt: temporary)
            } else {
                try fileManager.moveItem(at: temporary, to: storedROMURL)
            }
            romURL = storedROMURL
            status = "Compatible GoldenEye input imported."
        } catch {
            status = "Import failed: \(error.localizedDescription)"
        }
    }

    private static func message(for result: Int32) -> String {
        switch result {
        case 2:
            return "GoldenPad could not read that file. Copy it to a local folder and try again."
        case 3:
            return "That file is not a supported Nintendo 64 ROM format. Choose an extracted .z64, .v64, .n64, or .rom file."
        case 4:
            return "That is not the supported original NTSC-U GoldenEye 007 ROM or verified TLBFREE input. Other regions, revisions, and modified ROMs are not supported."
        case 5, 6:
            return "This build’s ROM conversion data is missing or invalid. Please reinstall GoldenPad."
        case 7:
            return "The converted ROM failed verification. Your existing game file was not changed."
        case 8:
            return "GoldenPad could not write the prepared ROM. Check available storage and try again."
        default:
            return "This build could not import the ROM. Please reinstall GoldenPad."
        }
    }

    private func validate(_ url: URL) -> Bool {
        url.path.withCString { goldenPadRecompValidateTLBFreeROM($0) == 1 }
    }
}
