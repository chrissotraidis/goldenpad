import SwiftUI
import UniformTypeIdentifiers

struct GoldenPadIssueReport: View {
    @State private var context: String
    let supportURL: URL
    init(context: String, supportURL: URL) {
        self._context = State(initialValue: context)
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

    private var draftURL: URL? {
        GoldenPadDiagnostics.issueURL(problem: problem, area: area, frequency: frequency, context: context)
    }
    private var preview: String {
        draftURL.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "body" })?.value } ?? "Please shorten your answers to fit the GitHub draft."
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("What happened?") {
                    TextField("Problem", text: $problem)
                    TextField("Mission, area and what you were doing", text: $area)
                    TextField("Every time, sometimes, or once?", text: $frequency)
                }
                Section("Review your GitHub draft") {
                    Text(preview).font(.footnote).textSelection(.enabled)
                    Text("GitHub issues are public. Export the report, review it, then attach it on GitHub. Opening the draft does not post an issue or upload files.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section {
                    Button("Export Diagnostic Report…") {
                        document = GoldenPadReportDocument(text: preview + "\n\n" + GoldenPadDiagnostics.report(context: context, support: supportURL))
                        exporting = true
                    }
                    Button("Open GitHub Draft") {
                        guard let url = draftURL else { return }
                        openURL(url) { accepted in openFailed = !accepted }
                    }.disabled(draftURL == nil)
                }
            }
            .navigationTitle("Report a Problem")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
            .fileExporter(isPresented: $exporting, document: document, contentType: .plainText, defaultFilename: "GoldenPad-Diagnostics") { result in
                if case .failure = result { exportFailed = true }
            }
            .alert("Could not save report", isPresented: $exportFailed) { Button("OK", role: .cancel) {} }
            .alert("Could not open GitHub", isPresented: $openFailed) {
                Button("OK", role: .cancel) {}
            } message: { Text("Please try again, or visit github.com/chrissotraidis/goldenpad/issues in your browser.") }
        }
        #if os(macOS)
        .frame(width: 640, height: 650)
        #endif
    }
}

private struct GoldenPadReportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    var text: String
    init(text: String) { self.text = text }
    init(configuration: ReadConfiguration) throws { text = String(decoding: configuration.file.regularFileContents ?? Data(), as: UTF8.self) }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: Data(text.utf8)) }
}
