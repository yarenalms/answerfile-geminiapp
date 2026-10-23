//
//  FileUtils.swift
//  AnswerFile
//
//  Created by ealmas on 3.08.2024.
//

import PDFKit
import ZIPFoundation


func readFile(at url: URL, completion: @escaping (String?) -> Void) {
    let ext = url.pathExtension.lowercased()
    switch ext {
    case "pdf":
        completion(readPDF(at: url))
    case "txt":
        completion(readText(at: url))
    case "docx":
        completion(readWord(at: url))
    case "jpg", "jpeg", "png", "heic", "tiff", "bmp":
        sendImageToAPI(for: url) { result in
            switch result {
            case .success(let analysisText):
                completion(analysisText)
            case .failure(let error):
                completion("Image analysis failed: \(error.localizedDescription)")
            }
        }
    default:
        completion(nil)
    }
}


func readPDF(at url: URL) -> String? {
    guard let document = PDFDocument(url: url) else {
        return nil // PDF dosyası açılamazsa nil döndürülür.
    }
    var text = ""
    for i in 0..<document.pageCount {
        guard let page = document.page(at: i) else { continue }
        if let pageContent = page.string {
            text += "Page \(i+1):\n" // Sayfa numarasını ekler.
            text += pageContent
            text += "\n\n"
        }
    }
    return text // PDF dosyasının metin içeriği döndürülür.
}

func readText(at url: URL) -> String? {
    do {
        return try String(contentsOf: url, encoding: .utf8) // UTF-8 kodlamasıyla metin dosyası okunur.
    } catch {
        do {
            return try String(contentsOf: url, encoding: .utf16) // UTF-16 kodlamasıyla metin dosyası okunur.
        } catch {
            return nil // Okuma başarısız olursa nil döndürülür.
        }
    }
}

func readWord(at url: URL) -> String? {
    let officeOpenXml = OfficeOpenXml(documentPath: url.path)
    return officeOpenXml.extractText() // Word dosyasından metin çıkarılır.
}
func sendImageToAPI(for imageURL: URL, completion: @escaping (Result<String, APIError>) -> Void) {
    // Anahtar koddan değil Config.plist'ten okunur ve URL yerine başlıkta (header) gönderilir.
    let apiKey = APIKey.vision
    guard let url = URL(string: "https://vision.googleapis.com/v1/images:annotate") else {
        completion(.failure(.requestFailed))
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

    do {
        let imageData = try Data(contentsOf: imageURL)
        let base64Image = imageData.base64EncodedString()
        
        let parameters: [String: Any] = [
            "requests": [
                [
                    "image": [
                        "content": base64Image
                    ],
                    "features": [
                        ["type": "LABEL_DETECTION", "maxResults": 10],
                        ["type": "FACE_DETECTION"],
                        ["type": "OBJECT_LOCALIZATION"]
                    ]
                ]
            ]
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [])
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                completion(.failure(.requestFailed))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(.failure(.invalidResponse))
                return
            }

            guard let data = data else {
                completion(.failure(.decodingError))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let responses = json["responses"] as? [[String: Any]],
                   let response = responses.first {
                    
                    var resultText = ""
                    
                    // Yüz Algılama (Face Detection)
                    if let faceAnnotations = response["faceAnnotations"] as? [[String: Any]], !faceAnnotations.isEmpty {
                        resultText += "Resimde bir yüz algılandı. "
                    }
                    
                    // Nesne Tanıma (Label Detection)
                    if let labelAnnotations = response["labelAnnotations"] as? [[String: Any]], !labelAnnotations.isEmpty {
                        resultText += "Resimdeki belirgin nesneler: "
                        for label in labelAnnotations {
                            if let description = label["description"] as? String {
                                resultText += "\(description), "
                            }
                        }
                        resultText = String(resultText.dropLast(2)) // Son virgülü kaldır
                        resultText += ". "
                    }
                    
                    // Objelerin Yerelleştirilmesi (Object Localization)
                    if let localizedObjectAnnotations = response["localizedObjectAnnotations"] as? [[String: Any]], !localizedObjectAnnotations.isEmpty {
                        for object in localizedObjectAnnotations {
                            if let name = object["name"] as? String {
                                resultText += "Resimde bir \(name) var. "
                            }
                        }
                    }
                    
                    // Özelleştirilmiş Yanıt
                    if resultText.isEmpty {
                        resultText = "Resim analiz edilemedi."
                    } else {
                        resultText = "Resim analizi tamamlandı: " + resultText
                    }
                    
                    completion(.success(resultText))
                } else {
                    completion(.failure(.decodingError))
                }
            } catch {
                completion(.failure(.jsonSerializationError))
            }
        }
        task.resume()
        
    } catch {
        completion(.failure(.jsonSerializationError))
    }
}
