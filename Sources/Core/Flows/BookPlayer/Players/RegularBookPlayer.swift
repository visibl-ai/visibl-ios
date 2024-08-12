//
//  RegularBookPlayer.swift
//  visibl
//
//

import SwiftUI

struct RegularBookPlayer: View {
    @ObservedObject var manager: PlayerManager
    @State private var showOutline = false
    @State private var showUserPreferences = false
    @State private var showTimer = false
    @State private var selectedTimerOption: Double = 0.0
    @State private var sheetHeight: CGFloat = .zero
    
    var hidePlayer: () -> Void

    var body: some View {
        VStack {
            navbar
            cover(height: UIScreen.main.bounds.height * 0.4)
            title
//            playbackSlider
            Spacer()
            playbackControlButtons
            Spacer()
            mediaSettingsButtons
        }
        .padding(EdgeInsets(top: 0, leading: 30, bottom: 30, trailing: 30))
        .edgesIgnoringSafeArea(.bottom)
        .sheet(isPresented: $showTimer) {
            ZStack {
                Color(UIColor.systemBackground)
                    .edgesIgnoringSafeArea(.all)
                
                SleepTimerView(manager: manager, showSleepTimerView: $showTimer, selectedTimerOption: $selectedTimerOption)
                    .padding()
                    .fixedSize(horizontal: false, vertical: true)
                    .modifier(GetHeightModifier(height: $sheetHeight))
                    .presentationDetents([.height(sheetHeight)])
            }
        }
        .sheet(isPresented: $showOutline) {
            OutlineListView(
                publication: manager.publication,
                bookId: manager.bookId,
                bookmarkRepository: manager.bookmarks
            ) { locator in
                manager.navigator.go(to: locator, animated: false)
                showOutline = false
            }
        }
        .sheet(isPresented: $showUserPreferences) {
            if let viewModel = manager.userPreferencesViewModel {
                UserPreferences(
                    model: viewModel,
                    onClose: {
                        showUserPreferences = false
                    }
                )
            } else {
                ProgressView()
            }
        }
        .onChange(of: showUserPreferences) { newValue in
            if newValue {
                manager.loadUserPreferences()
            } else {
                manager.userPreferencesViewModel = nil
            }
        }
    }
    
    // MARK: - Navigation Bar
    
    private var navbar: some View {
        HStack {
            Button(action: {
                hidePlayer()
            }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
            }
            Spacer()
            
            if let timerEndDate = manager.timerEndDate, Date() < timerEndDate {
                let timeLeft = Calendar.current.dateComponents([.minute, .second], from: Date(), to: timerEndDate)
                let minutesLeft = timeLeft.minute ?? 0
                let secondsLeft = timeLeft.second ?? 0
                let timeLeftFormatted = String(format: "%02d:%02d", minutesLeft, secondsLeft)
                
                Button(){
                    showTimer = true
                } label: {
                    Text(timeLeftFormatted)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                }
                
            } else {
                if let chapterName = manager.chapterName {
                    Text(chapterName)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            
            Spacer()
            Button(action: {
                //
            }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
        .frame(height: 30)
        .padding(.bottom, 20)
    }
    
    // MARK: - Book Cover
    
    private func cover(height: CGFloat) -> some View {
        Group {
            if let cover = manager.cover {
                Image(uiImage: cover)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: height)
                    .contentShape(Rectangle())
                    .clipShape(Rectangle())
                    .cornerRadius(12)
            } else {
                Color(UIColor.systemGray4)
                    .frame(height: height)
                    .cornerRadius(12)
                    .blinking()
            }
        }
    }
    
    // MARK: - Titles
    
    private var title: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let bookName = manager.bookName {
                Text(bookName)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack {
                    Rectangle()
                        .fill(Color(UIColor.systemGray4))
                        .frame(width: 200, height: 18)
                        .cornerRadius(4)
                        .blinking()
                    Spacer()
                }
            }
            if let bookAuthors = manager.bookAuthors {
                Text(bookAuthors)
                    .font(.system(size: 16, weight: .regular))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack {
                    Rectangle()
                        .fill(Color(UIColor.systemGray4))
                        .frame(width: 140, height: 16)
                        .cornerRadius(4)
                        .blinking()
                    Spacer()
                }
            }
        }
        .padding(.top, 24)
    }
    
    // MARK: - Playback Slider
    
//    private var playbackSlider: some View {
//        Group {
//            if manager.playback.state == .loading {
//                Rectangle()
//                    .fill(Color(UIColor.systemGray5))
//                    .frame(height: 70)
//                    .cornerRadius(8)
//                    .blinking()
//            } else {
//                if let duration = manager.playback.duration, duration > 0 {
//                    TimeSlider(
//                        time: Binding(
//                            get: { manager.playback.time },
//                            set: { manager.navigator.seek(to: $0) }
//                        ),
//                        duration: duration
//                    )
//                } else {
//                    Rectangle()
//                        .fill(Color(UIColor.systemGray5))
//                        .frame(height: 70)
//                        .cornerRadius(8)
//                        .blinking()
//                }
//            }
//        }
//        .padding(.top, 28)
//    }
    
    // MARK: - Playback Control Buttons
    
    private var playbackControlButtons: some View {
        HStack(spacing: 24) {
            Spacer()
            
            // Play the previous resource
            IconButton(systemName: "backward.fill", size: .medium) {
                manager.navigator.goBackward()
            }
            .disabled(!manager.navigator.canGoBackward)
            
            // Skip backward by 10 seconds.
            IconButton(systemName: "gobackward.15", size: .large) {
                manager.navigator.seek(by: -15)
            }
            
            // Toggle play-pause.
            IconButton(
                systemName: manager.playback.state != .paused
                ? "pause.fill"
                : "play.fill",
                size: .extraLarge
            ) {
                manager.navigator.playPause()
            }
            
            // Skip forward by 30 seconds.
            IconButton(systemName: "goforward.15", size: .large) {
                manager.navigator.seek(by: 15)
            }
            
            // Play the next resource.
            IconButton(systemName: "forward.fill", size: .medium) {
                manager.navigator.goForward()
            }
            .disabled(!manager.navigator.canGoForward)
            
            Spacer()
        }
    }
    
    // MARK: - Media Settings Buttons
    
    private var mediaSettingsButtons: some View {
        HStack {
            IconButton(
                systemName: "bookmark",
                size: .small
            ) {
                manager.eventSender.send(.bookmarkCurrentPosition)
            }
            Spacer()
            IconButton(
                systemName: "slider.horizontal.3",
                size: .small
            ) {
                showUserPreferences.toggle()
            }
            Spacer()
            IconButton(
                systemName: "moon.zzz.fill",
                size: .small
            ) {
                showTimer.toggle()
            }
            Spacer()
            IconButton(
                systemName: "list.bullet",
                size: .small
            ) {
                showOutline.toggle()
            }
        }
        .frame(height: 30)
        .padding(.top, 20)
        .padding(.bottom, 20)
    }
}
