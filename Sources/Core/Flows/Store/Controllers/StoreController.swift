//
//  StoreController.swift
//  visibl
//
//

import UIKit
import SwiftUI
import ReadiumShared
import ReadiumNavigator

class StoreController: BaseController {
    private var storeViewModel: StoreViewModel!
    private var privateFeedViewModel: PrivateFeedViewModel!
    var aaXManager: AAXManager?
    private lazy var hostingController = UIHostingController(rootView: MainStoreView(
        storeViewModel: self.storeViewModel,
        privateFeedViewModel: self.privateFeedViewModel
    ))
    
    var coordinator: StoreCoordinator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        storeViewModel = StoreViewModel(coordinator: coordinator!)
        privateFeedViewModel = PrivateFeedViewModel(axxManager: aaXManager!, coordinator: coordinator!)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.didMove(toParent: self)
        self.title = "store_tab".localized
    }
}
