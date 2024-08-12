//
//  AccountViewModel.swift
//  visibl
//
//

import Foundation
import SwiftUI
import Combine
import GoogleSignIn
import FirebaseAuth

enum AuthState {
    case auth
    case account
}

final class AccountViewModel: ObservableObject {
    var authService: AuthService
    @Published var state: AuthState?
    let privacyPolicyURL = URL(string: "https://google.com")!
    let termsOfUseURL = URL(string: "https://google.com")!
    
    enum Events {
        case authSuccess
        case authError(error: Error)
        case signOut
        case dismiss
        case googleSignIn
    }
    
    var cancellables = Set<AnyCancellable>()
    let eventSender = PassthroughSubject<AccountViewModel.Events, Never>()
    
    init(authService: AuthService) {
        self.authService = authService
        
        if authService.user != nil {
            self.state = .account
        } else {
            self.state = .auth
        }
    }
    
    // Helpers
    
    func arePasswordsMatching(_ p1: String, _ p2: String) -> Bool {
        return p1 == p2
    }
    
    func openLink(_ url: URL) {
        UIApplication.shared.open(url)
    }
}

// MARK: - Auth methods

extension AccountViewModel {
    func loginWithGoogle(_ signInResult: GIDSignInResult) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                guard let idToken = signInResult.user.idToken?.tokenString else {
                    throw NSError(domain: "GoogleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "No ID token"])
                }
                
                let accessToken = signInResult.user.accessToken.tokenString
                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
                
                try await self.authService.loginWithCredential(with: credential)
                self.eventSender.send(.authSuccess)
            } catch {
                self.eventSender.send(.authError(error: error))
            }
        }
    }
    
    func login(email: String, password: String) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await self.authService.login(email: email, password: password)
                self.eventSender.send(.authSuccess)
            } catch {
                self.eventSender.send(.authError(error: error))
            }
        }
    }
    
    func register(email: String, password: String, confirmPassword: String) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            
            if !arePasswordsMatching(password, confirmPassword) {
                return self.eventSender.send(.authError(error: AuthError.passwordMismatch))
            }
            
            do {
                try await self.authService.register(email: email, password: password)
                self.eventSender.send(.authSuccess)
            } catch {
                self.eventSender.send(.authError(error: error))
            }
        }
    }
    
    func signOut() {
        Task {
            try await authService.signOut()
        }
    }
}
