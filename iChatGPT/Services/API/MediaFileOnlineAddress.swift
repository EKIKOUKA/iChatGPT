//
//  GoogleSearchService.swift
//  iChatGPT
//
//  Created by EKI KOUKA on R 6/10/23.
//

import Foundation
import CryptoKit
import UniformTypeIdentifiers

class MediaFileOnlineAddress {
    private let CLOUDINARY_API_KEY = "911743962998466"
    private let CLOUDINARY_SECRET_API = Bundle.main.object(forInfoDictionaryKey: "CLOUDINARY_SECRET_API") as? String
    
    func upload(fileData: Data?, completion: @escaping (String?) -> Void) {
        guard let cloudinary_secret_api = CLOUDINARY_SECRET_API else {
            print("CLOUDINARY_SECRET_API API key not found")
            completion(nil)
            return
        }

        guard let fileData = fileData else {
            completion(nil)
            return
        }
        
        // 偵測 MIME 類型與副檔名
        let mimeType: String
        let fileExtension: String

        if let detectedType = UTType(filenameExtension: "tmp") {
            mimeType = detectedType.preferredMIMEType ?? "application/octet-stream"
            fileExtension = detectedType.preferredFilenameExtension ?? "bin"
        } else {
            mimeType = "application/octet-stream"
            fileExtension = "bin"
        }
        
        // Cloudinary 上伝参数
        let publicId = "dsyk0oet0_file"
        let timestamp = Int(Date().timeIntervalSince1970)
        let uploadUrl = "https://api.cloudinary.com/v1_1/dsyk0oet0/image/upload"
        // 組合簽名字符串
        let signatureString = "public_id=\(publicId)&timestamp=\(timestamp)\(cloudinary_secret_api)"
        let signature = Insecure.SHA1.hash(data: signatureString.data(using: .utf8)!)
            .map { String(format: "%02hhx", $0) }
            .joined()
       
        let boundary = UUID().uuidString
    
        var body = Data()
        
        func appendField(name: String, value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        appendField(name: "api_key", value: CLOUDINARY_API_KEY)
        appendField(name: "timestamp", value: "\(timestamp)")
        appendField(name: "public_id", value: publicId)
        appendField(name: "signature", value: signature)
        
        // 加入檔案資料
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"upload.\(fileExtension)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        print("body: ", body)
        
        Request.request(
            url: uploadUrl,
            headers: [
                "Content-Type": "multipart/form-data; boundary=\(boundary)"
            ],
            rawBody: body
        ) { result in
            switch result {
                case .success(let json):
                    if let dict = json as? [String: Any],
                       let url = dict["secure_url"] as? String {
                            DispatchQueue.main.async {
                                print("Cloudinary 上傳成功：\(url)")
                                completion(url)
                            }
                        }
                case .failure(let error):
                    print("❌ Cloudinary 上傳失敗: \(error.localizedDescription)")
                    completion(nil)
            }
        }
    }
}
