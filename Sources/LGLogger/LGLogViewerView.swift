//
//  LGLogViewerView.swift
//
//
//  Created by Chandan Singh on 2026/07/20.
//

import SwiftUI

/// Lists every log file `LGFileSink` has written and shows its contents on selection.
/// This is what the floating bubble opens.
struct LGLogViewerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var files: [URL] = []
    @State private var selectedFile: URL?
    @State private var content = ""

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
                    }
                }
            }
            .onAppear {
                files = LGFileSink.shared.allLogFileURLs().sorted { $0.lastPathComponent > $1.lastPathComponent }
            }
        }
    }
}
