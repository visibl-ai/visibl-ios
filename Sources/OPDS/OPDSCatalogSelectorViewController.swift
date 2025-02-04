//
//  Copyright 2024 Readium Foundation. All rights reserved.
//  Use of this source code is governed by the BSD-style license
//  available in the top-level LICENSE file of the project.
//

import Foundation
import ReadiumOPDS
import ReadiumShared
import UIKit

protocol OPDSCatalogSelectorViewControllerFactory {
    func make() -> OPDSCatalogSelectorViewController
}

class OPDSCatalogSelectorViewController: UITableViewController {
    var catalogData: [[String: String]]? // An array of dicts in the form ["title": title, "url": url]
    let cellReuseIdentifier = "catalogSelectorCell"
    let userDefaultsID = "opdsCatalogArray"
    var addFeedButton: UIBarButtonItem?
    var mustEditAtIndexPath: IndexPath?

    override func viewDidLoad() {
        self.title = "catalogs_tab".localized
        
        preloadTestFeeds()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)

        tableView.frame = UIScreen.main.bounds
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.sizeToFit()

        addFeedButton = UIBarButtonItem(title: NSLocalizedString("add_button", comment: "Add an OPDS feed button"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(OPDSCatalogSelectorViewController.showAddFeedPopup))
        addFeedButton?.accessibilityLabel = NSLocalizedString("opds_add_button_a11y_label", comment: "Add an OPDS feed button")

        navigationItem.rightBarButtonItem = addFeedButton
    }

    func preloadTestFeeds() {
        let version = 2
        let VERSION_KEY = "OPDS_CATALOG_VERSION"
        let visiblCatalog = ["title": "", "url": ""]

        catalogData = UserDefaults.standard.array(forKey: userDefaultsID) as? [[String: String]]
        let oldversion = UserDefaults.standard.integer(forKey: VERSION_KEY)
        if catalogData == nil || oldversion < version {
            UserDefaults.standard.set(version, forKey: VERSION_KEY)
            catalogData = [
                visiblCatalog
            ]
            UserDefaults.standard.set(catalogData, forKey: userDefaultsID)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        if let index = mustEditAtIndexPath?.row {
            showEditPopup(feedIndex: index)
        }
        mustEditAtIndexPath = nil
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        catalogData!.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        cell.textLabel?.text = catalogData![indexPath.row]["title"]
        return cell
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        cell.separatorInset = UIEdgeInsets.zero
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: false)
        guard let urlString = catalogData![indexPath.row]["url"],
              let url = URL(string: urlString)
        else {
            return
        }

        let viewController: OPDSRootTableViewController = OPDSFactory.shared.make(feedURL: url, indexPath: indexPath)
        navigationController?.pushViewController(viewController, animated: true)
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // action one
        let editAction = UIContextualAction(
            style: .normal,
            title: NSLocalizedString("edit_button", comment: "Edit a OPDS feed button")
        ) { _, _, completion in
            self.showEditPopup(feedIndex: indexPath.row)
            completion(true)
        }
        editAction.backgroundColor = UIColor.gray

        // action two
        let deleteAction = UIContextualAction(
            style: .destructive,
            title: NSLocalizedString("remove_button", comment: "Remove an OPDS feed button")
        ) { _, _, completion in
            self.catalogData?.remove(at: indexPath.row)
            UserDefaults.standard.set(self.catalogData, forKey: self.userDefaultsID)
            self.tableView.reloadData()
            completion(true)
        }
        deleteAction.backgroundColor = UIColor.gray

        return UISwipeActionsConfiguration(actions: [editAction, deleteAction])
    }

    @objc func showAddFeedPopup() {
        showEditPopup(feedIndex: nil)
    }

    func showEditPopup(feedIndex: Int?, retry: Bool = false) {
        let alertController = UIAlertController(
            title: NSLocalizedString("opds_add_title", comment: "Title of the add feed alert"),
            message: retry ? NSLocalizedString("opds_add_failure_message", comment: "Message when adding an invalid OPDS feed") : nil,
            preferredStyle: .alert
        )
        let confirmAction = UIAlertAction(title: NSLocalizedString("ok_button", comment: "Confirm addition of OPDS feed button"), style: .default) { _ in
            if let title = alertController.textFields?[0].text,
               let urlString = alertController.textFields?[1].text,
               let url = URL(string: urlString)
            {
                OPDSParser.parseURL(url: url) { _, error in
                    DispatchQueue.main.async {
                        guard error == nil else {
                            self.showEditPopup(feedIndex: feedIndex, retry: true)
                            return
                        }

                        if feedIndex == nil {
                            self.catalogData?.append(["title": title, "url": urlString])
                        } else {
                            self.catalogData?[feedIndex!] = ["title": title, "url": urlString]
                        }
                        UserDefaults.standard.set(self.catalogData, forKey: self.userDefaultsID)
                        self.tableView.reloadData()
                    }
                }
            } else {
                self.showEditPopup(feedIndex: feedIndex, retry: true)
            }
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("cancel_button", comment: "Button to cancel addition of the OPDS feed"), style: .cancel) { _ in }
        alertController.addTextField { textField in
            textField.placeholder = NSLocalizedString("opds_feed_title_caption", comment: "Label for the OPDS feed title field")
            if feedIndex != nil {
                textField.text = self.catalogData![feedIndex!]["title"]
            }
        }
        alertController.addTextField { textField in
            textField.placeholder = NSLocalizedString("opds_feed_url_caption", comment: "Label for the OPDS feed URL field")
            if feedIndex != nil {
                textField.text = self.catalogData![feedIndex!]["url"]
            }
        }
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}
