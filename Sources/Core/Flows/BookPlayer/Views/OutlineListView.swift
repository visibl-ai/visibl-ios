//
//  OutlineListView.swift
//  visibl
//
//

import Combine
import ReadiumShared
import SwiftUI

struct OutlineListView: View {
    private let publication: Publication
    @ObservedObject private var bookmarksModel: BookmarksViewModel
    @State private var selectedSection: OutlineSection = .tableOfContents
    private let onLocatorSelected: (Locator) -> Void

    // Outlines (list of links) to display for each section.
    private var outlines: [OutlineSection: [(level: Int, link: ReadiumShared.Link)]] = [:]

    init(publication: Publication, bookId: Book.Id, bookmarkRepository: BookmarkRepository, onLocatorSelected: @escaping (Locator) -> Void) {
        self.publication = publication
        self.onLocatorSelected = onLocatorSelected
        bookmarksModel = BookmarksViewModel(bookId: bookId, repository: bookmarkRepository)

        func flatten(_ links: [ReadiumShared.Link], level: Int = 0) -> [(level: Int, link: ReadiumShared.Link)] {
            links.flatMap { [(level, $0)] + flatten($0.children, level: level + 1) }
        }

        outlines = [
            .tableOfContents: flatten(
                !publication.tableOfContents.isEmpty
                    ? publication.tableOfContents
                    : publication.readingOrder
            ),
            .landmarks: flatten(publication.landmarks),
            .pageList: flatten(publication.pageList),
        ]
    }

    var body: some View {
        VStack {
//            OutlineTablePicker(selectedSection: $selectedSection)

            switch selectedSection {
            case .tableOfContents, .pageList, .landmarks:
                if let outline = outlines[selectedSection] {
                    List(outline.indices, id: \.self) { index in
                        let item = outline[index]
                        Text(String(repeating: "  ", count: item.level) + (item.link.title ?? item.link.href))
                            .font(.system(size: 14, weight: .regular))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if let locator = publication.locate(item.link) {
                                    onLocatorSelected(locator)
                                }
                            }
                    }
                } else {
                    preconditionFailure("Outline \(selectedSection) can't be nil!")
                }

            case .bookmarks:
                List(bookmarksModel.bookmarks, id: \.self) { bookmark in
                    BookmarkCellView(bookmark: bookmark)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onLocatorSelected(bookmark.locator)
                        }
                }
                .onAppear { bookmarksModel.loadIfNeeded() }
            case .highlights:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
