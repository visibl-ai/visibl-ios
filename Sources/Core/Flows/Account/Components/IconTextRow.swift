//
//  IconTextRow.swift
//  visibl
//
//

import SwiftUI

struct IconTextRow: View {
    let iconName: String
    let iconColor: Color
    let text: String
    var action: (() -> Void)?
    
    var body: some View {
        Button(action: { action?() }) {
            HStack {
                Image(systemName: iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.white)
                    .padding(6)
                    .frame(width: 28, height: 28)
                    .background(iconColor)
                    .cornerRadius(6)
                
                Text(text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(.leading, 6)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12, height: 12)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
