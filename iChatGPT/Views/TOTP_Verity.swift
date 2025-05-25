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
    @State private var codeStatus: String = ""
    
    var body: some View {
        CodeInputView(code: $code) { input in
            print("code: ", input)
            print("$code wrappedValue: ", $code.wrappedValue)
            speakeasy_verify()
        }
        Text(codeStatus)
        NavigationLink("TOTP確認コードを作成して", value: "CreateTOTP_Verity")
        
        .onAppear() {
            print("userId", userId!)
        }
        .navigationTitle("TOTPコードを認証")
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
