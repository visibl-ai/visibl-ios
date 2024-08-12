//
//  LoginView.swift
//  visibl
//
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AccountViewModel
    @State private var email = ""
    @State private var password = ""
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            VStack {
                title
                textFields
                AccountActionButton(
                    title: "sign_in_button".localized
                ) {
                    viewModel.login(email: email, password: password)
                }
                divider
                signInWithGoogleButton
                dontHaveAccount
                Spacer()
            }
            .navigationBarItems(
                trailing: AccountBarTextButton(
                    title: "close_button".localized
                ) {
                    viewModel.eventSender.send(.dismiss)
                }
            )
            .navigationBarTitle("", displayMode: .inline)
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
            Text("sign_in_title".localized)
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
            PasswordTextField(password: $password, placeholder: "password_placeholder".localized, isNewPassword: false)
        }
        .rectangleBackground(
            with: .clear,
            backgroundColor: colorScheme == .dark ? .black : Color(uiColor: .systemGray6),
            cornerRadius: 12
        )
        .frame(height: 80)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private var dontHaveAccount: some View {
        HStack {
            Text("dont_have_account".localized)
                .font(.system(size: 16, weight: .regular))
            NavigationLink(destination: RegisterView(viewModel: viewModel)) {
                Text("sign_up_button".localized)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 40)
    }
}
