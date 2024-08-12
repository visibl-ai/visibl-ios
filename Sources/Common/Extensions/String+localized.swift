//
//  String+localized.swift
//  visibl
//
//

import Foundation

extension String {
    public var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}
