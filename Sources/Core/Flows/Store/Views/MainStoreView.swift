//
//  MainStoreView.swift
//  visibl
//
//

import SwiftUI
import ReadiumShared
import ReadiumOPDS

struct MainStoreView: View {
    @ObservedObject var storeViewModel: StoreViewModel
    @ObservedObject var privateFeedViewModel: PrivateFeedViewModel
    var gridItemLayout = Array(repeating: GridItem(.flexible(), spacing: 20), count: 2)
    
    @State private var isTransitioning = false
    
    var body: some View {
        Group {
            if storeViewModel.isLoading && storeViewModel.feed == nil {
                SkeletonView()
                    .onDisappear {
                        withAnimation(.easeOut(duration: 0.5)) {
                            isTransitioning = true
                        }
                    }
            } else if let errorMessage = storeViewModel.errorMessage {
                Text(errorMessage)
            } else {
                ScrollView {
                    if privateFeedViewModel.axxUser != nil {
                        segmentedControl
                    }
                    selectedFeedView
                }
            }
        }
    }
    
    // MARK: - Segmented Control for Library Source
    
    private var segmentedControl: some View {
        VStack {
            Picker("", selection: $storeViewModel.selectedBookSource) {
                Text("Visibl Store").tag(0)
                Text(privateFeedViewModel.axxUser?.source ?? "Import").tag(1)
            }
            .pickerStyle(.segmented)
        }
        .padding(EdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 14))
    }
    
    // MARK: - Selected Feed View
    
    @ViewBuilder
    private var selectedFeedView: some View {
        if storeViewModel.selectedBookSource == 0 {
            if let feed = storeViewModel.feed {
                makeStore(feed: feed, viewModel: storeViewModel)
            } else {
                Text("No content available")
            }
        } else {
            if let feed = privateFeedViewModel.feed {
                makeStore(feed: feed, viewModel: privateFeedViewModel)
            } else {
                Text("No private content available")
            }
        }
    }
    
    // MARK: - Main Library View
    
    private func makeStore(feed: Feed, viewModel: any ObservableObject) -> some View {
        LazyVGrid(columns: gridItemLayout, spacing: 12) {
            ForEach(feed.publications, id: \.metadata.identifier) { publication in
                PublicationCell(
                    book: publication,
                    action: {
                        if let storeVM = viewModel as? StoreViewModel {
                            storeVM.selectedBook = publication
                            storeVM.coordinator.navigationSender.send(.openPublication(pub: publication))
                        } else if let privateVM = viewModel as? PrivateFeedViewModel {
                            privateVM.selectedBook = publication
                            privateVM.coordinator.navigationSender.send(.openPublication(pub: publication))
                        }
                    }
                )
            }
        }
        .padding(EdgeInsets(top: 16, leading: 14, bottom: 20, trailing: 14))
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isTransitioning = true
            }
        }
    }
}
