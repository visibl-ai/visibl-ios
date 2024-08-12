//
//  CollectionsController.swift
//  visibl
//
//

import UIKit
import SwiftUI

class CollectionsController: BaseController {
    private let viewModel = CollectionsViewModel()
    private let collectionsManager: CollectionsManager
    var coordinator: LibraryCoordinator?
    private lazy var hostingController = UIHostingController(rootView: CollectionsView(
        viewModel: viewModel,
        collectionsManager: collectionsManager)
    )
    
    init(collectionsManager: CollectionsManager) {
        self.collectionsManager = collectionsManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.didMove(toParent: self)
        self.title = "Collections"
    }
}
