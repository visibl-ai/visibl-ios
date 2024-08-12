//
//  VisualBookPlayer.swift
//  visibl
//
//

import SwiftUI
import Combine

struct VisualBookPlayer: View {
    @ObservedObject var manager: PlayerManager
    @State private var showOutline = false
    @State private var playButtonOpacity: Double = 0
    @State private var showPauseIcon: Bool = false
    @State private var dragOffset: CGFloat = 0
    @GestureState private var isDragging: Bool = false
    @State private var artworkChanged = UUID()
    @State private var showMenuButtons = false
    
    var hidePlayer: () -> Void
    
    var body: some View {
        ZStack {
            makeArtwork()
            
            dragView
            
            // MARK: - Main Content
            
            VStack {
                navBar
                Spacer()
                bottomMenu
            }
        }
        .background(.black)
        .overlay { playButton }
        .gesture(dragGesture)
        .gesture(manager.playback.state == .playing ? dragGesture : nil)
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
    }
    
    // MARK: Drag View
    
    private var dragView: some View {
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
                
                let threshold: CGFloat = 50
                if abs(dragOffset) > threshold {
                    if dragOffset > 0 {
                        manager.navigator.seek(by: -15)
                    } else {
                        manager.navigator.seek(by: 15)
                    }
                }
                dragOffset = 0
            }
    }
    
    // MARK: - NavBar
    
    private var navBar: some View {
        HStack {
            Button(action: {
                hidePlayer()
            }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
            }
            Spacer()
            Text(manager.chapterName ?? "")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .center)
                .onTapGesture {
                    showOutline.toggle()
                }
            Spacer()
            IconButton(systemName: "list.bullet", size: .small) {
                showOutline.toggle()
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
    
    private func makeArtwork() -> some View {
        GeometryReader { geometry in
            if let image = manager.cover {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .animation(.easeInOut(duration: 0.6))
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(2, anchor: .center)
                    .progressViewStyle(.circular)
                    .foregroundStyle(.white)
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Title
    
    private var title: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(manager.bookAuthors ?? "")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(manager.bookName ?? "")
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
                        Text(manager.bookAuthors ?? "")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(manager.bookName ?? "")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    IconButton(
                        systemName: "chevron.up.circle",
                        size: .small
                    ) {
                        print("Show Menu")
                    }
                }
                VStack {
                    if manager.playback.state == .loading {
                        Rectangle()
                            .fill(.gray)
                            .frame(height: 40)
                            .cornerRadius(8)
                            .blinking()
                            .padding(.top, 12)
                    } else {
                        if let duration = manager.playback.duration, duration > 0 {
                            TimeSlider(
                                time: Binding(
                                    get: {
                                        manager.playback.time
                                    },
                                    set: {
                                        manager.navigator.seek(to: $0)
                                    }
                                ),
                                duration: duration,
                                nextAction: {
                                    manager.navigator.goForward()
                                },
                                previousAction: {
                                    manager.navigator.goBackward()
                                }
                            )
                        }
                    }
                }
                .animation(.easeInOut(duration: 1), value: manager.playback.state)
                
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
                    
                    if manager.playback.state == .paused {
                        showPauseIcon = true
                        manager.navigator.playPause()
                        
                        withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                            playButtonOpacity = 0
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            showPauseIcon = false
                        }
                    } else {
                        showPauseIcon = false
                        manager.navigator.playPause()
                        
                        withAnimation(.easeIn(duration: 0.2)) {
                            playButtonOpacity = 1
                        }
                    }
                }
        }
    }
}
