//
//  StoreCoordinator.swift
//  visibl
//
//

import UIKit
import Combine
import ReadiumShared
import SwiftUI

// MARK: - CatalogCoordinator

final class StoreCoordinator: BaseCoordinator {
    private var navigationController: UINavigationController
    weak var tabBarCoordinator: TabBarCoordinator?
    let navigationSender: PassthroughSubject<StoreCoordinator.Events, Never>
    private let diContainer: DIContainer
    
    init(
        navigationController: UINavigationController,
        navigationSender: PassthroughSubject<StoreCoordinator.Events, Never>,
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
            case .main:
                openMain()
            case .openPublication(pub: let pub):
                self.openPublication(pub: pub)
            case .goToLibrary:
                tabBarCoordinator?.navigationSender.send(.openLibraryMain)
            case .presentSignIn:
                presentSignIn()
            }
        }).store(in: &cancellable)
    }
    
    func start() -> UINavigationController {
        let catalogVC = StoreController()
        catalogVC.coordinator = self
        catalogVC.aaXManager = diContainer.aaxManager
        navigationController.setViewControllers([catalogVC], animated: false)
        return navigationController
    }
    
    private func openMain() {
        // Logic to open main catalog view if needed
    }
    
    private func openPublication(pub: Publication) {
        let publicationVC = PublicationController(
            coordinator: self,
            library: diContainer.libraryService,
            publication: pub,
            authService: diContainer.authService
        )
        navigationController.pushViewController(publicationVC, animated: true)
    }
    
    func presentSignIn() {
        let vc = AccountViewController(viewModel: AccountViewModel(authService: diContainer.authService))
        navigationController.present(vc, animated: true)
    }
}

// MARK: - Store Events

extension StoreCoordinator {
    enum Events {
        case main
        case openPublication(pub: Publication)
        case goToLibrary
        case presentSignIn
    }
}
