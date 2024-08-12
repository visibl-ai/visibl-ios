//
//  AAXConnectController.swift
//  visibl
//
//

import UIKit
import SwiftUI
import Combine

class AAXConnectController: UIViewController {
    private let aaxManager: AAXManager
    private lazy var hostingController = UIHostingController(rootView: CountryPickerView(aaxManager: aaxManager))
    var cancellable = Set<AnyCancellable>()
    
    init(aaxManager: AAXManager) {
        self.aaxManager = aaxManager
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
        bind()
    }
    
    private func bind() {
        aaxManager.eventSender.sink(receiveValue: { [unowned self] event in
            switch event {
            case .dismiss:
                self.dismiss(animated: true, completion: nil)
            }
        }).store(in: &cancellable)
    }
}
