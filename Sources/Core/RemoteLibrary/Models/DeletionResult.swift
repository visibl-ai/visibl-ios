//
//  DeletionResponseModel.swift
//  visibl
//
//

import Foundation

struct DeletionResult: Codable {
    let message: String
    let results: Results
    
    struct Results: Codable {
        let success: [String]
        let failed: [String]
    }
}
