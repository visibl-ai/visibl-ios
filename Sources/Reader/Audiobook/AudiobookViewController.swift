//
//  Copyright 2024 Readium Foundation. All rights reserved.
//  Use of this source code is governed by the BSD-style license
//  available in the top-level LICENSE file of the project.
//

import Combine
import Foundation
import MediaPlayer
import ReadiumNavigator
import ReadiumShared
import SwiftUI
import UIKit

class AudiobookViewController: ReaderViewController<AudioNavigator>, AudioNavigatorDelegate {
    private let model: AudiobookViewModel
    private let preferencesStore: AnyUserPreferencesStore<AudioPreferences>
    var cancellable = Set<AnyCancellable>()

    init(
        publication: Publication,
        locator: Locator?,
        bookId: Book.Id,
        books: BookRepository,
        bookmarks: BookmarkRepository,
        initialPreferences: AudioPreferences,
        preferencesStore: AnyUserPreferencesStore<AudioPreferences>
    ) {
        self.preferencesStore = preferencesStore

        let navigator = AudioNavigator(
            publication: publication,
            initialLocation: locator,
            config: AudioNavigator.Configuration(
                preferences: initialPreferences
            )
        )

        model = AudiobookViewModel(
            navigator: navigator
        )

        super.init(
            navigator: navigator,
            publication: publication,
            bookId: bookId,
            books: books,
            bookmarks: bookmarks
        )

        navigator.delegate = self
    }

    private lazy var readerController =
        UIHostingController(rootView: AudiobookReader(model: model))

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        addChild(readerController)
        view.addSubview(readerController.view)
        readerController.view.frame = view.bounds
        readerController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        readerController.didMove(toParent: self)

        navigator.play()
        setupNowPlaying()
        setupCommandCenterControls()
        
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigator.pause()
        clearNowPlaying()
    }
    
    private func bind() {
        model.eventSender.sink(receiveValue: { [unowned self] event in
            switch event {
            case .bookmarkCurrentPosition:
                self.bookmarkCurrentPosition()
            case .presentUserPreferences:
                self.presentUserPreferences()
            case .presentOutline:
                self.presentOutline()
            case .popViewController:
                self.navigationController?.popViewController(animated: true)
            }
        }).store(in: &cancellable)
    }

    override func presentUserPreferences() {
        Task {
            let userPrefs = await UserPreferences(
                model: UserPreferencesViewModel(
                    bookId: bookId,
                    preferences: try! preferencesStore.preferences(for: bookId),
                    configurable: navigator,
                    store: preferencesStore
                ),
                onClose: { [weak self] in
                    self?.dismiss(animated: true)
                }
            )
            let vc = UIHostingController(rootView: userPrefs)
            vc.modalPresentationStyle = .formSheet
            present(vc, animated: true)
        }
    }

    // MARK: - AudioNavigatorDelegate

    func navigator(_ navigator: AudioNavigator, playbackDidChange info: MediaPlaybackInfo) {
        model.onPlaybackChanged(info: info)

        updateNowPlaying(info: info)
        updateCommandCenterControls()
    }

    // MARK: - Command Center controls

    private func setupCommandCenterControls() {
        DispatchQueue.global(qos: .userInitiated).async {
            let title = self.publication.metadata.title ?? "No title"
            let artist = self.publication.metadata.authors.map(\.name).joined(separator: ", ")
            let cover = self.publication.cover

            DispatchQueue.main.async {
                NowPlayingInfo.shared.media = .init(
                    title: title,
                    artist: artist,
                    artwork: cover
                )
            }
        }

        let rcc = MPRemoteCommandCenter.shared()

        func on(_ command: MPRemoteCommand, _ block: @escaping (AudioNavigator, MPRemoteCommandEvent) -> Void) {
            command.addTarget { [weak self] event in
                guard let self = self else {
                    return .noActionableNowPlayingItem
                }
                block(self.navigator, event)
                return .success
            }
        }

        on(rcc.playCommand) { navigator, _ in
            navigator.play()
        }

        on(rcc.pauseCommand) { navigator, _ in
            navigator.pause()
        }

        on(rcc.togglePlayPauseCommand) { navigator, _ in
            navigator.playPause()
        }

        on(rcc.previousTrackCommand) { navigator, _ in
            navigator.goBackward()
        }

        on(rcc.nextTrackCommand) { navigator, _ in
            navigator.goForward()
        }

        rcc.skipBackwardCommand.preferredIntervals = [10]
        on(rcc.skipBackwardCommand) { navigator, _ in
            navigator.seek(by: -10)
        }

        rcc.skipForwardCommand.preferredIntervals = [30]
        on(rcc.skipForwardCommand) { navigator, _ in
            navigator.seek(by: +30)
        }

        on(rcc.changePlaybackPositionCommand) { navigator, event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return
            }
            navigator.seek(to: event.positionTime)
        }
    }

    private func updateCommandCenterControls() {
        let rcc = MPRemoteCommandCenter.shared()
        rcc.previousTrackCommand.isEnabled = navigator.canGoBackward
        rcc.nextTrackCommand.isEnabled = navigator.canGoForward
    }

    // MARK: - Now Playing metadata

    private func setupNowPlaying() {
        let nowPlaying = NowPlayingInfo.shared

        // Initial publication metadata.
        nowPlaying.media = NowPlayingInfo.Media(
            title: publication.metadata.title ?? "",
            artist: publication.metadata.authors.map(\.name).joined(separator: ", "),
            chapterCount: publication.readingOrder.count
        )

        // Update the artwork after the view model loaded it.
        model.$cover
            .sink { cover in
                nowPlaying.media?.artwork = cover
            }
            .store(in: &subscriptions)
    }

    private func updateNowPlaying(info: MediaPlaybackInfo) {
        let nowPlaying = NowPlayingInfo.shared

        nowPlaying.playback = NowPlayingInfo.Playback(
            duration: info.duration,
            elapsedTime: info.time,
            rate: navigator.settings.speed
        )

        nowPlaying.media?.chapterNumber = info.resourceIndex
        
        model.chapterName = model.navigator.publication.readingOrder[nowPlaying.media?.chapterNumber ?? 1].title ?? "Loading"
    }

    private func clearNowPlaying() {
        NowPlayingInfo.shared.clear()
    }
}
