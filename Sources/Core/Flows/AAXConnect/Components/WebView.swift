//
//  WebView.swift
//  visibl
//
//

import SwiftUI
import WebKit

class WebViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var url: URL?
}

struct WebView: UIViewRepresentable {
    @ObservedObject var viewModel: WebViewModel
    let url: URL
    var onContentChange: ((WKWebView) -> Void)?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences = preferences
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard uiView.url == nil else { return }
        let request = URLRequest(url: url)
        uiView.load(request)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.viewModel.url = webView.url
            parent.viewModel.canGoBack = webView.canGoBack
            parent.viewModel.canGoForward = webView.canGoForward
            parent.viewModel.isLoading = false
            
            parent.onContentChange?(webView)
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.viewModel.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.viewModel.isLoading = false
        }
    }
}
