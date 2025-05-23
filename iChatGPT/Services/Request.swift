//
//  Request.swift
//  iChatGPT
//
//  Created by 宇都宮　誠 on R 7/05/23.
//

import Foundation

class Request {
    
    static func request(
        url: String,
        headers: [String: String]? = nil,
        body: [String: Any]? = nil,
        completion: @escaping (Result<Any, Error>) -> Void
    ) {
        guard let url = URL(string: url) else {
            print("❌ 無效な URL")
            completion(.failure(NSError(domain: "", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "無效な URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        if request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("❌ 請求が誤り: \(error)")
                completion(.failure(error))
            } else if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data)
                    if let array = json as? [[String: Any]] {
                        completion(.success(array))
                    } else {
                        print("⚠️ データ形式が期待されるJSON配列ではない")
                        print("原始の JSON: \(json)")
                        completion(.failure(NSError(domain: "", code: -3, userInfo: [NSLocalizedDescriptionKey: "資料格式錯誤"])))
                    }
                } catch {
                    print("❌ JSONをデコードエラー: \(error)")
                    print(String(data: data, encoding: .utf8) ?? "")
                    completion(.failure(error))
                }
            } else {
                print("❌ データなし")
                completion(.failure(NSError(domain: "", code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "データなし"])))
            }
        }.resume()
    }
}
