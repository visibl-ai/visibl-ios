//
//  LibraryManager.swift
//  visibl
//
//

import Foundation
import ReadiumShared

struct CatalogueGetResponse: Codable {
    var id: String
    var title: String
}

class LibraryManager {
    static let shared = LibraryManager()
    
    func getSceneJSON(libraryId: String) {
        Task {
            let result: [ArkworkSceneModel] = try await CloudFunctionService.shared.makeAuthenticatedCall(
                functionName: "v1getAi",
                with: ["libraryId": libraryId]
            )
            print(result)
        }
    }
    
    func listCatalogueItems() {
        Task {
            let result: [SimpleCatalogueItemModel] = try await CloudFunctionService.shared.makeAuthenticatedCall(
                functionName: "v1catalogueGet"
            )
            print("Catalogue items: \(result)")
        }
    }
    
    func addItemToUserLibrary(catalogueId: String) {
        Task {
            let result: RemoteLibraryAddItemResponse = try await CloudFunctionService.shared.makeAuthenticatedCall(
                functionName: "v1addItemToLibrary",
                with: ["catalogueId": catalogueId]
            )
            print(result)
        }
    }
    
    // async
    
    func addItemToUserLibrary(catalogueId: String) async throws -> String {
        let result: RemoteLibraryAddItemResponse = try await CloudFunctionService.shared.makeAuthenticatedCall(
            functionName: "v1addItemToLibrary",
            with: ["catalogueId": catalogueId]
        )
        return result.id
    }
    
    func getUserLibrary(includeManifest: Bool) {
        Task {
            let result: [UserAudiobook] = try await CloudFunctionService.shared.makeAuthenticatedCall(
                functionName: "v1getLibrary",
                with: ["includeManifest": includeManifest]
            )
            print("User Library items: \(result)")
        }
    }
    
    func deleteBooks(bookIDs: [String]) {
        Task {
            let result: [DeletionResult] = try await CloudFunctionService.shared.makeAuthenticatedCall(
                functionName: "v1deleteItemsFromLibrary",
                with: ["libraryIds": bookIDs]
            )
            print(result)
        }
    }
}

extension Metadata {
    public var visiblId: String? {
        get {
            otherMetadata["visiblId"] as? String
        }
        set {
            var updatedMetadata = otherMetadata
            updatedMetadata["visiblId"] = newValue
            otherMetadata = updatedMetadata
        }
    }
}
