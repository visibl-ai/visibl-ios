//
//  RegisterView.swift
//  visibl
//
//

import SwiftUI

struct RegisterView: View {
    @ObservedObject var viewModel: AccountViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            title
            textFields
            AccountActionButton(
                title: "sign_up_button".localized
            ) {
                viewModel.register(email: email, password: password, confirmPassword: confirmPassword)
            }
            divider
            signInWithGoogleButton
            Spacer()
        }
        .navigationBarItems(
            leading: backButton,
            trailing: AccountBarTextButton(
                title: "close_button".localized
            ) {
                viewModel.eventSender.send(.dismiss)
            }
        )
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle("", displayMode: .inline)
    }
    
    private var closeButton: some View {
        Button("close_button".localized) {
            viewModel.eventSender.send(.dismiss)
        }
        .font(.system(size: 15, weight: .semibold))
    }
    
    private var backButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("back_button".localized)
            }
        }
    }
    
    private var divider: some View {
        Divider()
            .background(.gray.opacity(0.5))
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 12)
    }
    
    private var title: some View {
        HStack {
            Text("sign_up_title".localized)
                .font(.system(size: 24, weight: .bold))
            Spacer()
        }
        .padding(.top, 40)
        .padding(.horizontal, 20)
    }
    
    private var signInWithGoogleButton: some View {
        Button(action: {
            viewModel.eventSender.send(.googleSignIn)
        }) {
            HStack {
                Image("google_logo")
                    .resizable()
                    .frame(width: 20, height: 20)
                Text("sign_in_google_button".localized)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(.black)
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
    }
    
    private var textFields: some View {
        VStack {
            EmailTextField(email: $email, placeholder: "email_placeholder".localized)
            Divider()
            PasswordTextField(password: $password, placeholder: "password_placeholder".localized, isNewPassword: true)
            Divider()
            PasswordTextField(password: $confirmPassword, placeholder: "confirm_password_placeholder".localized, isNewPassword: false)
        }
        .rectangleBackground(
            with: .clear,
            backgroundColor: colorScheme == .dark ? .black : Color(uiColor: .systemGray6),
            cornerRadius: 12
        )
        .frame(height: 120)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}
