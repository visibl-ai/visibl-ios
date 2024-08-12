//
//  LibraryViewModel.swift
//  visibl
//
//

import Foundation
import Combine
import SwiftUI

enum LibrarySortOption: String, CaseIterable {
    case recent
    case title
    case author
}

enum LibraryViewMode: String, CaseIterable {
    case list
    case grid
}

class UserConfigurations {
    static let shared = UserConfigurations()
    
    @AppStorage("librarySorting") var librarySorting: LibrarySortOption = .recent
    @AppStorage("libraryViewMode") var libraryViewMode: LibraryViewMode = .grid
}

class LibraryViewModel: ObservableObject {
    private let library: LibraryService
    var coordinator: LibraryCoordinator
    
    @Published var books: [Book] = []
    @Published var selectedBooks: [Book] = []
    @Published var selectedBook: Book?
    
    @Published var sortOption: LibrarySortOption {
        didSet {
            UserConfigurations.shared.librarySorting = sortOption
            sortBooks()
        }
    }
    
    @Published var viewModeOption: LibraryViewMode {
        didSet {
            UserConfigurations.shared.libraryViewMode = viewModeOption
        }
    }
    
    @Published var isEditing = false {
        didSet {
            selectedBooks.removeAll()
        }
    }
    
    let eventSender = PassthroughSubject<LibraryViewModel.Events, Never>()
    private var subscriptions = Set<AnyCancellable>()
    
    init(
        library: LibraryService,
        coordinator: LibraryCoordinator
    ) {
        self.library = library
        self.coordinator = coordinator
        self.sortOption = UserConfigurations.shared.librarySorting
        sortOption = UserConfigurations.shared.librarySorting
        viewModeOption = UserConfigurations.shared.libraryViewMode
        fetchBooks()
    }
    
    func fetchBooks() {
        library.allBooks()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.eventSender.send(.error(error))
                }
            } receiveValue: { [weak self] newBooks in
                self?.books = newBooks
                self?.sortBooks()
            }
            .store(in: &subscriptions)
    }
}

// MARK: - Actions

extension LibraryViewModel {
    func selectBook(book: Book) {
        if selectedBooks.contains(book) {
            selectedBooks.removeAll { $0 == book }
        } else {
            selectedBooks.append(book)
        }
    }
    
    func selectAllBooks() {
        if selectedBooks.count == books.count {
            selectedBooks.removeAll()
        } else {
            selectedBooks = books
        }
    }
    
    func resetSelection() {
        selectedBooks.removeAll()
    }
}

// MARK: - Sorting

extension LibraryViewModel {
    private func sortBooks() {
        books.sort { lhs, rhs in
            switch sortOption {
            case .recent:
                return lhs.created > rhs.created
            case .title:
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            case .author:
                let author1 = lhs.authors ?? ""
                let author2 = rhs.authors ?? ""
                return author1.localizedCaseInsensitiveCompare(author2) == .orderedAscending
            }
        }
    }
}

// MARK: - Book CRUD

extension LibraryViewModel {
    func deleteBook(book: Book) {
        Task {
            do {
                try await self.library.remove(book)
            } catch {
                print("Error deleting book: \(error)")
            }
        }
    }
}

// MARK: - Events

extension LibraryViewModel {
    enum Events {
        case pushToCollections
        case openBook(book: Book)
        case deleteBook(book: Book)
        case importBook
        case error(Error)
    }
}
