//
//  CreateTOTP_Verity.swift
//  iChatGPT
//
//  Created by 宇都宮　誠 on R 7/05/25.
//
import SwiftUI
import WebKit

struct CreateTOTP_VirityView: View {
    @Binding var navigationPath: NavigationPath
    @AppStorage("userId") var userId: String?
    @State private var code: String = ""
    @State private var codeStatus: String = ""
    
    var body: some View {
        VStack(spacing: 16) {
            WebView(url: URL(string: "http://133.242.132.37:3000/generate-secret?userId=" + userId!)!)
                .frame(width: .infinity, height: 400)
            VStack(spacing: 20) {
                CodeInputView(code: $code) { input in
                    print("code: ", input)
                    print("$code wrappedValue: ", $code.wrappedValue)
                    speakeasy_verify()
                }
                Text(codeStatus)
            }
        }
        .padding()
        .navigationTitle("TOTP確認コードを設定")
    }
    
    func speakeasy_verify() {
        Request.request(url: "http://133.242.132.37:3000/verify",
            body: [
                "userId": userId!,
                "token": $code.wrappedValue
            ]
        ) { result in
            switch result {
                case .success(let json):
                    print("json: ", json)
                if let dict = json as? [String: Any],
                   let success = dict["success"] as? Int {
                    codeStatus = success == 1 ? "正しい" : "正しくない"
                }
                case .failure(let error):
                    print("❌ 請求失敗: \(error.localizedDescription)")
            }
        }
    }
}


struct WebView1: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }
    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.load(URLRequest(url: url))
    }
}
