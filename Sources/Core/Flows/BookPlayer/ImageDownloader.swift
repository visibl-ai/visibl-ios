//
//  ImageDownloader.swift
//  visibl
//
//

import Foundation
import UIKit

enum ImageDownloaderError: Error {
    case invalidURL
    case downloadFailed
    case saveFailed
}

class ImageDownloader {
    static let shared = ImageDownloader()
    
    private init() {}
    
    func downloadAndSaveImage(from urlString: String) async throws -> URL {
        guard let url = URL(string: urlString) else {
            throw ImageDownloaderError.invalidURL
        }
        
        let image = try await downloadImage(from: url)
        return try await saveImage(image, withPath: url.path)
    }
    
    private func downloadImage(from url: URL) async throws -> UIImage {
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let image = UIImage(data: data) else {
            throw ImageDownloaderError.downloadFailed
        }
        
        return image
    }
    
    private func saveImage(_ image: UIImage, withPath path: String) async throws -> URL {
        let fileManager = FileManager.default
        
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw ImageDownloaderError.saveFailed
        }
        
        let fullPath = documentsDirectory.appendingPathComponent(path)
        
        try fileManager.createDirectory(at: fullPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        guard let data = image.jpegData(compressionQuality: 1.0) else {
            throw ImageDownloaderError.saveFailed
        }
        
        try data.write(to: fullPath)
        
        return fullPath
    }
}
