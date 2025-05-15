//
//  OpenAIChatService.swift
//  iChatGPT
//
//  Created by EKI KOUKA on R 6/10/21.
//  first create on R 6/09/22.

import Foundation

class ChatGPTAIChatAPI: NSObject, ObservableObject, URLSessionDataDelegate {
    private var session: URLSession!
    private var completeMessage = NSMutableString()
    private var onUpdate: (([MessageElement]) -> Void)?
    
    override init() {
        super.init()
        let configuration = URLSessionConfiguration.default
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
    }
    
    func callChatGPTAPI(for conversation: Conversation, mediaFileOnlineAddress: String? = nil, onUpdate: @escaping ([MessageElement]) -> Void) {
        self.onUpdate = onUpdate
        // 重置 `completeMessage` 在开始新请求时
        completeMessage = NSMutableString()
        
        let userMessage = conversation.messages.last { $0.isUserMessage }?.elements.map { $0.content }.joined(separator: " ") ?? ""
        // 判断是否需要执行搜索，假设含有 "search:" 关键字需要进行联网搜索
        if userMessage.contains("search:") {
            let query = userMessage.replacingOccurrences(of: "search:", with: "").trimmingCharacters(in: .whitespaces)
            
            // 调用 Google 搜索 API
            GoogleSearchService().search(query: query) { searchResults in
                guard let searchResults = searchResults else {
                    // 如果搜索失败，直接调用 ChatGPT API 生成回复
                    self.callChatGPTWithMessages(for: conversation, mediaFileOnlineAddress: mediaFileOnlineAddress)
                    return
                }
                print("GoogleSearchService searchResults: \n\(searchResults)")
                
                // 使用搜索结果构建 ChatGPT 的上下文，并调用 ChatGPT API
                let searchContext = "The following are search results for the query '\(query)':\n\(searchResults)"
                self.callChatGPTWithMessages(for: conversation, mediaFileOnlineAddress: mediaFileOnlineAddress, searchContext: searchContext)
            }
        } else {
            // 如果不需要搜索，直接调用 ChatGPT API
            callChatGPTWithMessages(for: conversation, mediaFileOnlineAddress: mediaFileOnlineAddress)
        }
    }
    
    func callChatGPTWithMessages(for conversation: Conversation, mediaFileOnlineAddress: String? = nil, searchContext: String? = nil) {
        // 从配置文件中获取 API 密钥
        let CHATGPT_API_KEY = Bundle.main.object(forInfoDictionaryKey: "CHATGPT_API_KEY") as? String
        guard let CHATGPT_API_KEY = CHATGPT_API_KEY else {
            print("CHATGPT_API_KEY API key not found")
            return
        }
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(CHATGPT_API_KEY)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 処理搜索上下文
        let searchMemory: [[String: String]] = searchContext != nil ? [["role": "system", "content": searchContext!]] : []
        
        // 将用户的对话消息也加进去
//        let messages = conversation.messages.suffix(10).map { message in
//            ["role": message.isUserMessage ? "user" : "assistant", "content": message.elements.map { $0.content }.joined(separator: " ")]
//        }
        // 构建 messages
        var messages: [[String: Any]] = []

        if let mediaAddress = mediaFileOnlineAddress {
            print("mediaAddress: ", mediaAddress)
            let mediaMessage: [String: Any] = [
                "role": "user",
                "content": [
                    ["type": "text", "text": conversation.messages.last?.elements.map { $0.content }.joined(separator: " ") ?? ""],
                    ["type": "image_url", "image_url": [
                        "url": mediaAddress
                    ]]
                ]
            ]
            messages.append(mediaMessage)
        } else {
            messages = conversation.messages.suffix(10).map { message in
                ["role": message.isUserMessage ? "user" : "assistant", "content": message.elements.map { $0.content }.joined(separator: " ")]
            }
        }
        print("conversation.messages: \(messages)")

        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": userMemory + searchMemory + messages,// 将用户记忆信息与当前对话合并
            "stream": true // 启用流式响应
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        print("request.httpBody: ", request.httpBody?.count)

        let task = session.dataTask(with: request)
        task.resume()
    }
    
    // URLSessionDataDelegate 方法
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let input = String(data: data, encoding: .utf8)
        // 列印接收到的原始數據
        print("原始響應 Raw Response: \(input ?? "")")
        
