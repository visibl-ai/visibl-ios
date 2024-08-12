//
//  PublicationView.swift
//  visibl
//
//

import SwiftUI
import ReadiumShared

struct PublicationView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: PublicationViewModel
    @State private var imageLoaded = false
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack (spacing: 16) {
                    cover
                    title
                    publicationInfo
                    downloadButton
                    description
                    Spacer(minLength: 100)
                }
            }
        }
        .onAppear {
            viewModel.checkIfBookIsDownloaded(publication: viewModel.publication)
        }
    }
    
    // MARK: - Cover Image
    
    private var cover: some View {
        AsyncImage(url: URL(string: viewModel.publication.images.first?.href ?? "")) { phase in
            switch phase {
            case .empty:
                placeholder
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(16)
                    .frame(maxWidth: .infinity)
                    .frame(height: UIScreen.main.bounds.height * 0.4)
                    .contentShape(Rectangle())
                    .clipShape(Rectangle())
                    .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 2)
                    .padding(.all, 30)
                    .background(
                        image
                            .resizable()
                            .scaledToFill()
                            .blur(radius: 50)
                            .clipped()
                    )
                    .opacity(imageLoaded ? 1 : 0)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.5)) {
                            imageLoaded = true
                        }
                    }
            case .failure:
                placeholder
            @unknown default:
                EmptyView()
            }
        }
        .overlay(
            Group {
                if !imageLoaded {
                    placeholder
                }
            }
        )
    }
    
    // placeholder
    private var placeholder: some View {
        Rectangle()
            .fill(Color(UIColor.systemGray4))
            .frame(maxWidth: .infinity)
            .frame(height: UIScreen.main.bounds.height * 0.4)
            .padding(.all, 30)
            .background(Color(UIColor.systemGray4))
    }
    
    // MARK: - Publication Title and Authors
    
    private var title: some View {
        VStack (alignment: .center, spacing: 12) {
            Text(viewModel.publication.metadata.title ?? "12")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
            Text(viewModel.publication.metadata.authors.first?.name ?? "")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.top, 18)
    }
    
    // MARK: - Publication Info Section
    
    private var publicationInfo: some View {
        HStack (spacing: 18) {
            makePublicationInfo(
                icon: "calendar",
                title: formatDate(viewModel.publication.metadata.published),
                subtitle: "Published"
            )
            makePublicationInfo(
                icon: "clock", 
                title: formatDuration(viewModel.publication.metadata.duration),
                subtitle: "Duration"
            )
            makePublicationInfo(
                icon: "book.closed",
                title: "\(viewModel.publication.tableOfContents.count) Chapters",
                subtitle: "Contents"
            )
        }
        .padding(.horizontal, 30)
        .padding(.top, 18)
    }
    
    @ViewBuilder
    private func makePublicationInfo(icon: String, title: String, subtitle: String) -> some View {
        VStack (spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.primary)
            
            VStack (spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Download Button
    
    private var downloadButton: some View {
        Button {
            print("Download book")
            viewModel.downloadBook(publication: viewModel.publication)
        } label: {
            HStack (spacing: 12) {
                Image(systemName: viewModel.isDownloaded ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                Text(viewModel.isDownloaded ? "Downloaded" : "Get This Book")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                if viewModel.isDownloading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(viewModel.isDownloaded ? Color(UIColor.systemGray4) : colorScheme == .dark ? Color(UIColor.systemGray6) : .black)
            .cornerRadius(12)

        }
        .padding(.top, 20)
        .padding(.horizontal, 20)
        .disabled(viewModel.isDownloading || viewModel.isDownloaded)
    }
    
    // MARK: - Publication Description
    
    private var description: some View {
        Group {
            VStack (alignment: .leading, spacing: 8) {
                Text("About this book")
                    .font(.system(size: 16, weight: .bold))
                    .multilineTextAlignment(.leading)
                Text(viewModel.publication.metadata.description ?? "")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, 18)
        .padding(.horizontal, 20)
    }
}

// MARK: - Helpers

extension PublicationView {
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    func formatDuration(_ duration: Double?) -> String {
        guard let seconds = duration else { return "Unknown" }
        
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        if hours == 0 {
            return "\(minutes) min"
        } else if minutes == 0 {
            return "\(hours) h"
        } else {
            return "\(hours) h \(minutes) min"
        }
    }
}
