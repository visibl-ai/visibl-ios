//
//  TabBarCoordinator.swift
//  visibl
//
//

import UIKit
import Combine
import SwiftUI
import ReadiumNavigator

// MARK: - BaseCoordinator

class BaseCoordinator {
    var cancellable = Set<AnyCancellable>()
    
    init() {
        bind()
    }
    
    func bind() {
        fatalError("Should be implemented in child class")
    }
}


// MARK: - TabBarCoordinator

final class TabBarCoordinator: BaseCoordinator {
    private weak var tabBarController: UITabBarController?
    let navigationSender: PassthroughSubject<TabBarCoordinator.Events, Never>
    let libraryCoordinator: LibraryCoordinator
    let catalogCoordinator: StoreCoordinator
    let settingsCoordinator: SettingsCoordinator
    
    private var nowPlayingViewController: UIHostingController<NowPlayingView>?
    
    init(
        tabBarController: UITabBarController,
        navigationSender: PassthroughSubject<TabBarCoordinator.Events, Never>,
        libraryCoordinator: LibraryCoordinator,
        catalogCoordinator: StoreCoordinator,
        settingsCoordinator: SettingsCoordinator
    ) {
        self.navigationSender = navigationSender
        self.tabBarController = tabBarController
        self.libraryCoordinator = libraryCoordinator
        self.catalogCoordinator = catalogCoordinator
        self.settingsCoordinator = settingsCoordinator
        super.init()
        libraryCoordinator.tabBarCoordinator = self
        catalogCoordinator.tabBarCoordinator = self
    }
    
    override func bind() {
        navigationSender.sink(receiveValue: { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .openLibrary(let event):
                libraryCoordinator.navigationSender.send(event)
            case .openLibraryMain:
                tabBarController?.selectedIndex = 0
            case .openCatalog(let event):
                catalogCoordinator.navigationSender.send(event)
            case .openCatalogMain:
                tabBarController?.selectedIndex = 1
            case .openSettings(let event):
                settingsCoordinator.navigationSender.send(event)
            case .openSettingsMain:
                tabBarController?.selectedIndex = 2
            }
        }).store(in: &cancellable)
    }
    
    func start() {
        let libraryVC = libraryCoordinator.start()
        let catalogVC = catalogCoordinator.start()
        let settingsVC = settingsCoordinator.start()
        
        libraryVC.tabBarItem = makeItem(title: "bookshelf_tab", image: "books.vertical.fill")
        catalogVC.tabBarItem = makeItem(title: "store_tab", image: "bag.fill")
        settingsVC.tabBarItem = makeItem(title: "settings_tab", image: "gearshape.fill")
        
        tabBarController?.viewControllers = [libraryVC, catalogVC, settingsVC]
        configureTabBarAppearance()
    }
    
    private func configureTabBarAppearance() {
        tabBarController?.tabBar.tintColor = .label
        tabBarController?.tabBar.unselectedItemTintColor = .systemGray2
        tabBarController?.tabBar.barTintColor = .systemBackground
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        tabBarController?.tabBar.standardAppearance = appearance
        tabBarController?.tabBar.scrollEdgeAppearance = appearance
    }
    
    private func makeItem(title: String, image: String) -> UITabBarItem {
        UITabBarItem(
            title: NSLocalizedString(title, comment: "Tab title"),
            image: UIImage(systemName: image),
            tag: 0
        )
    }
}

// MARK: - Now Playing View Setup

extension TabBarCoordinator {
    func showNowPlayingView(
        manager: PlayerManager,
        close: @escaping () -> Void,
        open: @escaping () -> Void
    ) {
        guard nowPlayingViewController == nil else { return }
        
        let nowPlayingView = NowPlayingView(
            manager: manager,
            close: { [weak self] in
                self?.deinitNowPlayingView()
                close()
            },
            open: {
                open()
            }
        )
        
        let hostingController = UIHostingController(rootView: nowPlayingView)
        nowPlayingViewController = hostingController
        
        tabBarController?.addChild(hostingController)
        tabBarController?.view.addSubview(hostingController.view)
        hostingController.didMove(toParent: tabBarController)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: tabBarController!.view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: tabBarController!.view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: tabBarController!.tabBar.topAnchor, constant: -8),
            hostingController.view.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    func deinitNowPlayingView() {
        nowPlayingViewController?.willMove(toParent: nil)
        nowPlayingViewController?.view.removeFromSuperview()
        nowPlayingViewController?.removeFromParent()
        nowPlayingViewController = nil
    }
    
    func hideNowPlayingView(isHidden: Bool) {
        nowPlayingViewController?.view.isHidden = isHidden
    }
}

// MARK: - TabBar Events

extension TabBarCoordinator {
    enum Events {
        case openLibrary(LibraryCoordinator.Events)
        case openLibraryMain
        case openCatalog(StoreCoordinator.Events)
        case openCatalogMain
        case openSettings(SettingsCoordinator.Events)
        case openSettingsMain
    }
}
