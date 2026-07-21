//
//  LGUploadError.swift
//
//
//  Created by Chandan Singh on 2026/07/20.
//

import Foundation

/// A failure encountered while sending or uploading log files.
public enum LGUploadError: Error, CustomStringConvertible, Sendable {
    case noLogFiles
    case mailUnavailable
    case mailCancelled
    case mailFailed(reason: String)
    case uploadFailed(reason: String)
    case invalidResponse

    public var description: String {
        switch self {
        case .noLogFiles:
            return "there are no log files to send"
        case .mailUnavailable:
            return "this device isn't configured to send mail"
        case .mailCancelled:
            return "mail composition was cancelled"
        case .mailFailed(let reason):
            return "sending mail failed: \(reason)"
        case .uploadFailed(let reason):
            return "upload failed: \(reason)"
        case .invalidResponse:
            return "the server returned an unexpected response"
        }
    }
}
