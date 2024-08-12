//
//  CollectionsView.swift
//  visibl
//
//

import SwiftUI

struct CollectionsView: View {
    @ObservedObject var viewModel: CollectionsViewModel
    @ObservedObject var collectionsManager: CollectionsManager
    
    var body: some View {
        ZStack {
            VStack {
                List {
                    ForEach(collectionsManager.collections) { collection in
                        HStack {
                            Text(collection.title)
                                .font(.system(size: 15, weight: .medium))
                            Spacer()
                            Text(String(collection.booksIDs.count))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.gray)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .onAppear {
                            print("\(collection.title) collection appeared, number of books: \(collection.booksIDs.count)")
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}
