//
//  LibraryView.swift
//  visibl
//
//

import SwiftUI

struct LibraryView: View {
    @ObservedObject var viewModel: LibraryViewModel
    @ObservedObject var collectionsManager: CollectionsManager
    var gridItemLayout = Array(repeating: GridItem(.flexible(), spacing: 20), count: 2)
    @State private var firstLaunch = true
    
    // MARK: - Make UI
    
    var body: some View {
        if firstLaunch {
            ScrollView {
//                collectionsButton
                SkeletonView()
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation {
                        firstLaunch = false
                    }
                }
            }
        } else {
            makeUI()
        }
    }
    
    private func makeUI() -> some View {
        VStack {
            if viewModel.books.isEmpty {
                EmptyBookListPlaceholder(
                    openStore: {
                        viewModel.coordinator.navigationSender.send(.goToCatalog)
                    }
                )
            } else {
                ScrollView {
                    VStack {
//                        collectionsButton
                        if viewModel.viewModeOption == .grid {
                            bookGrid
                        } else {
                            bookList
                        }
                        Color.clear
                            .frame(height: 80)
                    }
                }
            }
        }
    }
    
    // MARK: - Book List
    
    private var bookList: some View {
        LazyVStack (spacing: 12) {
            ForEach(viewModel.books) { book in
                BookListCell(
                    book: book,
                    openBook: { viewModel.eventSender.send(.openBook(book: book)) },
                    menuContent: { makeBookMenu(for: book, compact: true) },
                    isEditing: viewModel.isEditing,
                    isSelected: viewModel.selectedBooks.contains(book)
                )
                .onTapGesture { viewModel.selectBook(book: book) }
                
            }
            .animation(.default, value: viewModel.books)
        }
        .padding(EdgeInsets(top: 16, leading: 14, bottom: 20, trailing: 14))
    }
    
    // MARK: - Book Grid
    
    private var bookGrid: some View {
        LazyVGrid(columns: gridItemLayout, spacing: 12) {
            ForEach(viewModel.books) { book in
                BookGridCell(
                    book: book,
                    openBook: {
                        if !viewModel.isEditing {
                            viewModel.eventSender.send(.openBook(book: book))
                        } else {
                            viewModel.selectBook(book: book)
                        }
                    },
                    isEditing: viewModel.isEditing,
                    isSelected: viewModel.selectedBooks.contains(book)
                )
                .contextMenu { makeMenuContent(book: book) }
            }
            .animation(.default, value: viewModel.books)
        }
        .padding(EdgeInsets(top: 16, leading: 14, bottom: 20, trailing: 14))
    }
}

// MARK: - Book Menu

extension LibraryView {
    private func makeBookMenu(for book: Book, compact: Bool = false) -> some View {
        Menu {
            makeMenuContent(book: book)
        } label: {
            Group {
                if compact {
                    Image(systemName: "ellipsis")
                        .foregroundColor(Color(UIColor.label))
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(Color(UIColor.label))
                        .frame(width: 32, height: 32)
                }
            }
        }
    }
}

// MARK: - Menu Content

extension LibraryView {
    private func makeMenuContent(book: Book) -> some View {
        Group {
            Button(action: {
                print("Set book style") //
            }) {
                Label("book_menu_visibl_style_button".localized, systemImage: "theatermask.and.paintbrush")
            }
            Divider()
            Button(action: {
                print("Add book to collection") //
                collectionsManager.addToFavorites(book)
            }) {
                Label("Add To Favorites".localized, systemImage: "heart")
            }
            Button(action: {
                print("Add book to collection") //
            }) {
                Label("book_menu_add_to_collection_button".localized, systemImage: "text.badge.plus")
            }
            Button(action: {
                print("Add book to collection")
                collectionsManager.addToHidden(book)
            }) {
                Label("book_menu_make_hidden".localized, systemImage: "eye.slash")
            }
            Button(action: {
                print("View book in store")
            }) {
                Label("book_menu_view_in_store_button".localized, systemImage: "bag")
            }
            Divider()
            Button(role: .destructive, action: {
                withAnimation(.easeInOut(duration: 0.3)) { viewModel.eventSender.send(.deleteBook(book: book)) }
            }) {
                Label("book_menu_remove_book_button".localized, systemImage: "trash")
            }
        }
    }
}

// MARK: - Collections Button

extension LibraryView {
    private var collectionsButton: some View {
        Button(action: {
            viewModel.coordinator.navigationSender.send(.openCollections)
        }, label: {
            VStack {
                Divider()
                HStack {
                    Image(systemName: "text.justify.leading")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                    Text("collections_button".localized)
                        .foregroundColor(Color(UIColor.label))
                        .font(.system(size: 16, weight: .regular))
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.forward")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 3)
                Divider()
            }
            .padding(.top, 6)
            .padding(.horizontal, 14)
        })
    }
}
