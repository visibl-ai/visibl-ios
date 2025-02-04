//
//  Copyright 2024 Readium Foundation. All rights reserved.
//  Use of this source code is governed by the BSD-style license
//  available in the top-level LICENSE file of the project.
//

import Combine
import Kingfisher
import ReadiumShared
import UIKit
import FirebaseAuth

protocol OPDSPublicationInfoViewControllerFactory {
    func make(publication: Publication) -> OPDSPublicationInfoViewController
}

class OPDSPublicationInfoViewController: UIViewController, Loggable {
    weak var moduleDelegate: OPDSModuleDelegate?

    var publication: Publication?
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var fxImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var authorLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var downloadButton: UIButton!
    @IBOutlet var downloadActivityIndicator: UIActivityIndicatorView!

    private lazy var downloadLink: Link? = publication?.downloadLinks.first
    private var subscriptions = Set<AnyCancellable>()
    
    let authService = AuthService.shared

    override func viewDidLoad() {
        fxImageView.clipsToBounds = true
        fxImageView!.contentMode = .scaleAspectFill
        imageView!.contentMode = .scaleAspectFit

        let titleTextView = OPDSPlaceholderPublicationView(
            frame: imageView.frame,
            title: publication?.metadata.title,
            author: publication?.metadata.authors
                .map(\.name)
                .joined(separator: ", ")
        )

        if let images = publication?.images {
            if images.count > 0 {
                let coverURL = URL(string: images[0].href)
                if coverURL != nil {
                    imageView.kf.setImage(
                        with: coverURL,
                        placeholder: titleTextView,
                        options: [.transition(ImageTransition.fade(0.5))],
                        progressBlock: nil
                    ) { result in
                        switch result {
                        case let .success(image):
                            self.fxImageView?.image = image.image
                            UIView.transition(
                                with: self.fxImageView,
                                duration: 0.3,
                                options: .transitionCrossDissolve,
                                animations: { self.fxImageView?.image = image.image },
                                completion: nil
                            )
                        case .failure:
                            break
                        }
                    }
                }
            }
        }

        titleLabel.text = publication?.metadata.title
        authorLabel.text = publication?.metadata.authors
            .map(\.name)
            .joined(separator: ", ")
        descriptionLabel.text = publication?.metadata.description
        descriptionLabel.sizeToFit()

        downloadActivityIndicator.stopAnimating()

        // If we are not able to get a free link, we hide the download button
        // TODO: handle payment or redirection for others links?
        if downloadLink == nil {
            downloadButton.isHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.tintColor = .label
//        tabBarController?.tabBar.isHidden = true
    }
    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        tabBarController?.tabBar.isHidden = false
//    }

    @IBAction func downloadBook(_ sender: UIButton) {
        guard let delegate = moduleDelegate, let downloadLink = downloadLink else {
            return
        }

        Task {
            do {
                guard Auth.auth().currentUser != nil else {
                    delegate.presentAlertWithButtons(
                        NSLocalizedString("no_user_logged_in_error_title", comment: "Title of the alert when there's an error"),
                        message: NSLocalizedString("no_user_logged_in_description", comment: "Message when no user is logged in"),
                        buttons: [
                            (NSLocalizedString("no_user_logged_in_cancel_button", comment: "Title for cancel button"), nil),
                            (NSLocalizedString("no_user_logged_in_action_button", comment: "Title for login button"), {
                                self.showAuth()
                            })
                        ],
                        from: self
                    )
                    return
                }
                
                downloadActivityIndicator.startAnimating()
                downloadButton.isEnabled = false

                let book = try await delegate.opdsDownloadPublication(publication, at: downloadLink, sender: self)
                
                delegate.presentAlert(
                    NSLocalizedString("success_title", comment: "Title of the alert when a publication is successfully downloaded"),
                    message: String(format: NSLocalizedString("library_download_success_message", comment: "Message of the alert when a publication is successfully downloaded"), book.title),
                    from: self
                )
            } catch {
                delegate.presentError(error, from: self)
            }

            downloadActivityIndicator.stopAnimating()
            downloadButton.isEnabled = true
            openLibrary()
        }
    }
    
    func showAuth() {
        let vc = AccountViewController(viewModel: AccountViewModel(authService: authService))
        self.present(vc, animated: true)
    }
    
    func openLibrary() {
        tabBarController?.selectedIndex = 0
    }
}
