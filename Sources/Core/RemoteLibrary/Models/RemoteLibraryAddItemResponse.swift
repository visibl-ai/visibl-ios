//
//  RemoteLibraryAddItemResponse.swift
//  visibl
//
//

import Foundation

struct RemoteLibraryAddItemResponse: Codable {
    let id: String
    let uid: String
    let catalogueId: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case uid
        case catalogueId
    }
}
