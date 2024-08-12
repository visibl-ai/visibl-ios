//
//  AuthService.swift
//  visibl
//
//

import Foundation
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import Combine

struct CurrentUserModel {
    let email: String
    let name: String
    let photoURL: String
}

enum AuthError: LocalizedError {
    case passwordMismatch
    
    var errorDescription: String? {
        switch self {
        case .passwordMismatch:
            return NSLocalizedString("Passwords do not match", comment: "Error when passwords don't match during registration")
        }
    }
}

final class AuthService {
    static let shared = AuthService()
    
    @Published var user: CurrentUserModel?
    
    init() {
        Task {
            let user = await setupCurrentUser()
            await MainActor.run { self.user = user }
        }
    }
}

// MARK: - Access Data

extension AuthService {
    func setupCurrentUser() async -> CurrentUserModel? {
        do {
            guard let currentUser = Auth.auth().currentUser else {
                throw NSError(
                    domain: "AuthenticationService",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "No current user available"]
                )
            }
                        
            let email = currentUser.email ?? ""
            let name = currentUser.displayName ?? ""
            let photoURL = currentUser.photoURL?.absoluteString ?? ""
            
            return CurrentUserModel(email: email, name: name, photoURL: photoURL)
        } catch {
            print("Error retrieving access data: \(error)")
            return nil
        }
    }
}

// MARK: - Google Sign In

extension AuthService {
    func loginWithCredential(with credential: AuthCredential) async throws {
        try await Auth.auth().signIn(with: credential)
        let user = await setupCurrentUser()
        await MainActor.run { self.user = user }
    }
}

// MARK: - Log in

extension AuthService {
    public func login(email: String, password: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    print("Login error: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                Task {
                    let user = await self.setupCurrentUser()
                    await MainActor.run { self.user = user }
                }
                continuation.resume()
            }
        }
    }
}

// MARK: - Register

extension AuthService {
    public func register(email: String, password: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    print("Registration error: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                Task {
                    let user = await self.setupCurrentUser()
                    await MainActor.run { self.user = user }
                }
                continuation.resume()
            }
        }
    }
}

// MARK: - Sign Out

extension AuthService {
    public func signOut() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try Auth.auth().signOut()
                Task { await MainActor.run { self.user = nil } }
                continuation.resume()
            } catch let signOutError as NSError {
                print("Error signing out: \(signOutError.localizedDescription)")
                continuation.resume(throwing: signOutError)
            }
        }
    }
}
