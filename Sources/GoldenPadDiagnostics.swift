import Foundation
import Metal
import Darwin

@_silgen_name("goldenpad_diagnostics_flush")
private func flushGoldenPadDiagnostics()
@_silgen_name("goldenpad_diagnostics_summary")
private func goldenPadPerformanceSummary() -> UnsafePointer<CChar>

@_silgen_name("goldenpad_recomp_prepare_diagnostics")
private func prepareGoldenPadDiagnostics(_ path: UnsafePointer<CChar>)

enum GoldenPadDiagnostics {
    static func start(at support: URL) { support.path.withCString { prepareGoldenPadDiagnostics($0) } }

    static var metadata: String {
        let bundle = Bundle.main
        var model = [CChar](repeating: 0, count: 128)
        var length = model.count
        #if os(macOS)
        let key = "hw.model"
        #else
        let key = "hw.machine"
        #endif
        let hardware = sysctlbyname(key, &model, &length, nil, 0) == 0 ? String(cString: model) : "unknown"
        let source = bundle.url(forResource: "BuildIdentity", withExtension: "txt")
            .flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? "Source identity unavailable"
        return """
        GoldenPad \(bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "unknown") (build \(bundle.object(forInfoDictionaryKey: "CFBundleVersion") ?? "unknown"))
        \(source.trimmingCharacters(in: .whitespacesAndNewlines))
        Hardware: \(hardware); GPU: \(MTLCreateSystemDefaultDevice()?.name ?? "unavailable")
        OS: \(ProcessInfo.processInfo.operatingSystemVersionString)
        Memory: \(ProcessInfo.processInfo.physicalMemory / (1024 * 1024)) MiB; processors: \(ProcessInfo.processInfo.activeProcessorCount)
        Thermal state: \(ProcessInfo.processInfo.thermalState.rawValue); low power: \(ProcessInfo.processInfo.isLowPowerModeEnabled)
        \(String(cString: goldenPadPerformanceSummary()))
        """
    }

    static func redact(_ text: String) -> String {
        var result = text.replacingOccurrences(of: NSTemporaryDirectory(), with: "<TEMP>/")
            .replacingOccurrences(of: NSHomeDirectory(), with: "<HOME>")
        // Export only; never rewrite source logs. Cover paths outside the app container too.
        for pattern in [#"(?<![A-Za-z0-9])(?:file://)?/[^\r\n<>]+"#,
                        #"(?i)\b(?:https?://)[^\s<>]+"#,
                        #"(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b"#,
                        #"(?i)(?:token|password|secret|authorization)\s*[:=]\s*\S+"#,
                        #"(?i)\b[^\s<>]+\.(?:z64|v64|n64|rom|sav|eep)\b"#] {
            result = result.replacingOccurrences(of: pattern, with: "<redacted>", options: .regularExpression)
        }
        return result
    }

    static func logTail(_ url: URL, limit: Int = 256 * 1024) -> String {
        // Never follow a replaced log symlink or read arbitrary support files.
        guard let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey]),
              values.isRegularFile == true, values.isSymbolicLink != true,
              let handle = try? FileHandle(forReadingFrom: url) else { return "No diagnostic log available." }
        defer { try? handle.close() }
        do {
            let size = try handle.seekToEnd()
            let clipped = size > UInt64(limit)
            try handle.seek(toOffset: clipped ? size - UInt64(limit) : 0)
            let data = try handle.read(upToCount: limit) ?? Data()
            var lines = String(decoding: data, as: UTF8.self).components(separatedBy: .newlines)
            if clipped { lines.removeFirst() }
            // Input values, player memory/position dumps and private LAN traces stay local.
            let allowed = ["perf ", "timing ", "stall ", "diagnostics:", "session:", "runtime:", "launch:", "error:", "lifecycle:", "audio-rates:"]
            return redact(lines.filter { line in
                allowed.contains { line.hasPrefix($0) || line.contains("] " + $0) || line.range(of: #"^t_ms=\d+ "# + NSRegularExpression.escapedPattern(for: $0), options: .regularExpression) != nil }
            }.joined(separator: "\n"))
        } catch { return "The diagnostic log could not be read." }
    }

    static func logs(at support: URL) -> String {
        flushGoldenPadDiagnostics()
        let directory = support.appendingPathComponent("Logs", isDirectory: true)
        return ["goldenpad-recomp-previous.log.1", "goldenpad-recomp-previous.log", "goldenpad-recomp-latest.log.1", "goldenpad-recomp-latest.log"].map {
            "\($0)\n\(logTail(directory.appendingPathComponent($0)))"
        }.joined(separator: "\n\n")
    }

    static func report(context: String, support: URL) -> String {
        """
        GoldenPad Diagnostics v2
        \(metadata)
        \(redact(context))

        Timing values are wall durations; p95_upper_us is a histogram bound.
        VI calls and screen submissions are not unique game frames. GPU command durations may overlap.
        Logs are filtered; ROMs, saves, raw controller inputs and private network traces are excluded.
        Review before sharing. GitHub reports and attachments are public.

        \(logs(at: support))
        """
    }

    static func issueURL(problem: String, area: String, frequency: String, context: String) -> URL? {
        func bounded(_ value: String, _ length: Int) -> String { String(redact(value).prefix(length)) }
        var components = URLComponents(string: "https://github.com/chrissotraidis/goldenpad/issues/new")!
        let body = """
        ## What happened?
        \(bounded(problem, 300))
        ## Mission / area and activity
        \(bounded(area, 200))
        ## Frequency
        \(bounded(frequency, 120))
        ## Technical context
        \(bounded(context, 1600))
        ## Diagnostics
        Attach your reviewed exported report and optional screenshot here. No files are attached automatically.
        """
        components.queryItems = [URLQueryItem(name: "title", value: "[Bug]: " + bounded(problem.isEmpty ? "GoldenPad problem" : problem, 80)), URLQueryItem(name: "body", value: body)]
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        guard let url = components.url, url.absoluteString.utf8.count <= 7500 else { return nil }
        return url
    }
}
