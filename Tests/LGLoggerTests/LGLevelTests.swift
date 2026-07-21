//
//  LGLevelTests.swift
//

import XCTest
@testable import LGLogger

final class LGLevelTests: XCTestCase {

    func testAllCasesInSeverityOrder() {
        XCTAssertEqual(LGLevel.allCases, [.debug, .info, .warning, .error])
    }

    func testRawValuesAreDistinctBitmask() {
        XCTAssertEqual(LGLevel.debug.rawValue, 0x01)
        XCTAssertEqual(LGLevel.info.rawValue, 0x02)
        XCTAssertEqual(LGLevel.warning.rawValue, 0x04)
        XCTAssertEqual(LGLevel.error.rawValue, 0x08)
    }

    func testPrefixPerLevel() {
        XCTAssertEqual(LGLevel.debug.prefix, "🔍")
        XCTAssertEqual(LGLevel.info.prefix, "💬")
        XCTAssertEqual(LGLevel.warning.prefix, "⚠️")
        XCTAssertEqual(LGLevel.error.prefix, "❌")
    }

    func testPrefixesAreUnique() {
        let prefixes = LGLevel.allCases.map(\.prefix)
        XCTAssertEqual(Set(prefixes).count, prefixes.count)
    }
}
