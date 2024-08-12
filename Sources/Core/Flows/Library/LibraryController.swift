//
//  LibraryController.swift
//  visibl
//
//

import UIKit
import SwiftUI
import Combine
import ReadiumShared
import UniformTypeIdentifiers
import ReadiumNavigator

class LibraryController: BaseController {
        
    var coordinator: LibraryCoordinator?
    
    var library: LibraryService
    var collectionsManager: CollectionsManager
    
    init(
        library: LibraryService,
        collectionsManager: CollectionsManager
    ) {
        self.library = library
        self.collectionsManager = collectionsManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var viewModel: LibraryViewModel!
    
    private var subscriptions = Set<AnyCancellable>()
        
    private var editingRightBarButtonItems: [UIBarButtonItem] = []
    private var editingLeftBarButtonItems: [UIBarButtonItem] = []
    private var defaultRightBarButtonItems: [UIBarButtonItem] = []
    
    private var tabBarOverlay: EditingModeTabBarOverlay?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = LibraryViewModel(library: library, coordinator: coordinator!)
        addSwiftUIView(LibraryView(viewModel: viewModel, collectionsManager: collectionsManager))
        self.title = "bookshelf_tab".localized
        setupBarButtonItems()
        bind()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.isEditing = false
    }
    
    // MARK: - Button Actions
    
    @objc func addBookFromDevice() {
        var types = DocumentTypes.main.supportedUTTypes
        types.append(UTType.text)
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }
    
    @objc private func doneEditing() {
        viewModel.isEditing = false
    }
    
    @objc private func selectAllBooks() {
        viewModel.selectAllBooks()
    }
    
    @objc private func deleteSelectedBooks() {
        let selectedBooksCount = viewModel.selectedBooks.count
        
        let title = NSLocalizedString("batch_delete_books_confirmation_title", comment: "")
        let message = String(format: NSLocalizedString("batch_delete_books_confirmation_desc", comment: ""), selectedBooksCount)
        let confirmTitle = NSLocalizedString("batch_delete_books_confirmation_button", comment: "")
        
        makeAlertWithConfirmation(
            title: title,
            message: message,
            confirmTitle: confirmTitle
        ) {
            self.batchDeleteBooks()
        }
    }
    
    @objc private func addSelectedBooksTo() {
        print("Add selected to")
    }
    
    private func setupBarButtonItems() {
        let addBookButton = CustomRoundedButton(systemName: "plus")
        addBookButton.addTarget(self, action: #selector(addBookFromDevice), for: .touchUpInside)
        let addBookBarButtonItem = addBookButton.asBarButtonItem()
        
        let menuButton = CustomRoundedButton(systemName: "ellipsis")
        menuButton.showsMenuAsPrimaryAction = true
        menuButton.menu = createMenu()
        let menuBarButtonItem = menuButton.asBarButtonItem()
        
        defaultRightBarButtonItems = [menuBarButtonItem, addBookBarButtonItem]
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneEditing))
        doneButton.tintColor = .label
        let selectAllButton = UIBarButtonItem(title: "library_menu_select_all_button".localized, style: .plain, target: self, action: #selector(selectAllBooks))
        selectAllButton.tintColor = .label
        
        editingRightBarButtonItems = [doneButton]
        editingLeftBarButtonItems = [selectAllButton]
        
        navigationItem.rightBarButtonItems = defaultRightBarButtonItems
    }
    
    private func updateBarButtonItems(isEditing: Bool) {
        if isEditing {
            navigationItem.rightBarButtonItems = editingRightBarButtonItems
            navigationItem.leftBarButtonItems = editingLeftBarButtonItems
            showTabBarOverlay()
        } else {
            navigationItem.rightBarButtonItems = defaultRightBarButtonItems
            navigationItem.leftBarButtonItems = nil
            hideTabBarOverlay()
        }
    }
    
