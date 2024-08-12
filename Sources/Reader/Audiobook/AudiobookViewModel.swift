//
//  AudiobookViewModel.swift
//  visibl
//
//

import SwiftUI
import ReadiumNavigator
import Combine

class AudiobookViewModel: ObservableObject {
    enum Events {
        case bookmarkCurrentPosition
        case presentUserPreferences
        case presentOutline
        case popViewController
    }
    
    var cancellables = Set<AnyCancellable>()
    let eventSender = PassthroughSubject<AudiobookViewModel.Events, Never>()
    let artworkManager = ArtworkManager.shared
    
    let navigator: AudioNavigator

    @Published var cover: UIImage?
    @Published var bookAuthors: String = ""
    @Published var bookName: String = ""
    @Published var chapterName: String = ""
    @Published var playback: MediaPlaybackInfo = .init()
    @Published var artworkURL: URL?
    
    init(navigator: AudioNavigator) {
        self.navigator = navigator
        
        Task {
            let tempCover = navigator.publication.cover
            let tempTitle = navigator.publication.metadata.title
            let tempAuthors = navigator.publication.metadata.authors.map(\.name).joined(separator: ", ")
            
            
            await MainActor.run {
                cover = tempCover
                if let title = tempTitle {
                    bookName = title
                }
                
                bookAuthors = tempAuthors
            }
            
            await artworkManager.decodeSceneMap()
        }
    }
}

// MARK: - Playback Control

extension AudiobookViewModel {
    func onPlaybackChanged(info: MediaPlaybackInfo) {
        playback = info
        
        if let imageURL = artworkManager.getArtworkImageURL(forTime: getCurrentPosition()) {
            artworkURL = imageURL
        }
    }
}

// MARK: - Update Cover

extension AudiobookViewModel {
    func updateCover(_ image: Image, in geometry: GeometryProxy) {
        let uiImage = image
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .snapshot()
        self.cover = uiImage
    }
}

// MARK: - Get Current Position in Audiobook

extension AudiobookViewModel {
    func getCurrentPosition() -> Double {
        let readingOrder = navigator.publication.readingOrder
        let currentResourceIndex = playback.resourceIndex
        
        let totalDuration = readingOrder
            .prefix(currentResourceIndex)
            .compactMap { $0.duration }
            .reduce(0, +)
        
        let currentPosition = totalDuration + playback.time
        return currentPosition
    }
}
