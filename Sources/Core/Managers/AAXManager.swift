//
//  AAXManager.swift
//  visibl
//
//

import Foundation
import Combine

// MARK: - AAX Responses

struct AAXLoginURLResponse: Codable {
    var codeVerifier: String
    var loginUrl: URL
    var serial: String
}

struct AAXDisconnectResponse: Codable {
    var deletedCount: Int
}

// MARK: - AAX Models

struct AAXCountryModel: Codable, Identifiable {
    var id: String
    var flag: String
    var name: String
    var code: String
}

struct AAXUserModel: Codable {
    var connected: Bool
    var source: String
    var accountOwner: String
}

// MARK: - AAX Manager

class AAXManager: ObservableObject {
    @Published var axxUser: AAXUserModel?
    
    var cancellables = Set<AnyCancellable>()
    let eventSender = PassthroughSubject<AAXManager.Events, Never>()
    
    @Published var selectedCountryCode: String = "uk"
    @Published var codeVerifier: String = ""
    @Published var serial: String = ""
    
    var countries: [AAXCountryModel] = [
        AAXCountryModel(id: "1", flag: "🇬🇧", name: "United Kingdom", code: "uk"),
        AAXCountryModel(id: "2", flag: "🇺🇸", name: "United States", code: "us"),
        AAXCountryModel(id: "3", flag: "🇨🇦", name: "Canada", code: "ca"),
        AAXCountryModel(id: "4", flag: "🇦🇺", name: "Australia", code: "au"),
        AAXCountryModel(id: "5", flag: "🇩🇪", name: "Germany", code: "de"),
        AAXCountryModel(id: "6", flag: "🇫🇷", name: "France", code: "fr"),
        AAXCountryModel(id: "7", flag: "🇮🇹", name: "Italy", code: "it"),
        AAXCountryModel(id: "8", flag: "🇪🇸", name: "Spain", code: "es"),
        AAXCountryModel(id: "9", flag: "🇧🇷", name: "Brazil", code: "br"),
        AAXCountryModel(id: "10", flag: "🇮🇳", name: "India", code: "in"),
        AAXCountryModel(id: "11", flag: "🇯🇵", name: "Japan", code: "jp")
    ]
    
    init() {
        Task {
            do {
                axxUser = try await checkAAXConnectionStatus()
            } catch {
                print("Error checking AAX connection status: \(error)")
            }
        }
    }
    
    @MainActor
    func getAAXLoginURL() async throws -> URL {
        let result: AAXLoginURLResponse = try await CloudFunctionService.shared.makeAuthenticatedCall(
            functionName: "v1getAAXLoginURL",
            with: ["countryCode": selectedCountryCode]
        )
        await MainActor.run {
            DispatchQueue.main.async {
                self.codeVerifier = result.codeVerifier
                self.serial = result.serial
            }
        }
        print(result)
        return result.loginUrl
    }
    
    @MainActor
    func submitAAXLogin(responseUrl: String) async throws {
        try await CloudFunctionService.shared.makeAuthenticatedCall(
            functionName: "v1aaxConnect",
            with: [
                "codeVerifier": codeVerifier,
                "responseUrl": responseUrl,
                "serial": serial,
                "countryCode": selectedCountryCode
            ]
        )
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        do {
            axxUser = try await checkAAXConnectionStatus()
            print("AAX connected successfully")
        } catch {
            print("Error checking AAX connection status: \(error.localizedDescription)")
        }
    }
    
    // MARK: - AAX Connection Status
    
    @MainActor
    func checkAAXConnectionStatus() async throws -> AAXUserModel {
        let result: AAXUserModel = try await CloudFunctionService.shared.makeAuthenticatedCall(
            functionName: "v1getAAXConnectStatus"
        )
        print(result)
        return result
    }
    
    @MainActor
    func getConnectionStatus() {
        Task {
            do {
                axxUser = try await checkAAXConnectionStatus()
            } catch {
                print("Error checking AAX connection status: \(error.localizedDescription)")
            }
        }
    }
    
    @MainActor
    func disconnectAAX() {
        Task {
            try await CloudFunctionService.shared.makeAuthenticatedCall(
                functionName: "v1disconnectAAX"
            )
            await MainActor.run {axxUser = nil}
        }
    }
}

extension AAXManager {
    enum Events {
        case dismiss
    }
}
