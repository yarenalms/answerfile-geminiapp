# answerfile-geminiapp
SwiftUI ile geliştirilmiş bu uygulama, PDF / DOCX / TXT dosyalarını okur , basit resimleri analiz eder ve Google Gemini API üzerinden soru-cevap yapmanıza olanak tanır.

##  Özellikler

-  Dosya seçimi (PDF, Word, metin dosyaları, görseller)
-  Gemini API ile içerik üzerinde soru-cevap
-  Modern SwiftUI arayüz
- ☁ Google Vision API ile görsel içerik analiz desteği

## Kullanılan Teknolojiler

- SwiftUI
- Google Gemini API
- Google Vision API (image desteği için)
- PDFKit, ZIPFoundation (Word analiz)
- MVVM benzeri modüler yapı

## Ekran Görüntüsü
<img src="screenshot1.png" width="200" alt="Ana ekran">

<img src="screenshot2.png" width="200" alt="chat ekranı">


##  Dosya Yapısı
AnswerFileApp.swift # Uygulama başlatıcısı
ContentView.swift # Ana ekran + dosya seçici
ChatView.swift # Soru-cevap arayüzü
Config.swift # API veri modelleri
APIKey.swift # API anahtarı yükleyici
FileUtils.swift # PDF, TXT, Word okuma, görsel analizi
OfficeOpenXml.swift # DOCX içerik çıkarıcı

## Nasıl Kullanılır?
1. `Config.plist` içinde `API_KEY` alanını doldur.
2. Uygulamayı Xcode'da çalıştır, cihaz veya simülatörde dene.
