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
        completion: @escaping (Result<Any, Error>) -> Void
    ) {
        guard let url = URL(string: url) else {
            completion(.failure(NSError(domain: "", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "無効な URL"])))
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
                completion(.failure(error))
                return
            }
            guard let data = data, let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "", code: -2,
                     userInfo: [NSLocalizedDescriptionKey: "❌ データなし"])))
                return
            }
            guard httpResponse.statusCode == 200 else {
                let bodyString = String(data: data, encoding: .utf8) ?? ""
                let errorMsg = "❌ HTTP エラー: \(httpResponse.statusCode): \(bodyString)"
                print("Response body: \(errorMsg)")
                if let json = try? JSONSerialization.jsonObject(with: data, options: []),
                   let dict = json as? [String: Any],
                   let message = dict["message"] as? String {
                    completion(.failure(NSError(domain: "", code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: message])))
                }
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
                completion(.failure(error))
            }
        }.resume()
    }
}
