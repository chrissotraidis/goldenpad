import Foundation
@main struct DiagnosticsTests {
    static func main() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let log = folder.appendingPathComponent("runtime.log")
        try "t_ms=10 perf window_ms=2000 dl_delta=30\nt_ms=11 [GoldenPadRecomp] input: buttons=123\nt_ms=12 [GoldenPadRecomp] runtime: /Users/someone/private.rom token=abc\n".write(to: log, atomically: true, encoding: .utf8)
        let tail = GoldenPadDiagnostics.logTail(log)
        precondition(tail.contains("dl_delta=30"))
        precondition(!tail.contains("buttons") && !tail.contains("someone") && !tail.contains("abc"))
        let link = folder.appendingPathComponent("link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: log)
        precondition(GoldenPadDiagnostics.logTail(link) == "No diagnostic log available.")
        let url = GoldenPadDiagnostics.issueURL(problem: "A+B & C?", area: "Dam", frequency: "Often", context: "build=9")!
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
        precondition(url.host == "github.com" && url.path == "/chrissotraidis/goldenpad/issues/new")
        precondition(url.absoluteString.contains("%2B"))
        precondition(items.first(where: {$0.name == "body"})!.value!.contains("A+B & C?"))
        let huge = String(repeating: "🇯🇵", count: 2000)
        let largeURL = GoldenPadDiagnostics.issueURL(problem: huge, area: huge, frequency: huge, context: huge)
        precondition(largeURL == nil || largeURL!.absoluteString.utf8.count <= 7500)
        precondition(GoldenPadDiagnostics.redact("x@example.com /private/data/game.z64 password=hello").contains("<redacted>"))
        print("PASS filtered export, symlink exclusion, redaction, URL encoding and URL size bounds")
    }
}
