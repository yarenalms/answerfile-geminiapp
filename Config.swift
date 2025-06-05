//
//  Config.swift
//  AnswerFile
//
//  Created by ealmas on 3.08.2024.
//
import Foundation

struct RecipeResponse: Codable {
    let candidates: [Candidate]
    let usageMetadata: UsageMetadata
}

struct Candidate: Codable {
    let content: Content
    let finishReason: String
    let index: Int
    let safetyRatings: [SafetyRating]
}

struct Content: Codable {
    let parts: [Part]
    let role: String
}

struct Part: Codable {
    let text: String
}

struct SafetyRating: Codable {
    let category: String
    let probability: String
}

struct UsageMetadata: Codable {
    let promptTokenCount: Int
    let candidatesTokenCount: Int
    let totalTokenCount: Int
}

// API Hata Durumları
enum APIError: Error {
    case requestFailed // İstek başarısız
    case invalidResponse // Yanıt geçersiz
    case decodingError // JSON çözümleme hatası
    case jsonSerializationError // JSON oluşturma hatası
    case apiKeyInvalid // API anahtarı geçersiz
    case unknownError // Bilinmeyen hata
}

// API'ye istek gönderme fonksiyonu
func sendQueryToGeminiAPI(metin: String, soru: String, completion: @escaping (Result<RecipeResponse, APIError>) -> Void) {
    let apiKey = APIKey.default // API anahtarını al
    let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=\(apiKey)" // API URL'si
    guard let url = URL(string: urlString) else {
        completion(.failure(.requestFailed)) // Hata ile tamamla
        return
    }
    
    // İstek parametrelerini hazırla
    let parameters: [String: Any] = [
        "contents": [
            [
                "parts": [
                    ["text": "\(metin)\n\(soru)"]
                ]
            ]
        ]
    ]
    
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: []) // JSON verisi oluştur
        var request = URLRequest(url: url)
        request.httpMethod = "POST" // HTTP metodu POST olarak ayarla
        request.setValue("application/json", forHTTPHeaderField: "Content-Type") // İçerik türünü ayarla
        request.httpBody = jsonData // İstek gövdesine JSON verisini ekle
        
        // API isteğini başlat
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                completion(.failure(.requestFailed)) // Hata ile tamamla
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(.failure(.invalidResponse)) // Hata ile tamamla
                return
            }
            
            guard let data = data else {
                completion(.failure(.decodingError)) // Hata ile tamamla
                return
            }
            
            // Yanıtı JSON olarak çözümle
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(RecipeResponse.self, from: data) // JSON yanıtını çözümle
                completion(.success(response)) // Başarı ile tamamla
            } catch {
                completion(.failure(.jsonSerializationError)) // Hata ile tamamla
            }
        }
        task.resume() // İstek görevini başlat
        
    } catch {
        completion(.failure(.jsonSerializationError)) // Hata ile tamamla
    }
}
