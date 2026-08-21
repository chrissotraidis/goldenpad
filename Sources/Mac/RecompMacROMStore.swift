import AppKit
import Foundation
import UniformTypeIdentifiers

@_silgen_name("goldenpad_recomp_validate_tlbfree_rom")
private func goldenPadRecompValidateTLBFreeROM(_ path: UnsafePointer<CChar>) -> Int32

@MainActor
final class RecompMacROMStore: ObservableObject {
    @Published private(set) var romURL: URL?
    @Published private(set) var status = "Choose your user-derived GoldenEye_TLBFREE.z64 to begin."

    let supportURL: URL

    init() {
        let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        supportURL = applicationSupport.appendingPathComponent("GoldenPad", isDirectory: true)
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
        let panel = NSOpenPanel()
        panel.title = "Choose GoldenEye_TLBFREE.z64"
        panel.message = "GoldenPad requires a compatible user-derived TLBFREE input. Retail ROM conversion is not included."
        panel.prompt = "Import"
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [UTType(filenameExtension: "z64") ?? .data]

        guard panel.runModal() == .OK, let source = panel.url else { return }
        importROM(from: source)
    }

    private var storedROMURL: URL {
        supportURL
            .appendingPathComponent("ROMs", isDirectory: true)
            .appendingPathComponent("GoldenEye_TLBFREE.z64")
    }

    private func importROM(from source: URL) {
        let securityScoped = source.startAccessingSecurityScopedResource()
        defer {
            if securityScoped { source.stopAccessingSecurityScopedResource() }
        }

        guard validate(source) else {
            status = "That file is not the expected GoldenEye NTSC-U TLBFREE input."
            return
        }

        let fileManager = FileManager.default
        let romDirectory = storedROMURL.deletingLastPathComponent()
        let temporary = romDirectory.appendingPathComponent(".GoldenEye_TLBFREE.importing-\(UUID().uuidString)")
        do {
            try fileManager.createDirectory(at: romDirectory, withIntermediateDirectories: true)
            try fileManager.copyItem(at: source, to: temporary)
            if fileManager.fileExists(atPath: storedROMURL.path) {
                _ = try fileManager.replaceItemAt(storedROMURL, withItemAt: temporary)
            } else {
                try fileManager.moveItem(at: temporary, to: storedROMURL)
            }
            romURL = storedROMURL
            status = "Compatible GoldenEye input imported."
        } catch {
            try? fileManager.removeItem(at: temporary)
            status = "Import failed: \(error.localizedDescription)"
        }
    }

    private func validate(_ url: URL) -> Bool {
        url.path.withCString { goldenPadRecompValidateTLBFreeROM($0) == 1 }
    }
}
