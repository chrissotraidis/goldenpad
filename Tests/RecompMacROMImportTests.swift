import Foundation

@main
struct RecompMacROMImportTests {
    @MainActor
    static func main() async throws {
        let args = CommandLine.arguments
        guard args.count == 3 || args.count == 4 else {
            fatalError("Usage: test PATCH_PATH VERIFIED_TLBFREE_PATH [RETAIL_PATH]")
        }
        func check(_ condition: Bool, _ message: String = "Check failed") { precondition(condition, message) }
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("GoldenPadImportTest-\(UUID().uuidString)")
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: root) }
        let patch = URL(fileURLWithPath: args[1])
        let expected = try Data(contentsOf: URL(fileURLWithPath: args[2]))
        let store = RecompMacROMStore(supportURL: root.appendingPathComponent("support"), patchURL: patch)
        precondition(store.romURL == nil)

        func checkImport(_ bytes: Data, name: String) async throws {
            let source = root.appendingPathComponent(name)
            try bytes.write(to: source)
            await store.importROM(from: source)
            precondition(!store.isImporting)
            guard let output = store.romURL else { fatalError(store.status) }
            check(try Data(contentsOf: output) == expected)
            check(try Data(contentsOf: source) == bytes, "Original changed")
            precondition(store.status == "Compatible GoldenEye input imported.", store.status)
        }
        func byteOrders(_ data: Data) -> [(String, Data)] {
            var v64 = [UInt8](data)
            var n64 = v64
            for i in stride(from: 0, to: v64.count, by: 2) { v64.swapAt(i, i + 1) }
            for i in stride(from: 0, to: n64.count, by: 4) {
                n64.swapAt(i, i + 3)
                n64.swapAt(i + 1, i + 2)
            }
            return [("z64", data), ("rom", data), ("v64", Data(v64)), ("n64", Data(n64))]
        }
        for (ext, bytes) in byteOrders(expected) {
            try await checkImport(bytes, name: "prepared.\(ext)")
        }
        let stored = store.romURL!
        await store.importROM(from: stored)
        check(try Data(contentsOf: stored) == expected, "Self import failed")
        let reopened = RecompMacROMStore(supportURL: store.supportURL, patchURL: nil)
        precondition(reopened.romURL == stored, "Existing install was not recognized")
        await reopened.importROM(from: root.appendingPathComponent("prepared.z64"))
        precondition(reopened.status == "Compatible GoldenEye input imported.")

        for (name, data) in [("truncated.z64", Data(expected.prefix(20))),
                             ("invalid.z64", Data(repeating: 0, count: expected.count)),
                             ("modified.z64", expected.dropLast() + Data([expected.last! ^ 1]))] {
            let source = root.appendingPathComponent(name)
            try data.write(to: source)
            await store.importROM(from: source)
            precondition(store.status != "Compatible GoldenEye input imported.")
            precondition(store.romURL == stored)
            check(try Data(contentsOf: stored) == expected, "Rejected import replaced existing data")
        }
        await store.importROM(from: root.appendingPathComponent("missing.z64"))
        precondition(store.status.contains("could not read"))
        check(try Data(contentsOf: stored) == expected)

        if args.count == 4 {
            let retail = try Data(contentsOf: URL(fileURLWithPath: args[3]))
            for (ext, bytes) in byteOrders(retail) {
                try await checkImport(bytes, name: "retail.\(ext)")
            }
            let missingPatch = RecompMacROMStore(supportURL: store.supportURL, patchURL: nil)
            await missingPatch.importROM(from: root.appendingPathComponent("retail.z64"))
            precondition(missingPatch.status.contains("conversion data"))
            check(try Data(contentsOf: stored) == expected)
            let badPatch = root.appendingPathComponent("bad.gep1")
            try Data(repeating: 0, count: 20).write(to: badPatch)
            let corruptPatch = RecompMacROMStore(supportURL: store.supportURL, patchURL: badPatch)
            await corruptPatch.importROM(from: root.appendingPathComponent("retail.z64"))
            precondition(corruptPatch.status.contains("conversion data"))
            check(try Data(contentsOf: stored) == expected)
            print("PASS: original retail conversion in all byte orders; missing/invalid patch preserves stored ROM")
        } else {
            print("SKIP: original retail conversion (provide RETAIL_PATH)")
        }
        let files = try fm.contentsOfDirectory(atPath: stored.deletingLastPathComponent().path)
        precondition(files == ["GoldenEye_TLBFREE.z64"], "Temporary import files leaked")
        print("PASS: prepared imports in all byte orders, replacement, self import, reload, invalid/unreadable input preservation, temporary cleanup")
    }
}
