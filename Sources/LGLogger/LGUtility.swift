//
//  LGUtility.swift
//
//
//  Created by Chandan Singh on 2026/06/20.
//

import Foundation

extension Date {
    func toISO8601String() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HHmmssZ"
        return dateFormatter.string(from: self)
    }
}
