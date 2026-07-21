//
//  LGFileSink.swift
//
//
//  Created by Chandan Singh on 2026/07/20.
//

import Foundation

/// Appends individual `LGPrint` lines to a per-launch log file when file logging is enabled.
///
/// `@unchecked Sendable` because every access to mutable state goes through `lock`.
final class LGFileSink: @unchecked Sendable {
    static let shared = LGFileSink()

    private let lock = NSLock()
    private let rootPath: String
    var fileManager: LGFileManagerProtocol = FileManager.default
    var fileHandleFactory = LGFileHandleFactory()
    private var fileHandle: FileHandle?
    private var didFailToOpen = false
    private(set) var currentFilePath: String?

    init(mainBundle: Bundle = Bundle.main) {
        let appSupportPath = NSSearchPathForDirectoriesInDomains(
            .applicationSupportDirectory, .userDomainMask, true
        ).first ?? NSTemporaryDirectory()
        let bundleIdentifier = mainBundle.bundleIdentifier ?? "unknown"
        self.rootPath = "\(appSupportPath)/\(bundleIdentifier)/LGPrint"
    }

    func append(_ line: String) {
        lock.lock()
        defer { lock.unlock() }

        if fileHandle == nil {
            guard !didFailToOpen, openFile() else { return }
        }
        guard let fileHandle, let data = (line + "\n").data(using: .utf8) else { return }

        if #available(macOS 10.15.4, iOS 13.4, watchOS 6.2, tvOS 13.4, *) {
            try? fileHandle.write(contentsOf: data)
        } else {
            fileHandle.write(data)
        }
    }

    /// Opens (creating if needed) this launch's log file. Only attempted once per launch —
    /// a failure is remembered so a broken path doesn't retry file-system work on every line.
    private func openFile() -> Bool {
        let logName = Self.getProcessStartDate().toISO8601String()
        let directoryPath = "\(rootPath)/\(logName)"
        let path = "\(directoryPath)/\(logName).log"

        try? fileManager.createDirectory(
            atPath: directoryPath,
            withIntermediateDirectories: true,
            attributes: nil
        )
        guard fileManager.createFile(atPath: path, contents: nil, attributes: nil),
              let handle = fileHandleFactory.create(forWritingAtPath: path)
        else {
            didFailToOpen = true
            return false
        }

        self.fileHandle = handle
        self.currentFilePath = path
        return true
    }

    /// Every log file written across every launch, for handing off to an uploader.
    func allLogFileURLs() -> [URL] {
        lock.lock()
        defer { lock.unlock() }

        guard let enumerator = FileManager.default.enumerator(
            at: URL(fileURLWithPath: rootPath),
            includingPropertiesForKeys: nil
        ) else {
            return []
        }
        return enumerator.compactMap { $0 as? URL }.filter { $0.pathExtension == "log" }
    }

    /// Deletes the given log files from disk. If the file currently being appended to is
    /// among them, a subsequent `append(_:)` call opens a fresh one.
    func deleteLogFiles(_ urls: [URL]) {
        lock.lock()
        defer { lock.unlock() }

        for url in urls {
            try? FileManager.default.removeItem(at: url)
            if url.path == currentFilePath {
                fileHandle = nil
                currentFilePath = nil
            }
        }
    }

    /// The start time of the current process, used to name each launch's log file.
    private static func getProcessStartDate() -> Date {
        let pid = ProcessInfo.processInfo.processIdentifier
        var mib = [ CTL_KERN, KERN_PROC, KERN_PROC_PID, pid ]
        var proc = kinfo_proc.init()
        var size = MemoryLayout<kinfo_proc>.size

        guard sysctl(&mib, 4, &proc, &size, nil, 0) == 0 else {
            return Date()
        }

        return Date.init(
            timeIntervalSince1970: TimeInterval(proc.kp_proc.p_starttime.tv_sec)
        )
    }
}
