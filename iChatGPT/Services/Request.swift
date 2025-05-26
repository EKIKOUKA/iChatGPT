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
        method: String? = nil,
        headers: [String: String]? = nil,
        body: [String: Any]? = nil,
        rawBody: Data? = nil,
        onStart: (() -> Void)? = nil,
        onFailure: ((String) -> Void)? = nil,
        completion: @escaping (Result<Any, Error>) -> Void
    ) {
        onStart?() // 請求開始
        
        guard let url = URL(string: url) else {
            let errorMsg = "無効な URL"
            onFailure?(errorMsg)
            completion(.failure(NSError(domain: "", code: -1,
                userInfo: [NSLocalizedDescriptionKey: errorMsg])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method ?? "POST"

        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        if request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("application/json;charset=utf-8", forHTTPHeaderField: "Content-Type")
        }
        if let rawBody = rawBody {
            request.httpBody = rawBody
        } else if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            print("httpBody: ", body)
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ 請求が誤り: \(error)")
                onFailure?(error.localizedDescription)
                completion(.failure(error))
            }
            guard let data = data, let httpResponse = response as? HTTPURLResponse else {
                let errorMsg = "❌ データなし"
                onFailure?(errorMsg)
                completion(.failure(NSError(domain: "", code: -2,
                             userInfo: [NSLocalizedDescriptionKey: errorMsg])))
                return
            }
            guard httpResponse.statusCode == 200 else {
                let bodyString = String(data: data, encoding: .utf8) ?? ""
                let errorMsg = "❌ HTTP エラー: \(httpResponse.statusCode): \(bodyString)"
                print("Response body: \(errorMsg)")
                onFailure?(errorMsg)
                completion(.failure(NSError(domain: "", code: httpResponse.statusCode,
                            userInfo: [NSLocalizedDescriptionKey: errorMsg])))
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let dict = json as? [String: Any] {
                    if let message = dict["message"] as? String {
                        print("Response message: \(message)")
                    }
                }
                completion(.success(json))
            } catch {
                let rawString = String(data: data, encoding: .utf8) ?? "<非UTF-8データ>"
                print("❌ JSONをデコードエラー: \(error), Raw response: \(rawString)")
                onFailure?("JSONをデコードエラー: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }.resume()
    }
}
