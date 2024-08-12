//
//  Copyright 2024 Readium Foundation. All rights reserved.
//  Use of this source code is governed by the BSD-style license
//  available in the top-level LICENSE file of the project.
//

import Combine
import UIKit
import Firebase

//@UIApplicationMain
//class AppDelegate: UIResponder, UIApplicationDelegate {
//    var window: UIWindow?
//
//    private var app: AppModule!
//    private var subscriptions = Set<AnyCancellable>()
//
//    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        
//        FirebaseApp.configure()
//        
//        app = try! AppModule()
//
//        let tabBar = TabBarController(app: app)
//        window = UIWindow(frame: UIScreen.main.bounds)
//        window?.rootViewController = tabBar
//        window?.makeKeyAndVisible()        
//        return true
//    }
//
//    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
//        Task {
//            try! await app.library.importPublication(from: url, sender: window!.rootViewController!)
//        }
//        return true
//    }
//}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private var tabBarCoordinator: TabBarCoordinator?
    private lazy var diContainer = DIContainer()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let tabBarController = UITabBarController()
        
        let libraryNavigationController = UINavigationController()
        let catalogNavigationController = UINavigationController()
        
        let libraryCoordinator = LibraryCoordinator(
            navigationController: libraryNavigationController,
            navigationSender: PassthroughSubject<LibraryCoordinator.Events, Never>(),
            diContainer: diContainer
        )
        
        let catalogCoordinator = StoreCoordinator(
            navigationController: catalogNavigationController,
            navigationSender: PassthroughSubject<StoreCoordinator.Events, Never>(),
            diContainer: diContainer
        )
        
        let settingsCoordinator = SettingsCoordinator(
            navigationController: UINavigationController(),
            navigationSender: PassthroughSubject<SettingsCoordinator.Events, Never>(),
            diContainer: diContainer
        )
        
        tabBarCoordinator = TabBarCoordinator(
            tabBarController: tabBarController,
            navigationSender: PassthroughSubject<TabBarCoordinator.Events, Never>(),
            libraryCoordinator: libraryCoordinator,
            catalogCoordinator: catalogCoordinator, 
            settingsCoordinator: settingsCoordinator
        )
        
        tabBarCoordinator?.start()
        
        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()
        
        configureNavigationBarAppearance()
        
        return true
    }
    
    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBar.appearance()
        appearance.tintColor = .label
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
    }
}
