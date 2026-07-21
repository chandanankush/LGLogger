//
//  LGLogViewerView.swift
//
//
//  Created by Chandan Singh on 2026/07/20.
//

import SwiftUI
import UIKit

/// Lists every log file `LGFileSink` has written and shows its contents on selection.
/// This is what the floating bubble opens.
struct LGLogViewerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var files: [URL] = []
    @State private var selectedFile: URL?
    @State private var content = ""
    @State private var presentingViewController: UIViewController?
    @State private var isShowingClearConfirmation = false
    @State private var statusMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if let selectedFile {
                    ScrollView {
                        Text(content)
                            .font(.system(.footnote, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .navigationTitle(selectedFile.lastPathComponent)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Back") { self.selectedFile = nil }
                        }
                    }
                } else if files.isEmpty {
                    ContentUnavailableView(
                        "No Log Files",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Nothing has been saved yet. Call LGSettings.enableFileLogging() to start saving.")
                    )
                    .navigationTitle("Logs")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { dismiss() }
                        }
                    }
                } else {
                    List(files, id: \.self) { file in
                        Button {
                            selectedFile = file
                            content = (try? String(contentsOf: file, encoding: .utf8)) ?? "Could not read file."
                        } label: {
                            VStack(alignment: .leading) {
                                Text(file.deletingLastPathComponent().lastPathComponent)
                                    .font(.headline)
                                Text(file.lastPathComponent)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .navigationTitle("Logs")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { dismiss() }
                        }
                        ToolbarItem(placement: .primaryAction) {
                            Menu {
                                Button("Email Logs") { emailLogs() }
                                if LGSettings.uploadURL != nil {
                                    Button("Upload Logs") { uploadLogs() }
                                }
                                Button("Clear Logs", role: .destructive) {
                                    isShowingClearConfirmation = true
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        }
                    }
                }
            }
            .background(LGViewControllerResolver { presentingViewController = $0 })
            .onAppear { refreshFiles() }
            .confirmationDialog(
                "Delete all saved log files? This can't be undone.",
                isPresented: $isShowingClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear Logs", role: .destructive) { clearLogs() }
            }
            .alert(
                "Logs",
                isPresented: Binding(get: { statusMessage != nil }, set: { if !$0 { statusMessage = nil } })
            ) {
                Button("OK") { statusMessage = nil }
            } message: {
                Text(statusMessage ?? "")
            }
        }
    }

    private func refreshFiles() {
        files = LGFileSink.shared.allLogFileURLs().sorted { $0.lastPathComponent > $1.lastPathComponent }
    }

    private func emailLogs() {
        guard let presentingViewController else { return }
        LGMailUploader.present(from: presentingViewController) { result in
            switch result {
            case .success:
                statusMessage = "Log files emailed and deleted."
            case .failure(let error):
                statusMessage = "Email failed: \(error)"
            }
            refreshFiles()
        }
    }

    private func uploadLogs() {
        guard let url = LGSettings.uploadURL else { return }
        LGNetworkUploader.upload(to: url) { result in
            switch result {
            case .success:
                statusMessage = "Log files uploaded and deleted."
            case .failure(let error):
                statusMessage = "Upload failed: \(error)"
            }
            refreshFiles()
        }
    }

    private func clearLogs() {
        LGFileSink.shared.deleteLogFiles(files)
        refreshFiles()
    }
}

/// Resolves the `UIViewController` actually hosting this SwiftUI view, so `LGMailUploader`
/// (which needs a real presenter) can present correctly from wherever this view ends up —
/// e.g. inside `LGOverlayWindow`'s own hosting controller, not necessarily the app's main window.
private struct LGViewControllerResolver: UIViewControllerRepresentable {
    let onResolve: (UIViewController) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            if let parent = uiViewController.parent {
                onResolve(parent)
            }
        }
    }
}
