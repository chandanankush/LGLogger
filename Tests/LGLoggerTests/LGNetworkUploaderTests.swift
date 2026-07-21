//
//  LGNetworkUploaderTests.swift
//
//  `LGNetworkUploader.upload` reads its files from the `LGFileSink.shared` singleton, so the
//  cleanly-testable behaviour of the public API is the empty-set guard. (Exercising the POST
//  path end-to-end would require decoupling the uploader from the shared sink — out of scope
//  for this suite.)
//

import XCTest
@testable import LGLogger

final class LGNetworkUploaderTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Start from a known-empty sink so the guard is deterministic.
        LGFileSink.shared.deleteLogFiles(LGFileSink.shared.allLogFileURLs())
    }

    func testUploadWithNoFilesReportsNoLogFiles() {
        let expectation = expectation(description: "completion called")
        var received: Result<Void, LGUploadError>?

        LGNetworkUploader.upload(to: URL(string: "https://example.com/logs")!) { result in
            received = result
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)

        guard case .failure(.noLogFiles) = received else {
            return XCTFail("expected .noLogFiles, got \(String(describing: received))")
        }
    }
}
