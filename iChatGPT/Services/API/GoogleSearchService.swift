//
//  GoogleSearchService.swift
//  iChatGPT
//
//  Created by EKI KOUKA on R 6/10/23.
//

import Foundation

class GoogleSearchService {
    private let searchEngineId = "97c0e574473e54798"
    private let GOOGLE_CUSTOM_SEARCH_API = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CUSTOM_SEARCH_API") as? String
    
    func search(query: String, completion: @escaping (String?) -> Void) {
        guard let GOOGLE_CUSTOM_SEARCH_API = GOOGLE_CUSTOM_SEARCH_API else {
            print("GOOGLE_CUSTOM_SEARCH_API API key not found")
            return
        }

        let urlString = "https://www.googleapis.com/customsearch/v1?key=\(GOOGLE_CUSTOM_SEARCH_API)&cx=\(searchEngineId)&q=\(query)"
        Request.request(url: urlString, method: "GET") { result in
            switch result {
                case .success(let json):
                    if let dict = json as? [String: Any],
                       let items = dict["items"] as? [[String: Any]] {
                        
                        // 获取搜索结果中的标题和描述
                        let searchResults = items.prefix(3).compactMap { item in
                            if let title = item["title"] as? String, let snippet = item["snippet"] as? String {
                                print("\(title): \(snippet)")
                                return "\(title): \(snippet)"
                            }
                            return nil
                        }.joined(separator: "\n")
                        completion(searchResults)
                    } else {
                        completion(nil)
                    }
                case .failure(let error):
                    print("❌ 請求失敗: \(error.localizedDescription)")
            }
        }
    }
}
