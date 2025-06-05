//
//  ChatView.swift
//  AnswerFile
//
//  Created by ealmas on 3.08.2024.
//
import SwiftUI
import PDFKit
import UniformTypeIdentifiers
import Foundation

struct ChatView: View {
    let fileURL: URL // Seçilen dosyanın URL'si.
    let fileContent: String // Dosya içeriği.
    @State private var question: String = "" // Kullanıcının sorusu.
    @State private var apiResult: [(String, Bool)] = [] // API'den gelen yanıtlar listesi (soru/yanıt, kullanıcı mı?).
    
    var body: some View {
        VStack {
            ScrollViewReader { scrollView in
                ScrollView { // API'den gelen yanıtları göstermek için kaydırılabilir alan.
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(apiResult.indices, id: \.self) { index in
                            let message = apiResult[index].0
                            let isUser = apiResult[index].1
                            
                            HStack {
                                if isUser {
                                    Spacer()
                                    Text(message)
                                        .padding()
                                        .background(Color.green.opacity(0.8)) // Sorular için yeşil baloncuk.
                                        .cornerRadius(15)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                } else {
                                    Text(message)
                                        .padding()
                                        .background(Color.gray.opacity(0.15)) // Cevaplar için daha açık gri baloncuk.
                                        .cornerRadius(15)
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Spacer()
                                }
                            }
                            .padding(.horizontal)
                            .id(index) // Her mesaja bir ID veriyoruz.
                        }
                    }
                }
                .onChange(of: apiResult.count) { newCount in
                    // Yeni bir mesaj geldiğinde en son mesaja kaydır.
                    withAnimation {
                        scrollView.scrollTo(newCount - 1, anchor: .bottom)
                    }
                }
            }
            
            Divider() // Alt kısımda soruyu ve gönderme butonunu ayıran çizgi.

            HStack {
                TextField("Write your question here...", text: $question) // Kullanıcının soru girdiği metin alanı.
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(25)
                    .padding(.horizontal)
                
                Button(action: {
                    sendQuestionToAPI() // Butona tıklandığında API'ye soru gönderilir.
                }) {
                    Image(systemName: "paperplane.fill") // Uçak simgesi.
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .padding(10)
                        .background(LinearGradient(gradient: Gradient(colors: [.green, .blue]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
                .padding(.trailing)
            }
            .padding(.bottom) // Alt kısımda biraz boşluk bırakır.
        }
        .padding()
        .background(Color.white)
        .navigationBarTitle(Text(fileURL.lastPathComponent), displayMode: .inline) // Ekran başlığı olarak dosya adı gösterilir.
    }
    
    func sendQuestionToAPI() {
        let text = fileContent
        let question = self.question
        
        // Soru balonunu ekle
        self.apiResult.append((question, true))
        self.question = "" // Soruyu gönderdiğinde temizle.
        
        sendQueryToGeminiAPI(metin: text, soru: question) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    let newResponse = response.candidates.first?.content.parts.first?.text ?? "No response"
                    self.apiResult.append((newResponse, false)) // Yeni yanıtı balon olarak ekle.
                case .failure(let error):
                    self.apiResult.append(("Hata: \(error.localizedDescription)", false))
                }
            }
        }
    }
}
