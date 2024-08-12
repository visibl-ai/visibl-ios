//
//  AAXLoginView.swift
//  visibl
//
//

import SwiftUI
import WebKit

struct AAXLoginView: View {
    @ObservedObject var aaxManager: AAXManager
    @StateObject private var webViewModel = WebViewModel()
    @Environment(\.presentationMode) var presentationMode
    let url: URL
    
    @State private var showLoadingIndicator = false
    
    var body: some View {
        ZStack {
            WebView(viewModel: webViewModel, url: url) { webView in
                handleWebViewNavigation(webView: webView)
            }
            
            VStack {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                    .scaleEffect(2)
                    .padding(.top, 20)
            }
            .opacity(showLoadingIndicator ? 1 : 0)
        }
        .navigationBarTitle("aax_connect_acc_title".localized, displayMode: .inline)
        .navigationBarItems(
            leading: backButton,
            trailing: closeButton
        )
        .navigationBarBackButtonHidden(true)
    }

    private func handleWebViewNavigation(webView: WKWebView) {
        if let url = webView.url?.absoluteString {
            if url.contains("openid.oa2.authorization_code") {
                Task {
                    do {
                        showLoadingIndicator = true
                        try await aaxManager.submitAAXLogin(responseUrl: url)
                        await MainActor.run { aaxManager.eventSender.send(.dismiss) }
                        showLoadingIndicator = false
                    } catch {
                        showLoadingIndicator = false
                        print("Error fetching AAX login URL: \(error.localizedDescription)")
                    }
                }
            } else if url.contains("login_failure") {
                print("Login failed")
            }
        }
    }
    
    private var closeButton: some View {
        Button("close_button".localized) {
            print("Close button tapped")
            aaxManager.eventSender.send(.dismiss)
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
}
