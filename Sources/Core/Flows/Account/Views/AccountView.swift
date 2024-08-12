//
//  AccountView.swift
//  visibl
//
//

import SwiftUI

struct AccountView: View {
    @ObservedObject var viewModel: AccountViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                profile
                information
                signOut
                    .onTapGesture {
                        viewModel.eventSender.send(.signOut)
                    }
                Spacer()
            }
            .navigationBarItems(
                trailing: AccountBarTextButton(
                    title: "done_button".localized
                ) {
                    viewModel.eventSender.send(.dismiss)
                }
            )
            .navigationBarTitle("account_title".localized, displayMode: .inline)
        }
    }
    
    private var profile: some View {
        HStack{
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 28, height: 28)
                .foregroundColor(.gray)
                .padding(.leading, 12)
            if let user = viewModel.authService.user {
                Text(user.email)
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.leading, 6)
                Spacer()
            } else {
                Text("sign_in_call_to_action".localized)
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.leading, 6)
                Spacer()
                Image(systemName: "chevron.right")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12, height: 12)
                    .foregroundColor(.gray)
                    .padding(.trailing, 12)
            }
        }
        .rectangleBackground(
            with: .clear,
            backgroundColor: colorScheme == .dark ? .black : Color(uiColor: .systemGray6),
            cornerRadius: 12
        )
        .frame(height: 50)
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
    
    private var information: some View {
        VStack(alignment: .leading) {
            Spacer()
            IconTextRow(
                iconName: "lock",
                iconColor: .green,
                text: "privacy_policy".localized
            ) {
                viewModel.openLink(viewModel.privacyPolicyURL)
            }
            Spacer()
            Divider()
                .background(.gray.opacity(0.5))
            Spacer()
            IconTextRow(
                iconName: "doc.plaintext",
                iconColor: .orange,
                text: "terms_of_use".localized
            ) {
                viewModel.openLink(viewModel.termsOfUseURL)
            }
            Spacer()
        }
        .rectangleBackground(
            with: .clear,
            backgroundColor: colorScheme == .dark ? .black : Color(uiColor: .systemGray6),
            cornerRadius: 12
        )
        .frame(height: 100)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var signOut: some View {
        HStack {
            Text("sign_out_button".localized)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.blue)
                .padding(.leading, 12)
            Spacer()
        }
        .rectangleBackground(
            with: .clear,
            backgroundColor: colorScheme == .dark ? .black : Color(uiColor: .systemGray6),
            cornerRadius: 12
        )
        .frame(height: 50)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}
