//
//  LGUploadErrorTests.swift
//

import XCTest
@testable import LGLogger

final class LGUploadErrorTests: XCTestCase {

    func testDescriptionsAreHumanReadable() {
        XCTAssertEqual(LGUploadError.noLogFiles.description, "there are no log files to send")
        XCTAssertEqual(LGUploadError.mailUnavailable.description, "this device isn't configured to send mail")
        XCTAssertEqual(LGUploadError.mailCancelled.description, "mail composition was cancelled")
        XCTAssertEqual(LGUploadError.invalidResponse.description, "the server returned an unexpected response")
    }

    func testDescriptionsInterpolateReason() {
        XCTAssertEqual(
            LGUploadError.mailFailed(reason: "smtp down").description,
            "sending mail failed: smtp down"
        )
        XCTAssertEqual(
            LGUploadError.uploadFailed(reason: "timeout").description,
            "upload failed: timeout"
        )
    }
}
