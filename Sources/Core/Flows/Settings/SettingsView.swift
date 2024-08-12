//
//  SettingsView.swift
//  visibl
//
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var presentDisconnectConfirmAlert = false
    
    var body: some View {
        ScrollView {
            profile
                .onTapGesture {
                    viewModel.eventSender.send(.showAuth)
                }
            aaxConnection
            information
            appVersion
        }
        .alert("aax_disconnect_alert_title".localized, isPresented: $presentDisconnectConfirmAlert) {
            Button("aax_disconnect_alert_confirm_button".localized) {
                viewModel.aaxManager.disconnectAAX()
            }
            Button("aax_disconnect_alert_cancel_button".localized, role: .cancel) {
                presentDisconnectConfirmAlert = false
            }
        } message: {
            Text("aax_disconnect_alert_message".localized)
        }
        
        .onAppear {
            viewModel.aaxManager.getConnectionStatus()
        }
    }
    
    // MARK: - Profile
    
    private var profile: some View {
        HStack{
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 32, height: 32)
                .foregroundColor(.gray)
                .padding(.leading, 12)
                .padding(.trailing, 6)
            if let user = viewModel.user {
                Text(user.email)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
            } else {
                Text("sign_in_call_to_action".localized)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
            }
            Image(systemName: "chevron.right")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 12, height: 12)
                .foregroundColor(.gray)
                .padding(.trailing, 12)
        }
        .rectangleBackground(
            with: .clear,
            backgroundColor: Color(uiColor: UIColor.systemGray6),
            cornerRadius: 12
        )
        .frame(height: 80)
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
    
    // MARK: - Connect External Library
    
    private var aaxConnection: some View {
        VStack(alignment: .leading) {
            HStack {
                Image("AAXlogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .padding()
                    .background(.orange)
                    .frame(width: 28, height: 28)
                    .cornerRadius(6)
                
                if viewModel.axxUser == nil {
                    Text("Connect Your Account")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(.leading, 6)
                    
                    Spacer()
                    
                    Image(systemName: "circle")
                        .foregroundStyle(.gray)
                        .font(.system(size: 16, weight: .regular))
                } else {
                    Text("Connected as \(viewModel.axxUser?.accountOwner ?? "Loading")")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(.leading, 6)
                    
                    Spacer()
                    
                    Image(systemName: "smallcircle.filled.circle")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.green, .gray)
                        .font(.system(size: 16, weight: .medium))
                }
            }
            .padding(.horizontal, 12)
            .onTapGesture {
                if viewModel.axxUser == nil {
                    viewModel.eventSender.send(.showAAXAuth)
                } else {
                    presentDisconnectConfirmAlert = true
                }
            }
        }
        .rectangleBackground(
            with: .clear,
            backgroundColor: Color(uiColor: .systemGray6),
            cornerRadius: 12
        )
        .frame(height: 50)
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }
    
    // MARK: - Information
    
    private var information: some View {
        VStack(alignment: .leading) {
            Spacer()
            IconTextRow(
                iconName: "star.fill",
                iconColor: .green,
                text: "rate_app".localized
            ) {
                print("rate app")
            }
            Spacer()
            Divider().background(.gray.opacity(0.5))
            Spacer()
            IconTextRow(
                iconName: "square.and.arrow.up",
                iconColor: .blue,
                text: "share_with_friends".localized
            ) {
                print("share with friends")
            }
            Spacer()
            Divider().background(.gray.opacity(0.5))
            Spacer()
            IconTextRow(
                iconName: "envelope",
                iconColor: .gray,
                text: "contact_us".localized
            ) {
                print("contact us")
            }
            Spacer()
            
        }
        .rectangleBackground(
            with: .clear,
            backgroundColor: Color(uiColor: .systemGray6),
            cornerRadius: 12
        )
        .frame(height: 150)
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }
    
    // MARK: - App Version
    
    private var appVersion: some View {
        HStack {
            Spacer()
            Text("app_version_title".localized)
                .foregroundColor(.primary)
                .font(.system(size: 13, weight: .regular))
            Text(viewModel.getAppVersion())
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.gray)
            Spacer()
        }
        .frame(height: 50)
    }
}
