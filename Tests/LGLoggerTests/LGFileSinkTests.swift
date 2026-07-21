//
//  LGFileSinkTests.swift
//
//  Covers the on-disk append path through the injectable `LGFileManagerProtocol` seam:
//  the sink opens the launch file lazily, appends newline-terminated lines, and gives up
//  permanently (rather than retrying every line) once it fails to open a file.
//

import XCTest
@testable import LGLogger

final class LGFileSinkTests: XCTestCase {

    private var mock: MockFileManager!
    private var sink: LGFileSink!

    override func setUp() {
        super.setUp()
        mock = MockFileManager()
        sink = LGFileSink()
        sink.fileManager = mock
    }

    override func tearDown() {
        mock.cleanUp()
        mock = nil
        sink = nil
        super.tearDown()
    }

    func testAppendWritesNewlineTerminatedLinesToDisk() throws {
        sink.append("hello")
        sink.append("world")

        let path = try XCTUnwrap(sink.currentFilePath)
        let contents = try String(contentsOfFile: path, encoding: .utf8)
        XCTAssertEqual(contents, "hello\nworld\n")
    }

    func testOpenCreatesDirectoryWithIntermediates() {
        sink.append("x")
        XCTAssertEqual(mock.createdDirectories.count, 1)
        XCTAssertEqual(mock.createdFilePaths.count, 1)
    }

    func testFailedOpenIsNotRetriedOnEveryLine() {
        mock.createFileResult = false

        sink.append("first")
        sink.append("second")

        XCTAssertNil(sink.currentFilePath)
        XCTAssertEqual(mock.createdFilePaths.count, 1, "a failed open must not be retried per line")
    }
}
