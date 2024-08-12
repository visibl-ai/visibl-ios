//
//  PublicationController.swift
//  visibl
//
//

import UIKit
import SwiftUI
import ReadiumShared

final class PublicationController: UIViewController {
    var coordinator: StoreCoordinator?
    var library: LibraryService
    var authService: AuthService
    
    var viewModel: PublicationViewModel!
    var publication: Publication!
    
    private var hostingController: UIHostingController<PublicationView>?
    
    init(
        coordinator: StoreCoordinator,
        library: LibraryService,
        publication: Publication,
        authService: AuthService
    ) {
        self.coordinator = coordinator
        self.library = library
        self.publication = publication
        self.authService = authService
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = PublicationViewModel(
            library: library,
            coordinator: coordinator!,
            publication: publication, 
            authService: authService
        )
        
        hostingController = UIHostingController(rootView: PublicationView(
            viewModel: viewModel
        ))
        
        if let hostingController = hostingController {
            addChild(hostingController)
            view.addSubview(hostingController.view)
            hostingController.view.frame = view.bounds
            hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            hostingController.didMove(toParent: self)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
        tabBarController?.tabBar.isHidden = true
        coordinator?.tabBarCoordinator?.hideNowPlayingView(isHidden: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        tabBarController?.tabBar.isHidden = false
        coordinator?.tabBarCoordinator?.hideNowPlayingView(isHidden: false)
    }
}
