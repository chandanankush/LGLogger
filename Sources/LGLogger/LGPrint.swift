//
//  LGPrint.swift
//
//
//  Created by Chandan Singh on 2026/07/20.
//

import Foundation

/// Prints `message` to Xcode's debug area — used exactly like `print()` — subject to
/// `LGSettings`'s module filter, and (if file logging is enabled) also writes it to the
/// active log file when `level` is one of the allowed file-logging levels.
///
/// `message` is only evaluated if at least one of those two destinations is actually active,
/// so an expensive message expression costs nothing when logging for it is turned off.
public func LGPrint(
    _ message: @autoclosure () -> Any,
    level: LGLevel = .debug
) {
    LGLog.emit(module: nil, level: level, message: message)
}

/// Same as `LGPrint(_:level:)`, tagged with `module` so a module developer can call
/// `LGSettings.setLogLevel(onlyModules: ["Auth"])` and only see (and save) their own module's
/// lines.
public func LGPrint(
    _ module: String,
    _ message: @autoclosure () -> Any,
    level: LGLevel = .debug
) {
    LGLog.emit(module: module, level: level, message: message)
}

enum LGLog {
    static func emit(module: String?, level: LGLevel, message: () -> Any) {
        #if !DEBUG
        if level == .debug { return }
        #endif

        let destinations = LGSettings.destinations(forModule: module, level: level)
        guard destinations.printToConsole || destinations.writeToFile else { return }

        let modulePrefix = module.map { "[\($0)] " } ?? ""
        let line = "\(level.prefix) \(modulePrefix)\(message())"

        if destinations.printToConsole {
            switch destinations.outputMethod {
            case .print:
                print(line)
            case .nslog:
                NSLog("%@", line)
            }
        }
        if destinations.writeToFile {
            LGFileSink.shared.append(line)
        }
    }
}
