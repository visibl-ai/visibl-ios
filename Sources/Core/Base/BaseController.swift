//
//  BaseController.swift
//  visibl
//
//

import UIKit
import SwiftUI

class BaseController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillAppear(animated)
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Set large title font
        navigationController?.navigationBar.largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 36, weight: .bold).withSerifDesign()
        ]
        
        // Small title when scrolled
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .semibold).withSerifDesign()
        ]
    }
}

extension BaseController {
    func makeAlertWithConfirmation(title: String, message: String, confirmTitle: String, confirm: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: confirmTitle, style: .destructive) { _ in
            confirm()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
}

extension BaseController {
    func addSwiftUIView<T: View>(_ swiftUIView: T, to containerView: UIView? = nil) {
        let hostingController = UIHostingController(rootView: swiftUIView)
        addChild(hostingController)
        
        let targetView = containerView ?? view!
        targetView.addSubview(hostingController.view)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: targetView.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: targetView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: targetView.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: targetView.bottomAnchor)
        ])
        
        hostingController.didMove(toParent: self)
    }
}
