//
//  EmailTextField.swift
//  visibl
//
//

import SwiftUI

struct EmailTextField: View {
    @Binding var email: String
    var placeholder: String = "email_placeholder".localized
    
    var body: some View {
        TextField(placeholder, text: $email)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 12)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
    }
}
