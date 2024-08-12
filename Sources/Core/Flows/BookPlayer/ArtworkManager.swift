//
//  ArtworkManager.swift
//  visibl
//
//

import Foundation
import SwiftUI
import ReadiumShared
import DataCache

struct ArkworkSceneModel: Codable, Equatable {
    let sceneNumber: Int
    let startTime: Double
    let endTime: Double
    let image: String?
    
    enum CodingKeys: String, CodingKey {
        case sceneNumber = "scene_number"
        case startTime = "startTime"
        case endTime = "endTime"
        case image = "image"
    }
}

enum ArtworkError: Error {
    case imageURLNotFound
    case invalidURL
}

final class ArtworkManager: ObservableObject {
    static let shared = ArtworkManager()
        
    private let cache: DataCache = {
        let cache = DataCache(name: "ContentCache")
        cache.maxDiskCacheSize = 0
        cache.maxCachePeriodInSecond = 7*86400
        return cache
    }()
    
    @Published var currentBookRemoteID: String?
    @Published var currentChapter: Int?
    @Published var downloadedScene: Int = 0
    @Published var currentSceneMap: [ArkworkSceneModel] = []
    
    // MARK: - Map Decode
    
    func decodeSceneMap() async {        
        guard let currentBookRemoteID = currentBookRemoteID,
              let currentChapter = currentChapter else {
            print("Error: currentBookRemoteID or currentChapter is nil")
            return
        }
        
        print("Decoding scene map for book: \(currentBookRemoteID)")
        
        do {
            currentSceneMap = try await CloudFunctionService.shared.makeAuthenticatedCall(
                includeRawData: true,
                functionName: "v1getAi",
                with: [
                    "libraryId": currentBookRemoteID,
                    "chapter": "\(currentChapter)"
                ]
            )
        } catch {
            print("Error decoding scene map: \(error.localizedDescription)")
        }
    }
}

// MARK: - Imager Loader with UIImage Return

extension ArtworkManager {
    func getArtworkImage(forTime time: Double) async -> UIImage? {
        guard let currentScene = currentSceneMap.first(where: { $0.startTime <= time && $0.endTime > time }) else {
            print("No scene found for time: \(time)")
            return nil
        }
        
        // Exit if the image for this scene has already been downloaded
        if currentScene.sceneNumber == downloadedScene {
            return nil
        }
        
        guard let imageURLString = currentScene.image, !imageURLString.isEmpty else {
            print("No image URL for scene number: \(currentScene.sceneNumber)")
            return nil
        }
        
        print("Scene number: \(currentScene.sceneNumber)")
        
        if let localURL = getLocalImageURL(for: imageURLString) {
            self.downloadedScene = currentScene.sceneNumber
            return UIImage(contentsOfFile: localURL.path)
        } else {
            let image = await downloadImageToLocalWithUIImage(from: imageURLString)
            if image != nil {
                self.downloadedScene = currentScene.sceneNumber
            }
            return image
        }
    }
    
    private func downloadImageToLocalWithUIImage(from urlString: String) async -> UIImage? {
        do {
            let savedImageURL = try await ImageDownloader.shared.downloadAndSaveImage(from: urlString)
            print("Image downloaded and saved successfully at: \(savedImageURL.path)")
            return UIImage(contentsOfFile: savedImageURL.path)
        } catch {
            print("Error downloading and saving image: \(error)")
            return nil
        }
    }
}

// MARK: - Artwork URL

extension ArtworkManager {
    func getArtworkURL(forTime time: Double) -> URL? {
        let currentScene = currentSceneMap.first { $0.startTime <= time && $0.endTime > time }
        
        if let imageURLString = currentScene?.image, !imageURLString.isEmpty, let imageURL = URL(string: imageURLString) {
            print("Scene number: \(currentScene?.sceneNumber ?? -1)")
            return imageURL
        }
        
        let previousScene = currentSceneMap.filter { $0.endTime <= time }.max { $0.endTime < $1.endTime }
        
        guard let imageURLString = previousScene?.image, !imageURLString.isEmpty, let imageURL = URL(string: imageURLString) else {
            print("Image URL not found for time: \(time)")
            return nil
        }
        
        return imageURL
    }
}

// MARK: - Cache Manager

extension ArtworkManager {
    private func writeToCache(data: [ArkworkSceneModel], for key: String) {
        do {
            let jsonData = try JSONEncoder().encode(data)
            cache.write(data: jsonData, forKey: key)
            print("Successfully wrote data to cache for key: \(key)")
        } catch {
            print("Error writing to cache: \(error)")
        }
    }
    
    private func readFromCache(for key: String) -> [ArkworkSceneModel]? {
        guard let data = cache.readData(forKey: key) else {
            print("No cached data found for key: \(key)")
            return nil
        }
        
        do {
            let decodedData = try JSONDecoder().decode([ArkworkSceneModel].self, from: data)
            print("Successfully read data from cache for key: \(key)")
            return decodedData
        } catch {
            print("Error reading from cache: \(error)")
            return nil
        }
    }
    
    func clearCache() {
        cache.cleanAll()
    }
}

// MARK: - Imager Loader with URL Return

extension ArtworkManager {
    func getArtworkImageURL(forTime time: Double) -> URL? {
        let currentScene = currentSceneMap.first { $0.startTime <= time && $0.endTime > time }
        
        if let scene = currentScene ?? currentSceneMap.filter({ $0.endTime <= time }).max(by: { $0.endTime < $1.endTime }) {
            if let imageURLString = scene.image, !imageURLString.isEmpty {
                print("Scene number: \(scene.sceneNumber)")
                if let localURL = getLocalImageURL(for: imageURLString) {
                    return localURL
                } else {
                    Task {
                        return await downloadImageToLocalWithURL(from: imageURLString)
                    }
                }
            }
        }
        
        print("Image URL not found for time: \(time)")
        return nil
    }
    
    private func downloadImageToLocalWithURL(from urlString: String) async -> URL? {
        do {
            let savedImageURL = try await ImageDownloader.shared.downloadAndSaveImage(from: urlString)
            print("Image downloaded and saved successfully at: \(savedImageURL.path)")
            return savedImageURL
        } catch {
            print("Error downloading and saving image: \(error)")
            return URL(string: urlString)
        }
    }
    
    private func getLocalImageURL(for remoteURL: String) -> URL? {
        guard let url = URL(string: remoteURL) else {
            return nil
        }

        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let localURL = documentsDirectory.appendingPathComponent(url.path)
        
        return fileManager.fileExists(atPath: localURL.path) ? localURL : nil
    }
}

// MARK: - Other Methods

//extension ArtworkManager {
//    func decodeSceneMap() async {
//        cache.cleanAll()
//        currentSceneMap = []
//        
//        guard let currentBookRemoteID = currentBookRemoteID else {
//            print("Error: currentBookRemoteID is nil")
//            return
//        }
//        
//        print("Decoding scene map for book: \(currentBookRemoteID)")
//                
//        do {
//            if let cachedData = readFromCache(for: currentBookRemoteID) {
//                currentSceneMap = cachedData
//                print("Loaded scene map from cache")
//            } else {
//                let result: [ArkworkSceneModel] = try await CloudFunctionService.shared.makeAuthenticatedCall(
//                    includeRawData: true,
//                    functionName: "v1getAi",
//                    with: ["libraryId": currentBookRemoteID]
//                )
//                print("Fetched scene map from server")
//                
//                currentSceneMap = result
//                writeToCache(data: result, for: currentBookRemoteID)
//            }
//        } catch {
//            print("Error decoding scene map: \(error.localizedDescription)")
//        }
//    }
//}