        input?.enumerateLines { line, _ in
            guard line.hasPrefix("data: ") else { return }
            let jsonString = line.dropFirst(6).trimmingCharacters(in: .whitespacesAndNewlines)
            
            if jsonString == "[DONE]" {
                // 打印完整的响应内容
                print("完整的响应内容 completeMessage: \(self.completeMessage)")
                return
            }
            
            if let jsonData = jsonString.data(using: .utf8) {
                do {
                    let jsonResponse = try JSONSerialization.jsonObject(with: jsonData, options: [])
                    if let jsonDict = jsonResponse as? [String: Any],
                       let choices = jsonDict["choices"] as? [[String: Any]],
                       let delta = choices.first?["delta"] as? [String: Any],
                       var content = delta["content"] as? String {
                        print("Received content chunk: \(content)") // 添加這行來列印每個接收到的內容片段
                        self.completeMessage.append(content) // 保留完整的累積回應（如果需要）
                        //                        self.onUpdate?(self.completeMessage as String)
                        // 使用解析方法將內容拆分為多個 MessageElement
                        let parsedElements = self.parseChatResponse(self.completeMessage as String)
//                        self.onUpdate?(parsedElements) // 回調返回解析後的元素
                        // 在主線程中更新 UI
                       DispatchQueue.main.async {
                           self.onUpdate?(parsedElements)
                       }
                    }
                } catch {
                    print("解析 JSON 时出错：\(error)")
                }
            }
        }
    }
    
    //    func parseChatResponse(_ response: String) -> [MessageElement] {
    //        print("parseChatResponse!!")
    //        var elements: [MessageElement] = []
    //        var currentContent = ""
    //        var isInCodeBlock = false
    //        var isInMathBlock = false
    //        var isInMarkdown = false
    //
    //        let lines = response.split(separator: "\n")
    //
    //        /*for line in lines {
    //            // 檢查是否是代碼塊的開始或結束
    //            if line.starts(with: "```") {
    //                if isInCodeBlock {
    //                    // 代碼塊結束，將代碼塊內容加入到 elements 中
    //                    elements.append(MessageElement(type: .code, content: currentContent))
    //                    currentContent = ""
    //                    isInCodeBlock = false
    //                } else {
    //                    // 代碼塊開始
    //                    isInCodeBlock = true
    //                }
    //            }
    //            // 檢查是否是數學公式的開始或結束
    //            else if line.contains("\\(") || line.contains("\\[") {
    //                if isInMathBlock {
    //                    // 數學公式結束，將公式內容加入到 elements 中
    //                    elements.append(MessageElement(type: .mathFormula, content: currentContent))
    //                    currentContent = ""
    //                    isInMathBlock = false
    //                } else {
    //                    // 數學公式開始
    //                    isInMathBlock = true
    //                }
    //            }
    //            // 檢查是否是 Markdown 內容（如標題、粗體、斜體等）
    //            else if line.starts(with: "#") || line.contains("*") || line.contains("_") || line.contains("~~") || line.contains("-") || line.contains(".") || line.contains(" ") {
    //                if isInMarkdown {
    //                    // Markdown 內容結束，將其內容加入
    //                    elements.append(MessageElement(type: .markdown, content: currentContent))
    //                    currentContent = ""
    //                    isInMarkdown = false
    //                } else {
    //                    // 開始處理 Markdown 內容
    //                    isInMarkdown = true
    //                }
    //            }
    //            // 普通文本處理
    //            else {
    //                if isInCodeBlock {
    //                    // 如果是在代碼塊中，將文本加入到代碼塊中
    //                    currentContent += line + "\n"
    //                } else if isInMathBlock {
    //                    // 如果是在數學公式中，將文本加入到公式中
    //                    currentContent += line + "\n"
    //                } else if isInMarkdown {
    //                    // 如果是在 Markdown 中，將其內容加入
    //                    currentContent += line + " "
    //                } else {
    //                    // 正常的文本段落，將其加入到普通文本中
    //                    currentContent += line + " "
    //                }
    //            }
    //        }
    //
    //        // 處理最後一段，如果還有未處理的內容
    //        if !currentContent.isEmpty {
    //            if isInCodeBlock {
    //                elements.append(MessageElement(type: .code, content: currentContent))
    //            } else if isInMathBlock {
    //                elements.append(MessageElement(type: .mathFormula, content: currentContent))
    //            } else if isInMarkdown {
    //                elements.append(MessageElement(type: .plainText, content: currentContent))
    //            } else {
    //                elements.append(MessageElement(type: .plainText, content: currentContent))
    //            }
    //        }
    //        */
    //
    //        for line in lines {
    //            if line.starts(with: "-") || line.starts(with: ".") {
    //                currentContent += line + "\n"
    //            } else {
    //                currentContent += line + " "
    //            }
    //        }
    //        // 處理最後一段，如果還有未處理的內容
    //        if !currentContent.isEmpty {
    //            elements.append(MessageElement(type: .plainText, content: currentContent))
    //        }
    //        print("elements: \(elements)")
    //        return elements
    //    }
    func parseChatResponse(_ response: String) -> [MessageElement] {
        print("parseChatResponse!!")
//        print("Response content: \(response)") // 添加这行来打印完整的响应内容
        var elements: [MessageElement] = []
        var currentContent = ""
        var isInCodeBlock = false

        let lines = response.split(separator: "\n", omittingEmptySubsequences: false)

        for line in lines {
            if line.starts(with: "```") {
                if isInCodeBlock {
                    // 结束代码块，添加代码元素
                    elements.append(MessageElement(type: .code, content: currentContent))
                    currentContent = ""
                    isInCodeBlock = false
                } else {
                    // 开始代码块
                    isInCodeBlock = true
                    currentContent = ""
                }
            } else {
                if isInCodeBlock {
                    // 在代码块内，累积代码内容
                    currentContent += line + "\n"
                } else {
                    // 在普通文本中，累积为 Markdown 内容
                    currentContent += line + "\n"
                }
            }
        }

        // 处理剩余内容
        if !currentContent.isEmpty {
            if isInCodeBlock {
                elements.append(MessageElement(type: .code, content: currentContent))
            } else {
                elements.append(MessageElement(type: .markdown, content: currentContent))
            }
        }

        print("elements: \(elements)")
        return elements
    }
}
