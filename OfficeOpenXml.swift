//
//  OfficeOpenXml.swift
//  AnswerFile
//
//  Created by Yaren Almas on 6.08.2024.
//
import Foundation
import ZIPFoundation

class OfficeOpenXml {
    let documentPath: String
    var documentText: String?

    init(documentPath: String) {
        self.documentPath = documentPath
        self.documentText = nil
    }

    func extractText() -> String? {
        do {
            let archive = try Archive(url: URL(fileURLWithPath: documentPath), accessMode: .read)
            guard let entry = archive["word/document.xml"] else { return nil }
            
            var documentXML = ""
            _ = try archive.extract(entry) { data in
                documentXML.append(String(decoding: data, as: UTF8.self))
            }
            self.documentText = parseXML(documentXML)
            return self.documentText
        } catch {
            print("document.xml çıkarılırken hata oluştu: \(error)")
            return nil
        }
    }

    func parseXML(_ xml: String) -> String {
        var text = ""
    
        if let xmlData = xml.data(using: .utf8) {
            let xmlParser = XMLParser(data: xmlData)
            let parserDelegate = XMLParserDelegateImpl()
            xmlParser.delegate = parserDelegate
            if xmlParser.parse() {
                text = parserDelegate.parsedText
            }
        }
        return text
    }
}

class XMLParserDelegateImpl: NSObject, XMLParserDelegate {
    var parsedText = ""

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        parsedText += string
    }
}
