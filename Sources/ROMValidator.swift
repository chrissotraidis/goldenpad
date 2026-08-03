import CryptoKit
import Foundation

@_silgen_name("goldenpad_mgb64_core_accepts_rom")
private func goldenPadMGB64CoreAcceptsROM() -> Int32

@_silgen_name("goldenpad_mgb64_clear_rom")
private func goldenPadMGB64ClearROM()

@_silgen_name("goldenpad_mgb64_install_validated_rom")
private func goldenPadMGB64InstallValidatedROM(
    _ bytes: UnsafeRawPointer?,
    _ size: UInt32
) -> Int32

enum ROMValidator {
    private static let expectedSize = 12 * 1024 * 1024
    private static let expectedUSSHA1 = "abe01e4aeb033b6c0836819f549c791b26cfde83"

    static func validate(url: URL) -> ROMValidationState {
        if goldenPadMGB64CoreAcceptsROM() == 1 {
            goldenPadMGB64ClearROM()
        }
        let hasScopedAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasScopedAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let source = try Data(contentsOf: url, options: [.mappedIfSafe])
            guard source.count == expectedSize else {
                return .invalid("Expected a 12 MiB original retail dump; this file is \(source.count) bytes.")
            }

            let normalized: Data
            let byteOrder: String

            switch Array(source.prefix(4)) {
            case [0x80, 0x37, 0x12, 0x40]:
                normalized = source
                byteOrder = "Z64 big-endian"
            case [0x37, 0x80, 0x40, 0x12]:
                normalized = swapPairs(source)
                byteOrder = "V64 byte-swapped"
            case [0x40, 0x12, 0x37, 0x80]:
                normalized = reverseWords(source)
                byteOrder = "N64 little-endian"
            default:
                return .invalid("The file does not have a recognized Nintendo 64 ROM header.")
            }

            let digest = Insecure.SHA1.hash(data: normalized)
                .map { String(format: "%02x", $0) }
                .joined()

            guard digest == expectedUSSHA1 else {
                return .invalid("The dump is not the supported original US retail revision (SHA-1 mismatch).")
            }

            var coreLoaded = false
            if goldenPadMGB64CoreAcceptsROM() == 1 {
                let installed = normalized.withUnsafeBytes { bytes in
                    goldenPadMGB64InstallValidatedROM(bytes.baseAddress, UInt32(bytes.count))
                }
                guard installed == 1 else {
                    return .invalid("The validated dump could not be installed in volatile core memory.")
                }
                coreLoaded = true
                print("[GoldenPad] Validated ROM installed in volatile MGB64 memory")
            }

            return .valid(byteOrder: byteOrder, coreLoaded: coreLoaded)
        } catch {
            return .invalid("The selected file could not be read: \(error.localizedDescription)")
        }
    }

    private static func swapPairs(_ source: Data) -> Data {
        var bytes = [UInt8](source)
        for index in stride(from: 0, to: bytes.count, by: 2) {
            bytes.swapAt(index, index + 1)
        }
        return Data(bytes)
    }

    private static func reverseWords(_ source: Data) -> Data {
        var bytes = [UInt8](source)
        for index in stride(from: 0, to: bytes.count, by: 4) {
            bytes.swapAt(index, index + 3)
            bytes.swapAt(index + 1, index + 2)
        }
        return Data(bytes)
    }
}
