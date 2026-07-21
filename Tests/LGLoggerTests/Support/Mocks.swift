//
//  Mocks.swift
//
//  Test doubles shared across the LGLogger test suite.
//

import Foundation
@testable import LGLogger

/// A `LGFileManagerProtocol` that records every call and, by default, forwards to a real
/// `FileManager` so `LGFileSink` can genuinely open and write to a file on disk. Set
/// `createFileResult = false` to simulate a directory/file the sink can't create.
final class MockFileManager: LGFileManagerProtocol {
    var createFileResult = true
    private(set) var createdDirectories: [String] = []
    private(set) var createdFilePaths: [String] = []

    private let backing = FileManager.default

    func createDirectory(
        atPath path: String,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey: Any]?
    ) throws {
        createdDirectories.append(path)
        try backing.createDirectory(
            atPath: path,
            withIntermediateDirectories: createIntermediates,
            attributes: attributes
        )
    }

    func createFile(
        atPath path: String,
        contents data: Data?,
        attributes attr: [FileAttributeKey: Any]?
    ) -> Bool {
        createdFilePaths.append(path)
        guard createFileResult else { return false }
        return backing.createFile(atPath: path, contents: data, attributes: attr)
    }

    /// Removes anything this mock created from disk, so a test leaves no residue.
    func cleanUp() {
        for directory in createdDirectories {
            try? backing.removeItem(atPath: directory)
        }
    }
}
