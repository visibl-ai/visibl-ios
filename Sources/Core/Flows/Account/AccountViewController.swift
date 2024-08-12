//
//  AccountViewController.swift
//  visibl
//
//

import UIKit
import SwiftUI
import Combine
import GoogleSignIn

class AccountViewController: UIViewController {
    private let viewModel: AccountViewModel
    private var hostingController: UIHostingController<AnyView>
    var cancellable = Set<AnyCancellable>()
    
    init(viewModel: AccountViewModel) {
        self.viewModel = viewModel
        self.hostingController = UIHostingController(rootView: AnyView(EmptyView()))
        super.init(nibName: nil, bundle: nil)
        
        switch viewModel.state {
        case .auth:
            let authView = LoginView(viewModel: self.viewModel)
            self.hostingController.rootView = AnyView(authView)
        case .account:
            let accountView = AccountView(viewModel: self.viewModel)
            self.hostingController.rootView = AnyView(accountView)
        case .none:
            print("Error")
        }
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
        viewModel.eventSender.sink { [unowned self] event in
            switch event {
            case .authSuccess:
                self.dismiss(animated: true)
            case .authError(let error):
                self.showErrorAlert(error: error)
                print(error.localizedDescription)
            case .signOut:
                viewModel.signOut()
                self.dismiss(animated: true)
            case .dismiss:
                self.dismiss(animated: true)
            case .googleSignIn:
                self.initiateGoogleSignIn()
            }
        }.store(in: &cancellable)
    }
    
    private func initiateGoogleSignIn() {
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] signInResult, error in
            guard let self = self else { return }
            
            if error != nil {
                return
            }
            
            guard let signInResult = signInResult else {
                self.viewModel.eventSender.send(
                    .authError(
                        error: NSError(
                            domain: "GoogleSignIn",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "No sign-in result"]
                        )
                    )
                )
                return
            }
            
            self.viewModel.loginWithGoogle(signInResult)
        }
    }
    
    private func showErrorAlert(error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }
}
