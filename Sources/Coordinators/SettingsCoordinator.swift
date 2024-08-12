//
//  SettingsCoordinator.swift
//  visibl
//
//

import UIKit
import Combine
import ReadiumShared
import SwiftUI

// MARK: - CatalogCoordinator

final class SettingsCoordinator: BaseCoordinator {
    private var navigationController: UINavigationController
    weak var tabBarCoordinator: TabBarCoordinator?
    let navigationSender: PassthroughSubject<SettingsCoordinator.Events, Never>
    private let diContainer: DIContainer
    
    init(
        navigationController: UINavigationController,
        navigationSender: PassthroughSubject<SettingsCoordinator.Events, Never>,
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
            case .goToLibrary:
                tabBarCoordinator?.navigationSender.send(.openLibraryMain)
            case .goToStore:
                tabBarCoordinator?.navigationSender.send(.openCatalogMain)
            case .goToSettings:
                tabBarCoordinator?.navigationSender.send(.openSettingsMain)
            case .presentSignIn:
                presentSignIn()
            case .presentExternalLibraryConnect:
                presentExternalLibraryConnect()
            }
        }).store(in: &cancellable)
    }
    
    func start() -> UINavigationController {
        let settingsVC = SettingsController(aaxManager: diContainer.aaxManager)
        settingsVC.coordinator = self
        navigationController.setViewControllers([settingsVC], animated: false)
        return navigationController
    }
    
    func presentSignIn() {
        let vc = AccountViewController(viewModel: AccountViewModel(authService: diContainer.authService))
        navigationController.present(vc, animated: true)
    }
    
    func presentExternalLibraryConnect() {
        let vc = AAXConnectController(aaxManager: diContainer.aaxManager)
        navigationController.present(vc, animated: true)
    }
    
    func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        navigationController.present(alert, animated: true)
    }
    
    func presentAlertWithAction(title: String, message: String, actionTitle: String, action: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: { _ in
            action()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        navigationController.present(alert, animated: true)
    }
}

// MARK: - Settings Events

extension SettingsCoordinator {
    enum Events {
        case goToLibrary
        case goToStore
        case goToSettings
        case presentSignIn
        case presentExternalLibraryConnect
    }
}
