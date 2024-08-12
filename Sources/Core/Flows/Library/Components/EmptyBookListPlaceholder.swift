//
//  EmptyBookListPlaceholder.swift
//  visibl
//
//

import SwiftUI

struct EmptyBookListPlaceholder: View {
    @Environment(\.colorScheme) var colorScheme
    var openStore: () -> Void
    
    var body: some View {
        VStack (spacing: 18) {
            VStack (spacing: 8) {
                Text("library_call_to_action_title".localized)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                
                Text("library_call_to_action_desc".localized)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            Button(action: openStore) {
                HStack (spacing: 12) {
                    Image(systemName: "bag")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                    Text("Open Book Store")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(colorScheme == .dark ? Color(UIColor.systemGray6) : .black)
                .cornerRadius(12)
            }
        }
    }
}
