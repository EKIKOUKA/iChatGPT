//
//  MathTextView.swift
//  iChatGPT
//
//  Created by EKI KOUKA on R 6/11/13.
//

import SwiftUI
import WebKit

struct MathTextView: UIViewRepresentable {
    var text: String
    
    func clearCache() {
        let dataStore = WKWebsiteDataStore.default()
        let websiteDataTypes: Set<String> = [WKWebsiteDataTypeMemoryCache, WKWebsiteDataTypeDiskCache]
        dataStore.removeData(ofTypes: websiteDataTypes, modifiedSince: Date(timeIntervalSince1970: 0)) {
            print("Cache cleared.")
        }
    }
    
    class WebViewCoordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("WebView finished loading")
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("Failed to load: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("Navigation error: \(error.localizedDescription)")
        }
    }
    
    func makeCoordinator() -> WebViewCoordinator {
        return WebViewCoordinator()
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        print("WebView frame: \(webView.frame)")
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.navigationDelegate = context.coordinator // 绑定 delegate
        webView.configuration.preferences.javaScriptEnabled = true // 启用 JavaScript
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        clearCache()  // 清除缓存
        print("MathTextView text: \(text)")
        
        // 转换文本，处理 MathJax 渲染
        let htmlText = convertToHTML(text: text)
        print("Converted htmlText: \(htmlText)")
        
        let htmlString = """
        <!DOCTYPE html>
        <html>
        <head>
        <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.7/MathJax.js?config=TeX-MML-AM_CHTML"></script>
        <style>
            #content {
                font-size: 50px; /* Adjust the size here */
            }
        </style>
        </head>
        <body>
        <div id="content">\(htmlText)</div>
        <script type="text/javascript">
          MathJax.Hub.Queue(["Typeset", MathJax.Hub, "content"]);
          MathJax.Hub.Queue(function() {
            console.log('MathJax rendering finished');
          });
        </script>
        </body>
        </html>
        """
        uiView.loadHTMLString(htmlString, baseURL: nil)
        
        // 设置默认的 WebView 大小，避免内容为空时 WebView 不显示
        DispatchQueue.main.async {
            if uiView.frame.size.width == 0 || uiView.frame.size.height == 0 {
                uiView.frame = CGRect(x: 0, y: 0, width: 300, height: 300) // 这里给定默认大小
            }
        }
    }

    // 將含有公式的文本轉換為 HTML 格式
    private func convertToHTML(text: String) -> String {
        // 使用正則表達式查找公式部分
        let pattern = #"\\\((.*?)\\\)"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsText = text as NSString
        
        // 將公式包裹在 span 標記內，供 MathJax 渲染
        var htmlText = nsText as String
        regex?.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length)).forEach {
            let matchRange = $0.range(at: 0)
            let formula = nsText.substring(with: matchRange)
            let htmlFormula = "<span>\(formula)</span>"
            htmlText = htmlText.replacingOccurrences(of: formula, with: htmlFormula)
        }
        
        // 將文本中的換行符替換為 HTML 換行
        return htmlText.replacingOccurrences(of: "\n", with: "<br>")
    }
}

struct ContentView: View {
    var body: some View {
        GeometryReader { geometry in
            MathTextView(text: "測試")
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}
