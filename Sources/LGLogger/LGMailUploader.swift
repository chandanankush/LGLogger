//
//  LGMailUploader.swift
//
//
//  Created by Chandan Singh on 2026/07/20.
//

import Foundation
import MessageUI
import UIKit

/// Sends every collected log file as a mail attachment via the system mail composer.
@MainActor
public enum LGMailUploader {

    private static var activeDelegates: [ObjectIdentifier: LGMailComposeDelegate] = [:]

    /// Presents the mail composer from `presenter`, attaching every log file currently on
    /// disk. On successful send, the attached files are deleted; on cancel or failure they
    /// are left in place so nothing is lost.
    public static func present(
        from presenter: UIViewController,
        subject: String = "App Logs",
        recipients: [String] = [],
        completion: @escaping (Result<Void, LGUploadError>) -> Void
    ) {
        guard MFMailComposeViewController.canSendMail() else {
            completion(.failure(.mailUnavailable))
            return
        }

        let logFiles = LGFileSink.shared.allLogFileURLs()
        guard !logFiles.isEmpty else {
            completion(.failure(.noLogFiles))
            return
        }

        let composer = MFMailComposeViewController()
        let key = ObjectIdentifier(composer)
        let delegate = LGMailComposeDelegate(logFiles: logFiles) { result in
            activeDelegates.removeValue(forKey: key)
            completion(result)
        }
        activeDelegates[key] = delegate

        composer.mailComposeDelegate = delegate
        composer.setSubject(subject)
        composer.setToRecipients(recipients)
        for url in logFiles {
            if let data = try? Data(contentsOf: url) {
                composer.addAttachmentData(data, mimeType: "text/plain", fileName: url.lastPathComponent)
            }
        }

        presenter.present(composer, animated: true)
    }
}

/// Kept alive by `LGMailUploader.activeDelegates` for the composer's lifetime.
private final class LGMailComposeDelegate: NSObject, MFMailComposeViewControllerDelegate {
    private let logFiles: [URL]
    private let completion: (Result<Void, LGUploadError>) -> Void

    init(logFiles: [URL], completion: @escaping (Result<Void, LGUploadError>) -> Void) {
        self.logFiles = logFiles
        self.completion = completion
    }

    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        controller.dismiss(animated: true) {
            switch result {
            case .sent:
                LGFileSink.shared.deleteLogFiles(self.logFiles)
                self.completion(.success(()))
            case .cancelled, .saved:
                self.completion(.failure(.mailCancelled))
            case .failed:
                self.completion(.failure(.mailFailed(reason: error.map(String.init(describing:)) ?? "unknown")))
            @unknown default:
                self.completion(.failure(.mailFailed(reason: "unknown result")))
            }
        }
    }
}
