//
//  ContentView.swift
//  AnswerFile
//
//  Created by ealmas on 3.08.2024.
//
import SwiftUI
import PDFKit
import UniformTypeIdentifiers
import Foundation

struct ContentView: View {
    @State private var isDocumentPickerPresented = false
    @State private var selectedFileURL: URL? = nil
    @State private var fileContent: String = ""
    @State private var showPermissionInfo = false
    @State private var didReturnFromChatView = false
    private let permissionKey = "hasRequestedFileAccess"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                
                ZStack {
                    Image(systemName: "doc.text")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.green)
                    
                    Image(systemName: "questionmark.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.blue)
                        .offset(x: 25, y: 25)
                }
                
                Text("AnswerFile")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(Color.green)
                
                if let fileURL = selectedFileURL, !didReturnFromChatView {
                    NavigationLink(destination: ChatView(fileURL: fileURL, fileContent: fileContent)
                        .onDisappear {
                            // This code runs when returning from ChatView
                            didReturnFromChatView = true
                        }
                    ) {
                        Text("File Selected: \(fileURL.lastPathComponent)")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)  // Adjust button width to fit the screen
                            .background(
                                LinearGradient(gradient: Gradient(colors: [.green, .blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(10)  // Rounded corners
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal, 20)
                } else {
                    Button(action: {
                        isDocumentPickerPresented = true
                    }) {
                        Text("Select File")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)  // Adjust button width to fit the screen
                            .background(
                                LinearGradient(gradient: Gradient(colors: [.green, .blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(10)  // Rounded corners
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal, 20)
                    .sheet(isPresented: $isDocumentPickerPresented, onDismiss: {
                        if selectedFileURL != nil {
                            // Navigate to ChatView when file is selected
                            didReturnFromChatView = false
                        }
                    }) {
                        DocumentPicker(selectedFileURL: $selectedFileURL, fileContent: $fileContent)
                    }
                }
                
                if didReturnFromChatView {
                    NavigationLink(destination: ChatView(fileURL: selectedFileURL!, fileContent: fileContent)) {
                        Text("Continue")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)  // Adjust button width to fit the screen
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)  // Rounded corners
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.white)
            .alert(isPresented: $showPermissionInfo) {
                Alert(
                    title: Text("Permission Required"),
                    message: Text("We need access to your files to perform document operations."),
                    primaryButton: .default(Text("Continue")) {
                        UserDefaults.standard.set(true, forKey: permissionKey)
                        isDocumentPickerPresented = true
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable { // SwiftUI'da UIKit belge seçici kullanımı için temsilci yapı.
    @Binding var selectedFileURL: URL? // Seçilen dosyanın URL'sini tutar.
    @Binding var fileContent: String // Dosyadan çıkarılan içeriği tutar.
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self) // Koordinatörü oluşturur.
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController { // Belge seçici ekranı oluşturulması.
        let supportedTypes: [UTType] = [UTType.item, UTType.data, UTType.package] // Desteklenen dosya türleri.
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        picker.delegate = context.coordinator // Delegate olarak koordinatör atanır.
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // Güncellenmesi gereken herhangi bir işlem yok.
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate { // Belge seçici işlemlerini yönetmek için koordinatör sınıfı.
        var parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.selectedFileURL = url
            readFile(at: url) { content in
                DispatchQueue.main.async { [self] in
                    parent.fileContent = content ?? "File content could not be read."
                }
            }
        }
    }
}
