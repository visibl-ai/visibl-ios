//
//  CloudFunctionService.swift
//  visibl
//
//

import FirebaseAuth
import FirebaseFunctions

final class CloudFunctionService {
    static let shared = CloudFunctionService()
    private let functions = Functions.functions(region: Configuration.cloudFunctionRegion)
    
    private func checkUserAuthentication() -> Bool { return Auth.auth().currentUser != nil }
    
    public func makeAuthenticatedCall<T: Codable>(includeRawData: Bool = false, functionName: String, with data: Any? = nil) async throws -> T {
        guard checkUserAuthentication() else {
            throw NSError(
                domain: "FirebaseService",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]
            )
        }
        
        do {
            let callable = functions.httpsCallable(functionName)
            let result = try await callable.call(data)
            
            // Handle different types of result.data
            let jsonCompatibleData: Any
            if let dict = result.data as? [String: Any] {
                jsonCompatibleData = dict
            } else if let array = result.data as? [Any] {
                jsonCompatibleData = array
            } else {
                jsonCompatibleData = ["data": result.data]
            }
            
            let jsonData = try JSONSerialization.data(withJSONObject: jsonCompatibleData, options: [])
            
            // Print Raw Data into Console
            if includeRawData {
                if let jsonAsString = String(data: jsonData, encoding: .utf8) {
                    print("Raw JSON data: \(jsonAsString)")
                }
            }
            
            return try JSONDecoder().decode(T.self, from: jsonData)
        } catch {
            print("Error during Firebase function call or JSON parsing: \(error)")
            if let jsonError = error as? DecodingError {
                print("JSON Decoding Error: \(jsonError)")
            }
            throw NSError(
                domain: "FirebaseService",
                code: (error as NSError).code,
                userInfo: [NSLocalizedDescriptionKey: "Failed to call function or parse JSON: \(error.localizedDescription)"]
            )
        }
    }
    
    public func makeAuthenticatedCall(includeRawData: Bool = false, functionName: String, with data: Any? = nil) async throws {
        guard checkUserAuthentication() else {
            throw NSError(
                domain: "FirebaseService",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]
            )
        }
        
        do {
            let callable = functions.httpsCallable(functionName)
            let result = try await callable.call(data)
            
            // Print Raw Data into Console if requested
            if includeRawData {
                if let jsonData = try? JSONSerialization.data(withJSONObject: result.data, options: []),
                   let jsonAsString = String(data: jsonData, encoding: .utf8) {
                    print("Raw JSON data: \(jsonAsString)")
                }
            }
        } catch {
            print("Error during Firebase function call: \(error.localizedDescription)")
            throw NSError(
                domain: "FirebaseService",
                code: (error as NSError).code,
                userInfo: [NSLocalizedDescriptionKey: "Failed to call function: \(error.localizedDescription)"]
            )
        }
    }
}
