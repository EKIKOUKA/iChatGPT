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
            print("❌ 無効な URL")
            completion(.failure(NSError(domain: "", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "無効な URL"])))
            return
        }

        var request = URLRequest(url: url)
        
        if let http_method = method {
            request.httpMethod = http_method
        } else {
            request.httpMethod = "POST"
        }

        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
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
            } else if let data = data, let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                if statusCode != 200 {
                    let bodyString = String(data: data, encoding: .utf8) ?? ""
                    print("❌ HTTP エラー: \(statusCode)")
                    print("Response body: \(bodyString)")
                    let error = NSError(domain: "", code: statusCode,
                        userInfo: [NSLocalizedDescriptionKey: "HTTP エラー: \(statusCode)\n\(bodyString)"])
                    completion(.failure(error))
                    return
                }
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                    if let dict = json as? [String: Any] {
                        if let message = dict["message"] as? String {
                            print("Response message: \(message)")
                        }
                    }
                    completion(.success(json))
                } catch {
                    let rawString = String(data: data, encoding: .utf8) ?? "<非UTF-8データ>"
                    print("❌ JSONをデコードエラー: \(error)")
                    print("Raw response: \(rawString)")
                    // Try to parse message from raw string if possible
                    if let dataFromString = rawString.data(using: .utf8),
                       let jsonFromString = try? JSONSerialization.jsonObject(with: dataFromString, options: .allowFragments),
                       let dict = jsonFromString as? [String: Any],
                       let message = dict["message"] as? String {
                          let errorWithMessage = NSError(domain: "", code: -3,
                            userInfo: [NSLocalizedDescriptionKey: message])
                          completion(.failure(errorWithMessage))
                    } else {
                        completion(.failure(error))
                    }
                }
            } else {
                print("❌ データなし")
                completion(.failure(NSError(domain: "", code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "データなし"])))
            }
        }.resume()
    }
}
