//
//  TOTP_Verity.swift
//  iChatGPT
//
//  Created by 宇都宮　誠 on R 7/05/25.
//

import SwiftUI

struct TOTP_VerityView: View {
    @Binding var navigationPath: NavigationPath
    @AppStorage("userId") var userId: Int?
    @State private var code: String = ""
    
    @State var isLoading = false
    @State var showAlert = false
    @State var alertMsg: String? = nil
    
    var body: some View {
        ZStack {
            VStack {
                CodeInputView(code: $code) { input in
                    print("code: ", input)
                    print("$code wrappedValue: ", $code.wrappedValue)
                    speakeasy_verify()
                }
                NavigationLink("二要素認証コードを設定", value: "CreateTOTP_Verity")
                
                .onAppear() {
                    print("userId", userId!)
                }
                .navigationTitle("二要素認証")
            }
            .commonAlert(text: "認証結果", show: $showAlert, message: alertMsg)
            LoadingOverlayView(isLoading: isLoading)
        }
    }
    
    func speakeasy_verify() {
        isLoading = true
        Request.request(url: "http://133.242.132.37:3001/iChatGPT/verify",
            body: [
                "userId": userId!,
                "token": $code.wrappedValue
            ],
            completion: { result in
                print("result: ", result)
                isLoading = false
                switch result {
                    case .success(let json):
                        print("json: ", json)
                        if let dict = json as? [String: Any],
                           let success = dict["success"] as? Int {
                            if (success != 1) {
                                alertMsg = "認証コードは正しくない"
                                showAlert = true
                            }
                        }
                        case .failure(let error):
                            print("❌ 請求失敗: \(error.localizedDescription)")
                            alertMsg = error.localizedDescription
                            showAlert = true
                }
            }
        )
    }
}
