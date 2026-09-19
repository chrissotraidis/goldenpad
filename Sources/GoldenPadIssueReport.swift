import SwiftUI
import UniformTypeIdentifiers
#if os(iOS)
import UIKit
#endif

struct GoldenPadIssueReport: View {
    @State private var context: String
    let supportURL: URL
    init(context: String, supportURL: URL) {
        self._context = State(initialValue: "Report: GP-" + String(UUID().uuidString.prefix(8)) + "\n" + context)
        self.supportURL = supportURL
    }
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var problem = ""
    @State private var area = ""
    @State private var frequency = ""
    @State private var openFailed = false
    @State private var exporting = false
    @State private var exportFailed = false
    @State private var document = GoldenPadReportDocument(text: "")
    @State private var sharedReport: SharedReport?

    private var draftURL: URL? {
        GoldenPadDiagnostics.issueURL(problem: problem, area: area, frequency: frequency, context: context)
    }
    private var preview: String {
        draftURL.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "body" })?.value } ?? "Please shorten your answers to fit the GitHub draft."
    }
    private var reportText: String {
        preview + "\n\n" + GoldenPadDiagnostics.report(context: context, support: supportURL)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Tell us what went wrong. GoldenPad adds your build, device and recent performance details to a GitHub draft.")
                    Text("For visual problems, attach a screenshot or short video on GitHub.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("What happened?") {
                    TextField("Describe the problem", text: $problem, axis: .vertical)
                        .lineLimit(2...4)
                    TextField("Mission / area and what you were doing", text: $area)
                    TextField("Every time, sometimes, once, or not sure?", text: $frequency)
                }
                Section {
                    Button {
                        guard let url = draftURL else { return }
                        openURL(url) { accepted in openFailed = !accepted }
                    } label: {
                        Label("Report on GitHub", systemImage: "arrow.up.right.square")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(draftURL == nil)
                    Button(action: shareReport) {
                        Label("Share Diagnostic Report…", systemImage: "square.and.arrow.up")
                    }
                    Text("GitHub reports are public. You review and submit the draft there. Share the report to Files if you want to attach the detailed logs; nothing is uploaded automatically.")
                        .font(.footnote).foregroundStyle(.secondary)
                    if draftURL == nil {
                        Text("Shorten your answers to open the GitHub draft.").foregroundStyle(.red)
                    }
                }
                Section {
                    DisclosureGroup("Review technical details and draft") {
                        Text(preview).font(.footnote).textSelection(.enabled)
                    }
                    Text("Reports exclude game files, saves, raw controller inputs and private network traces. Review your own answers before sharing.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Report a Problem")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
            #if os(iOS)
            .sheet(item: $sharedReport) { report in
                GoldenPadReportShareSheet(url: report.url)
            }
            #else
            .fileExporter(isPresented: $exporting, document: document, contentType: .plainText, defaultFilename: "GoldenPad-Diagnostics") { result in
                if case .failure = result { exportFailed = true }
            }
            #endif
            .alert("Could not save report", isPresented: $exportFailed) { Button("OK", role: .cancel) {} }
            .alert("Could not open GitHub", isPresented: $openFailed) {
                Button("OK", role: .cancel) {}
            } message: { Text("Please try again, or visit github.com/chrissotraidis/goldenpad/issues in your browser.") }
        }
        #if os(macOS)
        .frame(width: 640, height: 650)
        #endif
    }

    private func shareReport() {
        #if os(iOS)
        do {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("GoldenPad-Diagnostics.txt")
            try reportText.write(to: url, atomically: true, encoding: .utf8)
            sharedReport = SharedReport(url: url)
        } catch { exportFailed = true }
        #else
        document = GoldenPadReportDocument(text: reportText)
        exporting = true
        #endif
    }
}

private struct SharedReport: Identifiable {
    let id = UUID()
    let url: URL
}
#if os(iOS)
private struct GoldenPadReportShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
#endif

private struct GoldenPadReportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    var text: String
    init(text: String) { self.text = text }
    init(configuration: ReadConfiguration) throws { text = String(decoding: configuration.file.regularFileContents ?? Data(), as: UTF8.self) }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: Data(text.utf8)) }
}
