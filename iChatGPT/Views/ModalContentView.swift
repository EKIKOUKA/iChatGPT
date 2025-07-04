//
//  ModalContentListAPI.swift
//  iChatGPT
//
//  Created by EKI KOUKA on R 6/10/06.
//

import SwiftUI
import WebKit
import SafariServices

struct ModalContentView: View {
    @Binding var isShowingModal: Bool // 绑定状态
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        
        VStack {
            
            NavigationStack(path: $navigationPath) {
                
                List {
                    NavigationLink("個人情報", value: "PersonInfo")
                    
                    Section(header: Text("人工知能オンライン")) {
                        NavigationLink("Gemini", destination: WebView(url: URL(string: "https://gemini.google.com/")!))
                        NavigationLink("ChatGPT", destination: WebView(url: URL(string: "https://chatgpt.com/")!))
                    }
                    
                    Section(header: Text("ChatGPT API について").textCase(.none)) {
                        NavigationLink("使用情況", destination: SafariView(url: URL(string: "https://platform.openai.com/settings/organization/usage")!))
                        NavigationLink("請求書", destination: SafariView(url: URL(string: "https://platform.openai.com/settings/organization/billing/overview")!))
                        NavigationLink("制限", destination: SafariView(url: URL(string: "https://platform.openai.com/settings/organization/limits")!))
                        NavigationLink("料金", destination: SafariView(url: URL(string: "https://openai.com/api/pricing/")!))
                    }
                    
                    Section(header: Text("Cloudinary").textCase(.none)) {
                        NavigationLink("Media Library", destination: SafariView(url: URL(string: "https://console.cloudinary.com/console/c-a34cabbb2cbbef50f7d5888c2d7ad0/media_library/search?q=&view_mode=mosaic")!))
                    }
                    
                    Section(header: Text("アカウント")) {
                        NavigationLink("メモリ管理", destination: memoryListView())
                    }
                }
                .navigationTitle("設定")
                .navigationBarTitleDisplayMode(.inline) // 強制標題在導航欄中居中
                .navigationBarItems(trailing:
                    Button(action: {
                        isShowingModal = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                    }
                )
                .navigationDestination(for: String.self) { value in
                    switch value {
                        case "PersonInfo":
                            PersonInfoView(navigationPath: $navigationPath) // 将 navigationPath 綁定傳給子頁
                        case "Login":
                            Login(navigationPath: $navigationPath)
                        case "TOTP":
                            TOTP_VerityView(navigationPath: $navigationPath)
                        case "CreateTOTP_Verity":
                            CreateTOTP_VirityView(navigationPath: $navigationPath)
                        default:
                            EmptyView()
                    }
                }
            }
        }
    }
}

struct memoryListView: View {
    
    var body: some View {
        VStack {
            List {
                ForEach(userMemory.indices, id: \.self) {index in
                    Text(userMemory[index]["content"]!)
                }
                .onDelete(perform: deleteMemoryItem)
            }
            .navigationTitle("メモリ管理")
            .navigationBarTitleDisplayMode(.inline) // 強制標題在導航欄中居中
        }
    }
    
    private func deleteMemoryItem(at offsets: IndexSet) {
    }
}


struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // 用于更新界面，用于协议的一部分，无需回调
    }
}

// Create a custom WKWebView struct
struct WebView: UIViewRepresentable {
    let url: URL
    let webView = WKWebView(frame: .zero)

    func makeUIView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator // Assign a delegate for events like loading or errors
        let request = URLRequest(url: url)
        if webView.url != url {
            webView.load(request)
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // You can implement code here if you need to update the WKWebView dynamically.
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    // 创建 Coordinator 来处理网页的加载和导航
    class Coordinator: NSObject, WKNavigationDelegate {
        // 页面加载完成后，调用该方法
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // 页面加载完成后执行 JavaScript
            removeDiv(webView)
        }

        // 删除指定的 div 元素
        func removeDiv(_ webView: WKWebView) {
            let javascript = """
                // 创建 MutationObserver 实例
                const observer = new MutationObserver(function(mutationsList, observer) {
                    // 查找页面中是否存在 id 为 'composer-background' 的 div
                    var div1 = document.querySelector('.min-h-4');
                    var div2 = document.querySelector('.pl-0');
                    var div3 = document.querySelector('.bottom-full');
                    
                    // 如果找到了这个 div，执行删除操作
                    if (div1 || div2 || div3) {
                        div1.remove();  // 删除元素
                        div2.remove();  // 删除元素
                        div3.remove();  // 删除元素
                        console.log('Div removed');
                        
                        // 停止观察，因为已经删除了目标元素
                        // observer.disconnect();
                        console.log('Observer disconnected');
                    }
                });

                // 配置 MutationObserver 的选项
                const config = {
                    childList: true,    // 监听子节点的增删
                    subtree: true       // 监听整个文档（包括后代节点）的变化
                };

                // 开始观察 document.body 元素的变化
                observer.observe(document.body, config);
            """
            // 执行 JavaScript 删除 div
            webView.evaluateJavaScript(javascript) { result, error in
                if let error = error {
                    print("Error executing JavaScript: \(error.localizedDescription)")
                } else if let result = result as? Bool, result == true {
                    print("Div removed successfully")
                } else {
                    print("Div not found or failed to remove.")
                }
            }
        }
    }
}


struct ModalContentView_Previews: PreviewProvider {
    static var previews: some View {
        ModalContentView(isShowingModal: .constant(false)) // 使用固定值模拟绑定状态
    }
}
