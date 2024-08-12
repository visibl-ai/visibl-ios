//
//  AccountBarTextButton.swift
//  visibl
//
//

import SwiftUI

struct AccountBarTextButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(title, action: action)
            .font(.system(size: 15, weight: .semibold))
    }
}
