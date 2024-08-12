//
//  UserAudiobook.swift
//  visibl
//
//

import Foundation

struct UserAudiobook: Codable {
    let addedAt: Timestamp
    let id: String
    let manifest: Manifest?
    let uid: String
    let catalogueId: String
    
    struct Timestamp: Codable {
        let nanoseconds: Int
        let seconds: Int
        
        enum CodingKeys: String, CodingKey {
            case nanoseconds = "_nanoseconds"
            case seconds = "_seconds"
        }
    }
    
    struct Manifest: Codable {
        let metadata: Metadata
        let links: [Link]
        let context: String
        let readingOrder: [ReadingOrder]
        
        enum CodingKeys: String, CodingKey {
            case metadata, links, readingOrder
            case context = "@context"
        }
    }
    
    struct Metadata: Codable {
        let duration: Double
        let author: Author
        let title: String
        let language: String
        let type: String
        let published: String
        
        enum CodingKeys: String, CodingKey {
            case duration, author, title, language, published
            case type = "@type"
        }
    }
    
    struct Author: Codable {
        let name: String
        let sortAs: String
    }
    
    struct Link: Codable {
        let rel: String
        let href: String
        let type: String
    }
    
    struct ReadingOrder: Codable {
        let bitrate: Int
        let title: String
        let href: String
        let type: String
        let duration: Double
    }
}
