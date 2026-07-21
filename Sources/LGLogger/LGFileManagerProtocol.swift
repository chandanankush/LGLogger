//
//  LGFileManagerProtocol.swift
//
//
//  Created by Chandan Singh on 2026/06/20.
//

import Foundation

// swiftlint:disable discouraged_optional_collection
protocol LGFileManagerProtocol {
    func createDirectory(
        atPath path: String,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey: Any]?
    ) throws

    func createFile(
        atPath path: String,
        contents data: Data?,
        attributes attr: [FileAttributeKey: Any]?
    ) -> Bool
}

extension FileManager: LGFileManagerProtocol {}
