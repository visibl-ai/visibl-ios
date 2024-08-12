//
//  PlayerManager.swift
//  visibl
//
//

import Foundation
import Combine
import ReadiumShared
import ReadiumNavigator
import UIKit
import MediaPlayer
import SwiftUI

final class PlayerManager: ObservableObject, Loggable {
    let navigator: AudioNavigator
    let publication: Publication
    let bookId: Book.Id
    
    let books: BookRepository
    let bookmarks: BookmarkRepository
    let preferencesStore: AnyUserPreferencesStore<AudioPreferences>
    
    var subscriptions = Set<AnyCancellable>()
    
    let artworkManager = ArtworkManager.shared
    
    // MARK: - Published properties
    @Published var cover: UIImage?
    @Published var initialCover: UIImage?
    @Published var bookName: String?
    @Published var chapterName: String?
    @Published var playback: MediaPlaybackInfo = .init()
    @Published var bookAuthors: String?
    
    @Published var artworkURL: URL?
    
    @Published var currentDate = Date()
    @Published var timerEndDate: Date?
    
    private var timeUpdater: AnyCancellable?
    
    // MARK: - Events
    enum Events {
        case bookmarkCurrentPosition
        case presentUserPreferences
        case presentOutline
    }
    
    let eventSender = PassthroughSubject<Events, Never>()
    
    @Published var userPreferencesViewModel: UserPreferencesViewModel<AudioNavigator.Settings, AudioPreferences, AudioPreferencesEditor>?
    
    init(
        publication: Publication,
        bookId: Book.Id,
        books: BookRepository,
        bookmarks: BookmarkRepository,
        navigator: AudioNavigator,
        preferencesStore: AnyUserPreferencesStore<AudioPreferences>
    ) {
        self.preferencesStore = preferencesStore
        self.publication = publication
        self.bookId = bookId
        self.books = books
        self.bookmarks = bookmarks
        self.navigator = navigator
        
        artworkManager.downloadedScene = 0
        
        navigator.delegate = self
        
        loadBookMetadata()
        setupNowPlaying()
        setupCommandCenterControls()
        navigator.play()
    }
    
    private func loadBookMetadata() {
        cover = navigator.publication.cover
        initialCover = navigator.publication.cover
        bookName = navigator.publication.metadata.title
        bookAuthors = navigator.publication.metadata.authors.map(\.name).joined(separator: ", ")
    }
    
    // MARK: - Playback Control Methods
    
    func play() {
        navigator.play()
    }
    
    func pause() {
        navigator.pause()
    }
    
    func playPause() {
        navigator.playPause()
    }
    
    func seekForward(by interval: TimeInterval = 15) {
        navigator.seek(by: interval)
    }
    
    func seekBackward(by interval: TimeInterval = 15) {
        navigator.seek(by: -interval)
    }
    
    // MARK: - Now Playing
    
    private func setupNowPlaying() {
        let nowPlaying = NowPlayingInfo.shared
        
        nowPlaying.media = NowPlayingInfo.Media(
            title: publication.metadata.title ?? "",
            artist: publication.metadata.authors.map(\.name).joined(separator: ", "),
            chapterCount: publication.readingOrder.count
        )
        
        $cover
            .sink { cover in
                nowPlaying.media?.artwork = cover
            }
            .store(in: &subscriptions)
    }
    
    func updateNowPlaying(info: MediaPlaybackInfo) {
        let nowPlaying = NowPlayingInfo.shared
        
        nowPlaying.playback = NowPlayingInfo.Playback(
            duration: info.duration,
            elapsedTime: info.time,
            rate: navigator.settings.speed
        )
        
        nowPlaying.media?.chapterNumber = info.resourceIndex
        
        chapterName = navigator.publication.readingOrder[nowPlaying.media?.chapterNumber ?? 1].title ?? "Loading"
    }
    
    func clearNowPlaying() {
        NowPlayingInfo.shared.clear()
    }
    
    // MARK: - Command Center Controls
    
