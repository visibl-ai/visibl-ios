//
//  BookListCell.swift
//  visibl
//
//

import SwiftUI

struct BookListCell: View {
    let book: Book
    let openBook: () -> Void
    let menuContent: () -> any View
    var isEditing: Bool
    var isSelected: Bool = false

    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 14) {
                if isEditing {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.primary)
                        .background(Color(UIColor.systemBackground).opacity(0.7))
                        .clipShape(Circle())
                        .padding(8)
                }
                
                AsyncImage(url: book.cover) { phase in
                    switch phase {
                    case .empty:
                        placeholder
                    case .success(let image):
                        ZStack {
                            image
                                .resizable()
                                .scaledToFill()
                        }
                        .frame(width: 80, height: 70)
                        .cornerRadius(6)
                        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 2)
                    case .failure:
                        placeholder
                    @unknown default:
                        EmptyView()
                    }
                }
                .onTapGesture {
                    if !isEditing { openBook() }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(book.title)
                        .font(.system(size: 15, weight: .medium))
                        .lineLimit(2)
                    Text(book.authors ?? "")
                        .font(.system(size: 13, weight: .regular))
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 6)
                
                AnyView(menuContent())
            }
            .padding(.all, 12)
            
        }
        .background(Color(UIColor.systemGray6))
    }
    
    private var placeholder: some View {
        Rectangle()
            .fill(Color(UIColor.systemGray4))
            .frame(maxWidth: .infinity)
            .frame(width: 80, height: 70)
            .cornerRadius(6)
            .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 2)
            .blinking()
    }
}
