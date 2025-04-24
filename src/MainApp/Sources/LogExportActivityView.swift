import SwiftUI
import UniformTypeIdentifiers

public struct LogExportActivityView: UIViewControllerRepresentable {
    public let data: Data
    public let fileName: String

    public init(data: Data, fileName: String) {
        self.data = data
        self.fileName = fileName
    }

    public func makeUIViewController(context _: Context) -> UIActivityViewController {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? data.write(to: tempURL, options: .atomic)
        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        return activityVC
    }

    public func updateUIViewController(_ _: UIActivityViewController, context _: Context) {}
}
