//
//  DIContainer.swift
//  visibl
//
//

import Foundation
import ReadiumShared
import ReadiumNavigator

final class DIContainer {
    // TODO: Remove this singleton, pass throgoth dependency injection
    var authService = AuthService.shared

    var libraryService: LibraryService!
    
    let httpClient = DefaultHTTPClient()
    let db: Database
    
    lazy var books: BookRepository = BookRepository(db: self.db)
    lazy var bookmarks: BookmarkRepository = BookmarkRepository(db: self.db)
    
    let collectionsManager = CollectionsManager()
    let aaxManager = AAXManager()
    
    init() {
        do {
            db = try Database(file: Paths.library.appendingPathComponent("database.db"))
        } catch {
            fatalError("Failed to initialize the database: \(error.localizedDescription)")
        }
        
        libraryService = LibraryService(books: books, httpClient: httpClient)
    }
    
    func makePreferencesStore() -> AnyUserPreferencesStore<AudioPreferences> {
        CompositeUserPreferencesStore(
            publicationStore: DatabaseUserPreferencesStore(books: books),
            sharedStore: UserDefaultsUserPreferencesStore(),
            publicationFilter: { $0.filterPublicationPreferences() },
            sharedFilter: { $0.filterSharedPreferences() }
        ).eraseToAnyPreferencesStore()
    }
}
