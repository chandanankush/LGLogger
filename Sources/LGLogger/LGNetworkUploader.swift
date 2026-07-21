//
//  LGNetworkUploader.swift
//
//
//  Created by Chandan Singh on 2026/07/20.
//

import Foundation

/// Uploads every collected log file to a URL via HTTP POST, deleting each file individually
/// once its own upload succeeds — a failure on one file never blocks or deletes the others.
public enum LGNetworkUploader {

    public static func upload(
        to url: URL,
        session: URLSession = .shared,
        completion: @escaping (Result<Void, LGUploadError>) -> Void
    ) {
        let logFiles = LGFileSink.shared.allLogFileURLs()
        guard !logFiles.isEmpty else {
            completion(.failure(.noLogFiles))
            return
        }

        let firstFailure = LGFailureBox()
        let group = DispatchGroup()

        for fileURL in logFiles {
            group.enter()
            uploadFile(at: fileURL, to: url, session: session) { result in
                switch result {
                case .success:
                    LGFileSink.shared.deleteLogFiles([fileURL])
                case .failure(let error):
                    firstFailure.recordFirst(error)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(firstFailure.value.map(Result.failure) ?? .success(()))
        }
    }

    private static func uploadFile(
        at fileURL: URL,
        to url: URL,
        session: URLSession,
        completion: @escaping (Result<Void, LGUploadError>) -> Void
    ) {
        guard let data = try? Data(contentsOf: fileURL) else {
            completion(.failure(.uploadFailed(reason: "could not read \(fileURL.lastPathComponent)")))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.setValue(fileURL.lastPathComponent, forHTTPHeaderField: "X-Log-File-Name")

        session.uploadTask(with: request, from: data) { _, response, error in
            if let error {
                completion(.failure(.uploadFailed(reason: error.localizedDescription)))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode)
            else {
                completion(.failure(.invalidResponse))
                return
            }
            completion(.success(()))
        }.resume()
    }
}

/// Thread-safe holder for the first failure across concurrent per-file uploads.
private final class LGFailureBox: @unchecked Sendable {
    private let lock = NSLock()
    private var storedValue: LGUploadError?

    func recordFirst(_ error: LGUploadError) {
        lock.withLock { if storedValue == nil { storedValue = error } }
    }

    var value: LGUploadError? { lock.withLock { storedValue } }
}
