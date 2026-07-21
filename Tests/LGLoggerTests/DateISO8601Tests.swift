//
//  DateISO8601Tests.swift
//
//  Covers `Date.toISO8601String()`, used to name each launch's log file/folder.
//

import XCTest
@testable import LGLogger

final class DateISO8601Tests: XCTestCase {

    /// `yyyy-MM-dd'T'HHmmssZ` — date, `T`, a 6-digit time, then a numeric zone offset.
    func testMatchesExpectedFormat() throws {
        let formatted = Date(timeIntervalSince1970: 0).toISO8601String()
        let pattern = #"^\d{4}-\d{2}-\d{2}T\d{6}([+-]\d{4}|Z)$"#
        XCTAssertNotNil(
            formatted.range(of: pattern, options: .regularExpression),
            "\(formatted) did not match \(pattern)"
        )
    }

    /// The filename is used on disk, so it must never contain a path separator.
    func testContainsNoPathSeparator() {
        XCTAssertFalse(Date().toISO8601String().contains("/"))
    }

    /// POSIX locale keeps the output ASCII regardless of the device's locale.
    func testUsesAsciiDigits() {
        let formatted = Date(timeIntervalSince1970: 1_000_000).toISO8601String()
        XCTAssertTrue(formatted.allSatisfy { $0.isASCII })
    }
}
