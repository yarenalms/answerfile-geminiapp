//
//  APIKey.swift
//  AnswerFile
//
//  Created by ealmas on 4.08.2024.
//

import Foundation

/// API anahtarlarını koda gömmek yerine `Config.plist` dosyasından okur.
/// Böylece anahtarlar kaynak kodda (ve Git geçmişinde) yer almaz.
enum APIKey {

    /// Google Gemini API anahtarı (metin soru-cevap).
    static var gemini: String { value(for: "API_KEY") }

    /// Google Cloud Vision API anahtarı (görsel analiz).
    static var vision: String { value(for: "VISION_API_KEY") }

    /// Geriye dönük uyumluluk için.
    static var `default`: String { gemini }

    private static func value(for key: String) -> String {
        guard let filePath = Bundle.main.path(forResource: "Config", ofType: "plist") else {
            fatalError("Couldn't find file 'Config.plist'.")
        }
        let plist = NSDictionary(contentsOfFile: filePath)
        guard let value = plist?.object(forKey: key) as? String else {
            fatalError("Couldn't find key '\(key)' in 'Config.plist'.")
        }
        if value.isEmpty || value.starts(with: "_") {
            fatalError("'\(key)' is not set. Add your own key to 'Config.plist' (see README).")
        }
        return value
    }
}