    private func setupCommandCenterControls() {
        let rcc = MPRemoteCommandCenter.shared()
        
        func on(_ command: MPRemoteCommand, _ block: @escaping (MPRemoteCommandEvent) -> Void) {
            command.addTarget { [weak self] event in
                guard self != nil else {
                    return .noActionableNowPlayingItem
                }
                block(event)
                return .success
            }
        }
        
        on(rcc.playCommand) { [weak self] _ in
            self?.play()
        }
        
        on(rcc.pauseCommand) { [weak self] _ in
            self?.pause()
        }
        
        on(rcc.togglePlayPauseCommand) { [weak self] _ in
            self?.playPause()
        }
        
        on(rcc.previousTrackCommand) { [weak self] _ in
            self?.navigator.goBackward()
        }
        
        on(rcc.nextTrackCommand) { [weak self] _ in
            self?.navigator.goForward()
        }
        
        rcc.skipBackwardCommand.preferredIntervals = [10]
        on(rcc.skipBackwardCommand) { [weak self] _ in
            self?.seekBackward(by: 10)
        }
        
        rcc.skipForwardCommand.preferredIntervals = [30]
        on(rcc.skipForwardCommand) { [weak self] _ in
            self?.seekForward(by: 30)
        }
        
        on(rcc.changePlaybackPositionCommand) { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return
            }
            self?.navigator.seek(to: event.positionTime)
        }
    }
    
    private func updateCommandCenterControls() {
        let rcc = MPRemoteCommandCenter.shared()
        rcc.previousTrackCommand.isEnabled = navigator.canGoBackward
        rcc.nextTrackCommand.isEnabled = navigator.canGoForward
    }
    
    // MARK: - Sleep Timer Methods
    func startCurrentTimeUpdater() {
        timeUpdater = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.currentDate = Date()
                self?.checkTimerEndDate()
            }
    }
    
    func setSleepTimer(for duration: TimeInterval) {
        timerEndDate = Date().addingTimeInterval(duration)
        startCurrentTimeUpdater()
    }
    
    private func checkTimerEndDate() {
        if let timerEndDate = timerEndDate, currentDate >= timerEndDate {
            stopPlayback()
            self.timerEndDate = nil
        }
    }
    
    private func stopPlayback() {
        DispatchQueue.main.async {
            self.pause()
        }
    }
    
    func cancelSleepTimer() {
        timerEndDate = nil
        timeUpdater?.cancel()
    }
    
    func goToLocator(_ locator: Locator) {
        navigator.go(to: locator, animated: false)
    }
    
    func loadUserPreferences() {
        Task {
            do {
                let preferences = try await preferencesStore.preferences(for: bookId)
                await MainActor.run {
                    userPreferencesViewModel = UserPreferencesViewModel(
                        bookId: bookId,
                        preferences: preferences,
                        configurable: navigator,
                        store: preferencesStore
                    )
                }
            } catch {
                print("Error loading preferences: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - NavigatorDelegate

extension PlayerManager: NavigatorDelegate {
    func navigator(_ navigator: any ReadiumNavigator.Navigator, didFailToLoadResourceAt href: ReadiumShared.RelativeURL, withError error: ReadiumShared.ResourceError) {
        print("Failed to load resource at \(href): \(error)")
    }
    
    func navigator(_ navigator: Navigator, locationDidChange locator: Locator) {
        Task {
            do {
                try await books.saveProgress(for: bookId, locator: locator)
            } catch {
                print(error)
            }
        }
    }
    
    func navigator(_ navigator: Navigator, didJumpTo locator: Locator) {}
    
    func navigator(_ navigator: Navigator, presentError error: NavigatorError) {
        print("Navigator error: \(error)")
    }
    
    func navigator(_ navigator: Navigator, presentExternalURL url: URL) {}
    
    func navigator(_ navigator: Navigator, shouldNavigateToNoteAt link: ReadiumShared.Link, content: String, referrer: String?) -> Bool {
        return true
    }
    
    func navigator(_ navigator: Navigator, didFailToLoadResourceAt href: String, withError error: ResourceError) {
        print("Failed to load resource at \(href): \(error)")
    }
}

// MARK: - AudioNavigatorDelegate

extension PlayerManager: AudioNavigatorDelegate {
    func navigator(_ navigator: AudioNavigator, playbackDidChange info: MediaPlaybackInfo) {
        DispatchQueue.main.async {
            self.playback = info
            self.updateNowPlaying(info: info)
            self.updateCommandCenterControls()
            
            Task { @MainActor in
                await self.loadBookArtworks(currentChapter: info.resourceIndex)
                await self.updateArtwork(currentChapter: info.resourceIndex)
            }
        }
    }
    
    private func loadBookArtworks(currentChapter: Int) async {
        if self.artworkManager.currentChapter != currentChapter {
            Task {
                await MainActor.run {
                    navigator.pause()
                    resetCover()
                    artworkManager.currentSceneMap = []
                    artworkManager.currentChapter = currentChapter
                }
                await artworkManager.decodeSceneMap()
                await MainActor.run { navigator.play() }
            }
        }
    }
    
    private func resetCover() {
        cover = nil
        cover = initialCover
    }
    
    private func updateArtwork(currentChapter: Int) async {
        if self.artworkManager.currentChapter == currentChapter {
            if let image = await self.artworkManager.getArtworkImage(forTime: self.getCurrentPosition()) {
                await MainActor.run {
                    cover = image
                }
            }
        }
    }
    
    func navigator(_ navigator: AudioNavigator, shouldPlayNextResource info: MediaPlaybackInfo) -> Bool {
        return true
    }
    
    func navigator(_ navigator: AudioNavigator, loadedTimeRangesDidChange ranges: [Range<Double>]) {}
}

// MARK: - Get Current Position in Audiobook

extension PlayerManager {
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
