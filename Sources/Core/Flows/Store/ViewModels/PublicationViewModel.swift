//
//  PublicationViewModel.swift
//  visibl
//
//

import Foundation
import ReadiumOPDS
import ReadiumShared
import ReadiumStreamer
import UIKit

// MARK: - View Model

class PublicationViewModel: ObservableObject {
    var library: LibraryService
    var coordinator: StoreCoordinator
    var publication: Publication
    var authService: AuthService
    
    @Published var errorMessage: String?
    @Published var isDownloading = false
    @Published var isDownloaded = false
    
    init(
        library: LibraryService,
        coordinator: StoreCoordinator,
        publication: Publication,
        authService: AuthService
    ) {
        self.library = library
        self.coordinator = coordinator
        self.publication = publication
        self.authService = authService
    }
    
    func checkIfBookIsDownloaded(publication: Publication) {
        Task {
            let books = try await library.allBooks().async()

            if books.contains(where: { $0.title == publication.metadata.title }) {
                await MainActor.run {
                    self.isDownloaded = true
                    print("Book already downloaded")
                }
                return
            }
        }
    }
    
    func downloadBook(publication: Publication) {
        if authService.user == nil {
            coordinator.navigationSender.send(.presentSignIn)
            return
        }
        
        guard let downloadLink = publication.downloadLinks.first else {
            self.errorMessage = "No download link available"
            return
        }
        
        Task {
            do {
                await MainActor.run {
                    self.isDownloading = true
                    self.errorMessage = nil
                }
                
                let book = try await downloadPublication(publication: publication, at: downloadLink)
                
                await MainActor.run {
                    self.isDownloading = false
                    print("Successfully downloaded: \(book.title)")
                    coordinator.navigationSender.send(.goToLibrary)
                }
            } catch {
                await MainActor.run {
                    self.isDownloading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func downloadPublication(publication: Publication?, at link: ReadiumShared.Link) async throws -> Book {
        do {
            let url = try link.url(relativeTo: publication?.baseURL, parameters: [:]).url
            
            // Create a wrapper class that conforms to UIViewController
            class ViewControllerWrapper: UIViewController {}
            let sender = await ViewControllerWrapper()
            
            return try await library.importPublication(from: url, sender: sender)
        } catch {
            throw NSError(domain: "StoreViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to resolve URL: \(error.localizedDescription)"])
        }
    }
}
