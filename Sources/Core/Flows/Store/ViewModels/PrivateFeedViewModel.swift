//
//  PrivateFeedViewModel.swift
//  visibl
//
//

import Foundation
import ReadiumOPDS
import ReadiumShared
import ReadiumStreamer
import UIKit
import Combine

// MARK: - View Model

class PrivateFeedViewModel: ObservableObject {
    var aaxManager: AAXManager
    var coordinator: StoreCoordinator
    
    @Published var axxUser: AAXUserModel?
    
    @Published var feed: Feed?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedBook: Publication?
    @Published var isDownloading = false
    @Published var selectedBookSource = 0
    
    private var originalFeedURL: URL?
    var nextPageURL: URL?
    var cancellables = Set<AnyCancellable>()
    
    init(
        axxManager: AAXManager,
        coordinator: StoreCoordinator
    ) {
        self.aaxManager = axxManager
        self.coordinator = coordinator
        Task { await loadInitialFeed() }
        
        aaxManager.$axxUser
            .assign(to: \.axxUser, on: self)
            .store(in: &cancellables)
    }
    
    @MainActor
    private func loadInitialFeed() async {
        do {
            let feedURLString = try await getPrivateFeed()
            self.originalFeedURL = URL(string: feedURLString)
            await loadFeed()
        } catch {
            print("Error fetching private feed URL: \(error.localizedDescription)")
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
    
    struct URLModel: Codable {
        let url: String
        
        enum CodingKeys: String, CodingKey {
            case url
        }
    }
    
    func getPrivateFeed() async throws -> String {
        let result: URLModel = try await CloudFunctionService.shared.makeAuthenticatedCall(
            functionName: "v1getPrivateOPDSFeedURL"
        )
        
        print(result)
        return result.url
    }
}
