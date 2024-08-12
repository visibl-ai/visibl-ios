//
//  StoreViewModel.swift
//  visibl
//
//

import Foundation
import ReadiumOPDS
import ReadiumShared
import ReadiumStreamer
import UIKit

// MARK: - View Model

class StoreViewModel: ObservableObject {
    var coordinator: StoreCoordinator
    
    @Published var feed: Feed?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedBook: Publication?
    @Published var isDownloading = false
    @Published var selectedBookSource = 0
    
    private var originalFeedURL: URL?
    var nextPageURL: URL?
    
    init(
        coordinator: StoreCoordinator
    ) {
        self.coordinator = coordinator
        self.originalFeedURL = URL(string: Configuration.catalogueURL)
        
        Task {
            await loadInitialData()
        }
    }
    
    @MainActor
    private func loadInitialData() async {
        await loadFeed()
        
        do {
            try await getPrivateFeed()
        } catch {
            print("Error fetching private feed URL: \(error)")
        }
    }
    
    @MainActor
    func loadFeed() async {
        isLoading = true
        errorMessage = nil
        
        guard let url = originalFeedURL else {
            isLoading = false
            errorMessage = "Invalid feed URL"
            return
        }
        
        do {
            let feed = try await OPDSParser.parseURL(url: url)
            self.feed = feed
            self.nextPageURL = findNextPageURL(feed: feed)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    func loadNextPage() async {
        guard let nextPageURL = nextPageURL else { return }
        
        isLoading = true
        
        do {
            let newFeed = try await OPDSParser.parseURL(url: nextPageURL)
            
            self.nextPageURL = findNextPageURL(feed: newFeed)
            self.feed?.publications.append(contentsOf: newFeed.publications)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func findNextPageURL(feed: Feed) -> URL? {
        guard let href = feed.links.first(withRel: .next)?.href else {
            return nil
        }
        return URL(string: href)
    }
    
    func getPrivateFeed() async throws {
        let result: [String: String] = try await CloudFunctionService.shared.makeAuthenticatedCall(
            functionName: "v1getPrivateOPDSFeedURL"
        )
        print(result)
    }
}

// Extension to make OPDSParser.parseURL async
extension OPDSParser {
    static func parseURL(url: URL) async throws -> Feed {
        return try await withCheckedThrowingContinuation { continuation in
            OPDSParser.parseURL(url: url) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let feed = result?.feed {
                    continuation.resume(returning: feed)
                } else {
                    continuation.resume(throwing: NSError(domain: "OPDSParserError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse feed"]))
                }
            }
        }
    }
}
