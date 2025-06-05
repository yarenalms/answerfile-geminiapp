//
//  APIKey.swift
//  AnswerFile
//
//  Created by ealmas on 4.08.2024.
//

import Foundation
enum APIKey {
  
  static var `default`: String {
    guard let filePath = Bundle.main.path(forResource: "Config", ofType: "plist")
    else {
      fatalError("Couldn't find file 'Config.plist'.")
    }
    let plist = NSDictionary(contentsOfFile: filePath)
    guard let value = plist?.object(forKey: "API_KEY") as? String else {
      fatalError("Couldn't find key 'API_KEY' in 'Config.plist'.")
    }
    if value.starts(with: "_") || value.isEmpty {
      fatalError(
        "Follow the instructions at https://ai.google.dev/tutorials/setup to get an API key."
      )
    }
    return value
  }
}
