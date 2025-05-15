//
//  DocumentPicker.swift
//  iChatGPT
//
//  Created by 宇都宮　誠 on R 7/05/10.
//

import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    var completion: (Data?) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.data])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            print("didPickDocumentsAt: \(urls)") // 檢查是否成功取得 URL
            if let url = urls.first {
                
                // 嘗試存取安全作用域資源
                guard url.startAccessingSecurityScopedResource() else {
                    print("Failed to access security-scoped resource.")
                    parent.completion(nil)
                    return
                }
                defer { url.stopAccessingSecurityScopedResource() } // 確保在離開 scope 時停止存取
                
                do {
                    let data = try Data(contentsOf: url)
                    print("Data size: \(data.count) bytes") // 檢查是否成功讀取資料
                    parent.completion(data)
                } catch {
                    print("Error reading data: \(error)") // 檢查讀取錯誤
                    parent.completion(nil)
                }
            } else {
                parent.completion(nil)
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.completion(nil)
        }
    }
}