    private func showTabBarOverlay() {
        guard tabBarOverlay == nil else { return }
        
        let overlay = EditingModeTabBarOverlay(frame: tabBarController?.tabBar.frame ?? .zero)
        tabBarController?.view.addSubview(overlay)
        
        overlay.deleteButton.addTarget(self, action: #selector(deleteSelectedBooks), for: .touchUpInside)
        overlay.addToButton.addTarget(self, action: #selector(addSelectedBooksTo), for: .touchUpInside)
        
        updateTabBarOverlayButtons(isEnabled: !viewModel.selectedBooks.isEmpty)
        
        tabBarOverlay = overlay
    }
    
    private func hideTabBarOverlay() {
        tabBarOverlay?.removeFromSuperview()
        tabBarOverlay = nil
    }
    
    private func updateTabBarOverlayButtons(isEnabled: Bool) {
        tabBarOverlay?.updateButtonStates(isEnabled: isEnabled)
    }
    
    private func pushToCollections() { }
}

// MARK: - Binding

extension LibraryController {
    func bind() {
        viewModel.eventSender.sink { [weak self] event in
            switch event {
            case .openBook(let book):
                self?.openBook(book: book)
            case .deleteBook(book: let book):
                self?.deleteBookWithConfirmation(book: book)
            case .error(_):
                print("Error")
            case .pushToCollections:
                self?.pushToCollections()
            case .importBook:
                print("Importing book")
            }
        }.store(in: &subscriptions)
        
        viewModel.$isEditing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEditing in
                self?.updateBarButtonItems(isEditing: isEditing)
            }
            .store(in: &subscriptions)
        
        viewModel.$selectedBooks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] selectedBooks in
                self?.updateTabBarOverlayButtons(isEnabled: !selectedBooks.isEmpty)
            }
            .store(in: &subscriptions)
    }
}

// MARK: - Book Related Actions

extension LibraryController {
    func openBook(book: Book) {
        coordinator?.navigationSender.send(.open(.openPlayer(book)))
    }
    
    func deleteBookWithConfirmation(book: Book) {
        if NowPlayingInfo.shared.media?.title == book.title {
            toast("Close player before deleting \(book.title)", on: self.view, duration: 2.0)
            return
        }
        
        let title = NSLocalizedString("book_delete_confirmation_title", comment: "")
        let message = String(format: NSLocalizedString("book_delete_confirmation_desc", comment: ""), book.title)
        let confirmTitle = NSLocalizedString("book_delete_confirmation_button", comment: "")
        
        makeAlertWithConfirmation(
            title: title,
            message: message,
            confirmTitle: confirmTitle
        ) {
            self.viewModel.deleteBook(book: book)
        }
    }
    
    func batchDeleteBooks() {
        if !viewModel.selectedBooks.isEmpty {
            for book in viewModel.selectedBooks {
                
                if NowPlayingInfo.shared.media?.title == book.title {
                    toast("Close player before deleting \(book.title)", on: self.view, duration: 2.0)
                    return
                }
                
                viewModel.deleteBook(book: book)
            }
            viewModel.selectedBooks.removeAll()
        }
        
        viewModel.isEditing = false
    }
}

// MARK: - UIDocumentPickerDelegate.

extension LibraryController: UIDocumentPickerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        importFiles(at: urls)
    }
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        importFiles(at: [url])
    }
    
    private func importFiles(at urls: [URL]) {
        Task {
            do {
                try await library.importPublications(from: urls, sender: self)
            } catch {
                print("Error importing files: \(error)")
            }
        }
    }
}

// Mark: - UIMenu

extension LibraryController {
    private func createMenu() -> UIMenu {
        return UIMenu.lazyMenuItems { [weak self] in
            guard let self = self else { return [] }
            
            let selectAction = UIAction(title: "library_menu_select_button".localized, image: UIImage(systemName: "checkmark.circle")) { _ in
                self.viewModel.isEditing.toggle()
            }
            
            let switchToGridAction = UIAction(
                title: "library_menu_grid_button".localized,
                image: UIImage(systemName: "square.grid.2x2"),
                state: self.viewModel.viewModeOption == .grid ? .on : .off
            ) { _ in
                self.viewModel.viewModeOption = .grid
            }
            
            let switchToListAction = UIAction(
                title: "library_menu_list_button".localized,
                image: UIImage(systemName: "list.bullet"),
                state: self.viewModel.viewModeOption == .list ? .on : .off
            ) { _ in
                self.viewModel.viewModeOption = .list
            }
            
            let sortByDateAction = UIAction(title: "library_menu_recent_button".localized, state: self.viewModel.sortOption == .recent ? .on : .off) { _ in
                self.viewModel.sortOption = .recent
            }
            
            let sortByTitleAction = UIAction(title: "library_menu_Title_button".localized, state: self.viewModel.sortOption == .title ? .on : .off) { _ in
                self.viewModel.sortOption = .title
            }
            
            let sortByAuthorAction = UIAction(title: "library_menu_Author_button".localized, state: self.viewModel.sortOption == .author ? .on : .off) { _ in
                self.viewModel.sortOption = .author
            }
            
            let viewModeMenu = UIMenu(options: .displayInline, children: [
                switchToGridAction,
                switchToListAction
            ])
            
            let sortMenu = UIMenu(title: "library_menu_sort_by_button".localized, options: .displayInline, children: [
                sortByDateAction,
                sortByTitleAction,
                sortByAuthorAction
            ])
            
            return [selectAction, viewModeMenu, sortMenu]
        }
    }
}
