//
//  Configuration.swift
//  visibl
//
//

import Foundation

class Configuration {
    static var cloudFunctionRegion: String {
        return Bundle.main.object(forInfoDictionaryKey: "APP_CLOUD_FUNC_REGION") as? String ?? ""
    }
    static var catalogueURL: String {
        let url = Bundle.main.object(forInfoDictionaryKey: "APP_CATALOGUE_URL") as? String ?? ""
        return "https://" + url
    }
}
