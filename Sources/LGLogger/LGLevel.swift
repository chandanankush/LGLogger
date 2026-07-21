//
//  LGLevel.swift
//
//
//  Created by Chandan Singh on 2026/07/20.
//

import Foundation

/// Severity of an `LGPrint` line. LG = Logger.
public enum LGLevel: UInt8, CaseIterable, Hashable, Sendable {

    case debug = 0x01
    case info = 0x02
    case warning = 0x04
    case error = 0x08

    var prefix: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "💬"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
}
