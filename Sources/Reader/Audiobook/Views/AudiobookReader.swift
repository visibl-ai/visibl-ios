//
//  AudiobookReader.swift
//  visibl
//
//

import SwiftUI
import Combine

struct AudiobookReader: View {
    @ObservedObject var model: AudiobookViewModel
    @State private var playButtonOpacity: Double = 1
    @State private var showPauseIcon: Bool = false
    @State private var dragOffset: CGFloat = 0
    @GestureState private var isDragging: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                navBar
                Spacer()
                bottomMenu
            }
        }
        .background(
            artwork()
        )
        .background(.black)
        .overlay {
            playButton
        }
        .onAppear {
            if model.playback.state != .playing {
                withAnimation(.easeOut(duration: 1)) {
                    playButtonOpacity = 0
                }
            }
        }
        .gesture(dragGesture)
        .overlay(
            HStack {
                if dragOffset > 0 {
                    HStack(spacing: 12) {
                        Image(systemName: "backward.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, height: 28)
                            .foregroundColor(.white)
                        Text("15")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                Spacer()
                if dragOffset < 0 {
                    HStack(spacing: 12) {
                        Text("15")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        Image(systemName: "forward.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, height: 28)
                            .foregroundColor(.white)
                    }
                }
            }
                .opacity(isDragging ? 1 : 0)
                .animation(.easeOut(duration: 0.2), value: isDragging)
                .padding(.horizontal, 20)
        )
        .gesture(model.playback.state == .playing ? dragGesture : nil)
    }
    
    // MARK: - Drag Gesture
    
    private var dragGesture: some Gesture {
        DragGesture()
            .updating($isDragging) { _, state, _ in
                if !state {
                    let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
                    hapticFeedback.impactOccurred()
                }
                state = true
            }
            .onChanged { value in
                dragOffset = value.translation.width
            }
            .onEnded { value in
                let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
                hapticFeedback.impactOccurred()
                
                let threshold: CGFloat = 50 // Minimum drag distance to trigger action
                if abs(dragOffset) > threshold {
                    if dragOffset > 0 {
                        model.navigator.seek(by: -15)
                    } else {
                        model.navigator.seek(by: 15)
                    }
                }
                dragOffset = 0
            }
    }
    
    // MARK: - NavBar
    
    private var navBar: some View {
        HStack {
            IconButton(systemName: "chevron.left", size: .base) {
                model.eventSender.send(.popViewController)
            }
            Spacer()
            Text(model.chapterName)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .center)
                .onTapGesture {
                    model.eventSender.send(.presentOutline)
                }
            Spacer()
            IconButton(systemName: "slider.horizontal.3", size: .small) {
                model.eventSender.send(.presentUserPreferences)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Line View
    private var line: some View {
        Rectangle()
            .fill(Color(UIColor.systemGray6))
            .frame(width: 40, height: 4)
            .cornerRadius(2)
    }
    
    // MARK: - Artwork
    
    private func artwork() -> some View {
        GeometryReader { geometry in
            Group {
                if let imageURL = model.artworkURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                                .transition(.opacity)
                                .onAppear {
                                    model.updateCover(image, in: geometry)
                                }
                                .onChange(of: image) { newImage in
                                    model.updateCover(newImage, in: geometry)
                                }
                        case .empty, .failure:
                            Rectangle()
                                .fill(.black)
                        @unknown default:
                            Rectangle()
                                .fill(.black)
                        }
                    }
                } else {
                    Image(uiImage: model.cover ?? UIImage())
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                }
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Book Cover
    
    private var cover: some View {
        Group {
            if let cover = model.cover {
                Image(uiImage: cover)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
    }
    
    // MARK: - Title
    
    private var title: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(model.bookAuthors)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(model.bookName)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Playback Slider
    
    private var bottomMenu: some View {
        Group {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    VStack {
                        Text(model.bookAuthors)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(model.bookName)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    IconButton(
                        systemName: "bookmark",
                        size: .small
                    ) {
                        model.eventSender.send(.bookmarkCurrentPosition)
                    }
                }
                if model.playback.state == .loading {
                    ProgressView()
                        .foregroundStyle(.white)
                        .progressViewStyle(.circular)
                } else {
//                    if let duration = model.playback.duration, duration > 0 {
//                        TimeSlider(
//                            time: Binding(
//                                get: {
//                                    model.playback.time
//                                },
//                                set: {
//                                    model.navigator.seek(to: $0)
//                                }
//                            ),
//                            duration: duration
//                        )
//                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.clear, .black]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .ignoresSafeArea(.all, edges: [.top, .bottom])
    }
    
    // MARK: - Play Button
    
    private var playButton: some View {
        ZStack {
            Image(systemName: showPauseIcon ? "pause.fill" : "play.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
                .foregroundColor(.white)
                .opacity(playButtonOpacity)
            
            Rectangle()
                .fill(Color.clear)
                .frame(width: 300, height: 300)
                .contentShape(Rectangle())
                .onTapGesture {
                    let impactHeavy = UIImpactFeedbackGenerator(style: .medium)
                    impactHeavy.impactOccurred()
                    
                    if model.playback.state == .paused {
                        // Transitioning from paused to playing
                        showPauseIcon = true
                        model.navigator.playPause()
                        
                        // Show pause icon briefly, then fade out
                        withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                            playButtonOpacity = 0
                        }
                        
                        // Reset to play icon after animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            showPauseIcon = false
                        }
                    } else {
                        // Transitioning from playing to paused
                        showPauseIcon = false
                        model.navigator.playPause()
                        
                        withAnimation(.easeIn(duration: 0.2)) {
                            playButtonOpacity = 1
                        }
                    }
                }
        }
    }
    
    // MARK: - Playback Control Buttons
    
    private var playbackControlButtons: some View {
        HStack(spacing: 24) {
            Spacer()
            
            // Play the previous resource
            IconButton(systemName: "backward.fill", size: .base) {
                model.navigator.goBackward()
            }
            .disabled(!model.navigator.canGoBackward)
            
            // Play the next resource.
            IconButton(systemName: "forward.fill", size: .base) {
                model.navigator.goForward()
            }
            .disabled(!model.navigator.canGoForward)
            
            Spacer()
        }
        .padding(.bottom, 20)
    }
}
