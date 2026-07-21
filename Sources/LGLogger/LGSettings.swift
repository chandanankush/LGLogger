//
//  LGSettings.swift
//
//
//  Created by Chandan Singh on 2026/07/20.
//

import Foundation

/// Central, thread-safe configuration for `LGPrint`.
///
/// - `setLogLevel(onlyModules:)` sets a single module filter shared by both console and file —
///   a module developer debugging just their own module calls `setLogLevel(onlyModules: ["Auth"])`
///   and only that module's lines print *and* get saved. `setLogLevelAll()` resets it back to
///   the default: every module is shown and saved. This only governs *which modules* — it has
///   no effect on whether file saving is on at all; that's `enableFileLogging()`, separately.
/// - Severity filtering stays independent per destination: `showConsole(onlyLevels:)` for the
///   console, `enableFileLogging(levels:)` for the file.
///
/// Note `.debug` is already compiled out of release builds entirely (see `LGLog`), so
/// restricting console/file output to `.debug` only ever shows anything in DEBUG builds.
public enum LGSettings {

    /// How a console line is emitted.
    public enum OutputMethod: Sendable {
        /// Writes via `print()`.
        case print

        /// Writes via `NSLog()`.
        case nslog
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var allowedModules: Set<String>?
    nonisolated(unsafe) private static var allowedConsoleLevels: Set<LGLevel> = Set(LGLevel.allCases)
    nonisolated(unsafe) private static var isFileLoggingEnabled = false
    nonisolated(unsafe) private static var allowedFileLevels: Set<LGLevel> = Set(LGLevel.allCases)
    nonisolated(unsafe) private static var storedOutputMethod: OutputMethod = .print

    /// Restricts both console and file output to `modules`. A log with no module tag, or a
    /// module not in this list, is suppressed from both destinations.
    public static func setLogLevel(onlyModules modules: [String]) {
        lock.withLock { allowedModules = Set(modules) }
    }

    /// Resets the module filter to the default: every module is shown and saved.
    public static func setLogLevelAll() {
        lock.withLock { allowedModules = nil }
    }

    /// Restricts console output to `levels`. Combines with the module filter — a line must
    /// pass both to print.
    public static func showConsole(onlyLevels levels: [LGLevel]) {
        lock.withLock { allowedConsoleLevels = Set(levels) }
    }

    /// Resets the console's level filter to the default: every level is shown.
    public static func showAllLevelsInConsole() {
        lock.withLock { allowedConsoleLevels = Set(LGLevel.allCases) }
    }

    /// Turns on file logging; only `levels` are written to disk. Defaults to every level.
    public static func enableFileLogging(levels: [LGLevel] = LGLevel.allCases) {
        lock.withLock {
            isFileLoggingEnabled = true
            allowedFileLevels = Set(levels)
        }
    }

    /// Turns file logging off (the default state).
    public static func disableFileLogging() {
        lock.withLock { isFileLoggingEnabled = false }
    }

    public static var outputMethod: OutputMethod {
        get { lock.withLock { storedOutputMethod } }
        set { lock.withLock { storedOutputMethod = newValue } }
    }

    /// Single-lock snapshot of where a call should go — read once per `LGPrint` call so it
    /// never takes the lock more than once.
    static func destinations(
        forModule module: String?,
        level: LGLevel
    ) -> (printToConsole: Bool, outputMethod: OutputMethod, writeToFile: Bool) {
        lock.withLock {
            let moduleAllowed: Bool
            if let allowedModules {
                moduleAllowed = module.map(allowedModules.contains) ?? false
            } else {
                moduleAllowed = true
            }

            let printToConsole = moduleAllowed && allowedConsoleLevels.contains(level)
            let writeToFile = moduleAllowed && isFileLoggingEnabled && allowedFileLevels.contains(level)
            return (printToConsole, storedOutputMethod, writeToFile)
        }
    }
}
