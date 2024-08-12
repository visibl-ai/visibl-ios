//
//  BookGridCell.swift
//  visibl
//
//

import SwiftUI

struct BookGridCell: View {
    let book: Book
    let openBook: () -> Void
    var isEditing: Bool
    var isSelected: Bool = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            AsyncImage(url: book.cover) { phase in
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
                Text(book.title)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                
                Text(book.authors ?? "")
                    .font(.system(size: 13, weight: .regular))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 6)
            .padding(.bottom, 16)
        }
        .overlay(
            Color(UIColor.systemBackground)
                .opacity(isEditing ? 0.5 : 0)
                .cornerRadius(8)
        )
        .overlay {
            VStack {
                HStack {
                    Spacer()
                    if isEditing {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.primary)
                            .background(Color(UIColor.systemBackground).opacity(0.7))
                            .clipShape(Circle())
                            .padding(8)
                    }
                }
                Spacer()
            }
        }
        .onTapGesture {
            openBook()
        }
    }
    
    private var placeholder: some View {
        Rectangle()
            .fill(Color(UIColor.systemGray4))
            .frame(maxWidth: .infinity)
            .frame(height: 170)
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 2)
            .blinking()
    }
}
