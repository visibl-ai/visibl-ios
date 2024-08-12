//
//  PublicationCell.swift
//  visibl
//
//

import SwiftUI
import ReadiumShared

struct PublicationCell: View {
    let book: Publication
    var action: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            AsyncImage(url: URL(string: book.images.first?.href ?? "")) { phase in
                switch phase {
                case .empty:
                    placeholder
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(height: 170)
                        .cornerRadius(8)
                        .contentShape(Rectangle())
                        .clipShape(Rectangle())
                        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 2)
                case .failure:
                    placeholder
                @unknown default:
                    EmptyView()
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(book.metadata.title ?? "")
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)

                Text(authorsString)
                    .font(.system(size: 13, weight: .regular))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 6)
            .padding(.bottom, 16)
        }
        .frame(width: 170)
        .onTapGesture {
            action?()
        }
    }
    
    // MARK: - Autor String
    
    private var authorsString: String {
        book.metadata.authors
            .map { $0.name }
            .joined(separator: ", ")
    }
    
    // MARK: - Placeholder
    
    private var placeholder: some View {
        Rectangle()
            .fill(Color(UIColor.systemGray4))
            .frame(maxWidth: .infinity)
            .frame(width: 170, height: 170)
            .cornerRadius(8)
            .blinking()
    }
}
