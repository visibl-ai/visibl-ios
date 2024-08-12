//
//  CatalogueItemModel.swift
//  visibl
//
//

import Foundation

struct SimpleCatalogueItemModel: Codable {
    let id: String
    let title: String
}

struct CatalogueItemModel: Codable {
    let author: [String]
    let id: String
    let title: String
    let language: String
    let duration: Double
    let createdAt: Timestamp
    let metadata: Metadata
    let type: String
    let updatedAt: Timestamp
    
    struct Metadata: Codable {
        let author: String
        let length: Double
        let title: String
        let codec: String
        let chapters: [String: Chapter]
        let year: String
        let bitrateKbs: Int
        
        enum CodingKeys: String, CodingKey {
            case author, length, title, codec, chapters, year
            case bitrateKbs = "bitrate_kbs"
        }
    }
    
    struct Chapter: Codable {
        let endTime: Double
        let startTime: Double
    }
    
    struct Timestamp: Codable {
        let nanoseconds: Int
        let seconds: Int
        
        enum CodingKeys: String, CodingKey {
            case nanoseconds = "_nanoseconds"
            case seconds = "_seconds"
        }
    }
}
