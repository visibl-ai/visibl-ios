//
//  CollectionsManager.swift
//  visibl
//
//

import Foundation
import ReadiumShared

struct CollectionModel: Identifiable, Hashable {
    let id: Int
    var title: String
    var booksIDs: [Book.Id]
    let isDefault: Bool
}

class CollectionsManager: ObservableObject {
    @Published var collections: [CollectionModel] = [
        CollectionModel(id: 1, title: "Favorites", booksIDs: [], isDefault: true),
        CollectionModel(id: 2, title: "Hidden", booksIDs: [], isDefault: true),
    ]
    
    @Published var selectedCollection: CollectionModel?
}

// MARK: - Single Collection Management

extension CollectionsManager {
    func addBook(_ book: Book, to collection: CollectionModel) {
        guard let index = collections.firstIndex(where: { $0.id == collection.id }) else {
            return
        }
        
        if let bookId = book.id, !collections[index].booksIDs.contains(bookId) {
            collections[index].booksIDs.append(bookId)
        }
    }
    
    func addToFavorites(_ book: Book) {
        guard let collection = collections.first(where: { $0.id == 1 }) else {
            return
        }
        
        addBook(book, to: collection)
        print("Number of books in favorites: \(collections[0].booksIDs.count)")
    }
    
    func addToHidden(_ book: Book) {
        guard let collection = collections.first(where: { $0.id == 2 }) else {
            return
        }
        
        addBook(book, to: collection)
    }
}

// MARK: - Collections CRUD

extension CollectionsManager {
    func addCollection(_ collection: CollectionModel) {
        guard !collections.contains(where: { $0.id == collection.id }) else {
            return // Avoid duplicate IDs
        }
        collections.append(collection)
    }
    
    func removeCollection(_ collection: CollectionModel) {
        collections.removeAll { $0.id == collection.id }
    }
}
