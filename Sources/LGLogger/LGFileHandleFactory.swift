//
//  LGFileHandleFactory.swift
//
//
//  Created by Chandan Singh on 2026/06/20.
//

import Foundation

class LGFileHandleFactory {
    func create(forWritingAtPath path: String) -> FileHandle? {
        FileHandle.init(forWritingAtPath: path)
    }
}
