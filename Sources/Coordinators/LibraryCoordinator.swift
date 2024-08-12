//
//  LibraryCoordinator.swift
//  visibl
//
//

import UIKit
import Combine
import ReadiumShared
import ReadiumNavigator
import SwiftUI

final class LibraryCoordinator: BaseCoordinator {
    private weak var navigationController: UINavigationController?
    weak var tabBarCoordinator: TabBarCoordinator?
    let navigationSender: PassthroughSubject<LibraryCoordinator.Events, Never>
    private let diContainer: DIContainer
    
    private var currentNavigator: AudioNavigator?
    private var currentManager: PlayerManager?
    
    init(
        navigationController: UINavigationController?,
        navigationSender: PassthroughSubject<LibraryCoordinator.Events, Never>,
        diContainer: DIContainer
    ) {
        self.navigationController = navigationController
        self.navigationSender = navigationSender
        self.diContainer = diContainer
        super.init()
    }
    
    override func bind() {
        navigationSender.sink(receiveValue: { [weak self] event in
            guard let self = self else { return }
            switch event {
            case let .open(flow):
                openFlow(flow: flow)
            case .goToCatalog:
                tabBarCoordinator?.navigationSender.send(.openCatalogMain)
            case .openCollections:
                openCollections()
            case .openSingleCollection(_, _):
                break
            }
        }).store(in: &cancellable)
    }
    
    func start() -> UINavigationController {
        let libraryVC = LibraryController(library: diContainer.libraryService, collectionsManager: diContainer.collectionsManager)
        libraryVC.coordinator = self
        navigationController?.setViewControllers([libraryVC], animated: false)
        return navigationController ?? UINavigationController(rootViewController: libraryVC)
    }
    
    private func openFlow(flow: Flows) {
        switch flow {
        case .openPlayer(let book):
            openBook(book: book)
        }
    }
}

// MARK: - Open Collections

extension LibraryCoordinator {
    private func openCollections() {
        let collectionsVC = CollectionsController(collectionsManager: diContainer.collectionsManager)
        collectionsVC.coordinator = self
        navigationController?.pushViewController(collectionsVC, animated: true)
    }
}

// MARK: - Open Book Player

extension LibraryCoordinator {
    // MARK: - Process Book
    /// extra layer to check current now playing book and navigator
    private func processBook(book: Book, topVC: UIViewController) async throws {
        await MainActor.run {
            currentNavigator?.pause()
            currentNavigator?.player.replaceCurrentItem(with: nil)
            currentNavigator = nil
            currentManager = nil
            tabBarCoordinator?.deinitNowPlayingView()
        }
        
        ArtworkManager.shared.currentBookRemoteID = book.remoteLibraryID
        
        let pub = try await diContainer.libraryService.openBook(book, sender: topVC)
        let preferencesStore = diContainer.makePreferencesStore()
        
        let navigator = try await AudioNavigator(
            publication: pub,
            initialLocation: book.locator,
            config: AudioNavigator.Configuration(
                preferences: preferencesStore.preferences(for: book.id!)
            )
        )
        
        currentNavigator = navigator
        
        currentManager = PlayerManager(
            publication: pub,
            bookId: book.id!,
            books: diContainer.books,
            bookmarks: diContainer.bookmarks,
            navigator: navigator,
            preferencesStore: preferencesStore
        )
    }
    
    private func openBook(book: Book) {
        Task {
            do {
                guard let topViewController = await navigationController?.topViewController else {
                    print("Error: No top view controller found")
                    return
                }
                
                if currentManager?.bookId != book.id {
                    try await processBook(book: book, topVC: topViewController)
                }
                
//                await ArtworkManager.shared.decodeSceneMap()
                
                await MainActor.run {
                    let hostingVC = UIHostingController(rootView: VisualBookPlayer(
                        manager: currentManager!,
                        hidePlayer: {
                            topViewController.dismiss(animated: true)
                        }
                    ))
                    
                    hostingVC.modalPresentationStyle = .fullScreen
                    topViewController.present(hostingVC, animated: true) {
                        self.tabBarCoordinator?.showNowPlayingView(
                            manager: self.currentManager!,
                            close: {
                                self.currentNavigator?.pause()
                                NowPlayingInfo.shared.clear()
                                self.currentNavigator?.player.replaceCurrentItem(with: nil)
                                self.currentNavigator = nil
                                self.currentManager = nil
                            },
                            open: {
                                topViewController.present(hostingVC, animated: true)
                            }
                        )
                    }
                }
            } catch {
                print("Error opening book: \(error)")
            }
        }
    }
}

// MARK: - Library Events

extension LibraryCoordinator {
    enum Events {
        case open(Flows)
        case goToCatalog
        case openCollections
        case openSingleCollection(CollectionModel, [Book])
    }
    
    enum Flows {
        case openPlayer(Book)
    }
}
