//
//  LGSettingsTests.swift
//
//  Covers the routing logic in `LGSettings.destinations(forModule:level:)` — the single
//  decision point that governs whether an `LGPrint` line reaches the console and/or the file.
//
//  `LGSettings` is process-global, so `setUp` normalises it back to defaults before each test.
//

import XCTest
@testable import LGLogger

final class LGSettingsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        LGSettings.setLogLevelAll()
        LGSettings.showAllLevelsInConsole()
        LGSettings.enableFileLogging(levels: LGLevel.allCases)
        LGSettings.disableFileLogging()
        LGSettings.outputMethod = .print
        LGSettings.uploadURL = nil
    }

    // MARK: - Defaults

    func testDefaultsPrintToConsoleButNotFile() {
        let dest = LGSettings.destinations(forModule: nil, level: .debug)
        XCTAssertTrue(dest.printToConsole)
        XCTAssertFalse(dest.writeToFile, "file logging is off until explicitly enabled")
        XCTAssertEqual(dest.outputMethod, .print)
    }

    // MARK: - Module filter

    func testModuleFilterRestrictsBothDestinations() {
        LGSettings.setLogLevel(onlyModules: ["Auth"])
        LGSettings.enableFileLogging()

        let auth = LGSettings.destinations(forModule: "Auth", level: .info)
        XCTAssertTrue(auth.printToConsole)
        XCTAssertTrue(auth.writeToFile)

        let other = LGSettings.destinations(forModule: "Payments", level: .info)
        XCTAssertFalse(other.printToConsole)
        XCTAssertFalse(other.writeToFile)
    }

    func testUntaggedLineSuppressedWhenModuleFilterActive() {
        LGSettings.setLogLevel(onlyModules: ["Auth"])
        let dest = LGSettings.destinations(forModule: nil, level: .info)
        XCTAssertFalse(dest.printToConsole)
        XCTAssertFalse(dest.writeToFile)
    }

    func testSetLogLevelAllRestoresEveryModule() {
        LGSettings.setLogLevel(onlyModules: ["Auth"])
        LGSettings.setLogLevelAll()
        XCTAssertTrue(LGSettings.destinations(forModule: "Anything", level: .info).printToConsole)
        XCTAssertTrue(LGSettings.destinations(forModule: nil, level: .info).printToConsole)
    }

    // MARK: - Console level filter

    func testConsoleLevelFilterIsIndependentOfFile() {
        LGSettings.showConsole(onlyLevels: [.error])
        XCTAssertFalse(LGSettings.destinations(forModule: nil, level: .debug).printToConsole)
        XCTAssertTrue(LGSettings.destinations(forModule: nil, level: .error).printToConsole)
    }

    // MARK: - File level filter

    func testEnableFileLoggingRestrictsFileLevelsOnly() {
        LGSettings.enableFileLogging(levels: [.error])

        let error = LGSettings.destinations(forModule: nil, level: .error)
        XCTAssertTrue(error.writeToFile)

        let debug = LGSettings.destinations(forModule: nil, level: .debug)
        XCTAssertFalse(debug.writeToFile, "debug is not an allowed file level")
        XCTAssertTrue(debug.printToConsole, "console is unaffected by the file level filter")
    }

    func testDisableFileLoggingStopsFileWrites() {
        LGSettings.enableFileLogging()
        LGSettings.disableFileLogging()
        XCTAssertFalse(LGSettings.destinations(forModule: nil, level: .error).writeToFile)
    }

    // MARK: - Output method

    func testOutputMethodIsReflectedInSnapshot() {
        LGSettings.outputMethod = .nslog
        XCTAssertEqual(LGSettings.destinations(forModule: nil, level: .info).outputMethod, .nslog)
    }

    // MARK: - Upload URL

    func testUploadURLRoundTrips() {
        XCTAssertNil(LGSettings.uploadURL)
        let url = URL(string: "https://example.com/logs")!
        LGSettings.uploadURL = url
        XCTAssertEqual(LGSettings.uploadURL, url)
    }
}
