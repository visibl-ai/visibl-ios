//
//  TabBarController.swift
//  visibl
//
//

import UIKit

class TabBarController: UITabBarController {
    
    let app: AppModule
    
    init(app: AppModule) {
        self.app = app
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Library
        let libraryViewController = app.library.rootViewController
        libraryViewController.tabBarItem = makeItem(title: "bookshelf_tab", image: "books.vertical.fill")
        
        // OPDS Feeds
        let opdsViewController = app.opds.rootViewController
        opdsViewController.tabBarItem = makeItem(title: "store_tab", image: "bag.fill")
        
        // Settings
        let settingsViewController = app.settingsViewController
        settingsViewController.tabBarItem = makeItem(title: "settings_tab", image: "gear")
        
        self.viewControllers = [
            libraryViewController,
            opdsViewController,
            settingsViewController
        ]
        
        self.tabBar.tintColor = .label
        self.tabBar.unselectedItemTintColor = .systemGray2
        self.tabBar.barTintColor = .systemBackground
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        self.tabBar.standardAppearance = appearance
        self.tabBar.scrollEdgeAppearance = appearance
    }
    
    func makeItem(title: String, image: String) -> UITabBarItem {
        UITabBarItem(
            title: title.localized,
            image: UIImage(systemName: image),
            tag: 0
        )
    }
}
