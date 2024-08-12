//
//  NowPlayingView.swift
//  visibl
//
//

import UIKit
import SwiftUI
import ReadiumShared
import ReadiumNavigator

struct NowPlayingView: View {
    @ObservedObject var manager: PlayerManager
    var close: () -> Void
    var open: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                artwork()
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(manager.bookName ?? "Title")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    Text(manager.bookAuthors ?? "Authors")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                buttons()
                
                Button(action: {
                    close()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 18)
            Spacer()
        }
        .background(Color(UIColor.systemGray6))
        .frame(height: 60)
        .onTapGesture {
            open()
        }
    }
    
    private func buttons() -> some View {
        HStack (spacing: 16) {
            Button(action: {
                print("seek back for 15 sec")
                manager.navigator.seek(by: -15)
            }) {
                Image(systemName: "gobackward.15")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Button(action: {
                manager.navigator.playPause()
                print("Playback State: \(manager.playback.state)")
            }) {
                Image(systemName: manager.playback.state != .paused ? "pause.fill" : "play.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
    }
    
    private func artwork() -> some View {
        Image(uiImage: manager.cover ?? UIImage())
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 60, height: 60)
            .clipped()
            .cornerRadius(6)
    }
}
