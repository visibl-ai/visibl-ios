//
//  SettingsController.swift
//  visibl
//
//

import UIKit
import SwiftUI
import Combine

class SettingsController: BaseController {
    private var viewModel: SettingsViewModel!
    var aaxManager: AAXManager
    var cancellable = Set<AnyCancellable>()
    var coordinator: SettingsCoordinator?
    
    init(aaxManager: AAXManager) {
        self.aaxManager = aaxManager
        viewModel = SettingsViewModel(aaxManager: aaxManager)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "settings_title".localized
        addSwiftUIView(SettingsView(viewModel: viewModel))
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        LibraryManager.shared.listCatalogueItems()
//        LibraryManager.shared.addItemToUserLibrary(catalogueId: "riw7PiKBeKZF70WUMoSw")
//        LibraryManager.shared.getUserLibrary(includeManifest: false)
//        LibraryManager.shared.deleteBooks(bookIDs: ["jjJsGYMnqsyG3yxREpXT"])
//        LibraryManager.shared.getSceneJSON(libraryId: "jjJsGYMnqsyG3yxREpXT")
    }
    
    private func bind() {
        viewModel.eventSender.sink(receiveValue: { [unowned self] event in
            switch event {
            case .showAuth:
                self.coordinator?.navigationSender.send(.presentSignIn)
            case .showAAXAuth:
                self.connectAAX()
            }
        }).store(in: &cancellable)
    }
    
    private func connectAAX() {
        if viewModel.user != nil {
            coordinator?.navigationSender.send(.presentExternalLibraryConnect)
        } else {
            coordinator?.presentAlertWithAction(
                title: "Sign In Required",
                message: "Please sign in to your Visibl Account before connecting to your external library.",
                actionTitle: "Sign In",
                action: {
                    self.coordinator?.navigationSender.send(.presentSignIn)
                }
            )
        }
    }
}
