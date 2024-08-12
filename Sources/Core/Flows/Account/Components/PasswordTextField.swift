//
//  PasswordTextField.swift
//  visibl
//
//

import SwiftUI

struct PasswordTextField: View {
    @Binding var password: String
    var placeholder: String = "password_placeholder".localized
    var isNewPassword: Bool
    
    var body: some View {
        SecureField(placeholder, text: $password)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 12)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .textContentType(isNewPassword ? .newPassword : .password)
    }
}
