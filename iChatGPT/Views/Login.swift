//
//  Login.swift
//  iChatGPT
//
//  Created by 宇都宮　誠 on R 7/05/25.
//

import SwiftUI

struct FormData {
    var username: String = ""
    var password: String = ""
}

struct Login: View {
    
    @AppStorage("userId") var userId: Int?
    @State private var formData = FormData()
    @FocusState private var passwordFieldIsFocused: Bool
    @State var visible = false
    @State private var usernameError: String? = nil
    @State private var passwordError: String? = nil

    @Binding var navigationPath: NavigationPath
    
    @State var isLoading = false
    @State var showAlert = false
    @State var alertMsg: String? = nil
    
    var body: some View {
        
        ZStack {
            
            VStack {
                
                Spacer()
                Text("アカンウトを登録")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, 40)
                
                TextField("ユーザーネーム", text: $formData.username)
                    .padding()
                    .keyboardType(.asciiCapable)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .background(Color(.systemBackground))
                    .cornerRadius(6)
                    .padding(.leading)
                    .padding(.trailing)
                    .onChange(of: formData.username) {
                        let filtered = formData.username.filter { $0.isASCII && !$0.isWhitespace }
                        if filtered != formData.username {
                            formData.username = filtered
                        }
                    }
                
                HStack {
                    Text(usernameError ?? "")
                        .foregroundStyle(.red)
                        .frame(height: 18)
                        .padding(.leading)
                    Spacer()
                }
                .padding(.leading)
                
                ZStack {
                    
                    VStack {
                        if visible {
                            TextField("パスワード", text: $formData.password)
                                .focused($passwordFieldIsFocused)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(6)
                        } else {
                            SecureField("パスワード", text: $formData.password)
                                .focused($passwordFieldIsFocused)
                                .textContentType(.password)
                                .autocapitalization(.none)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(6)
                        }
                        HStack {
                            Text(passwordError ?? "")
                                .foregroundStyle(.red)
                                .frame(height: 18)
                                .padding(.leading)
                            Spacer()
                        }
                    }
                    
                    HStack {
                        Spacer()
                        Button(action: {
                            visible.toggle()
                            passwordFieldIsFocused = true
                        }) {
                            Image(systemName: visible ? "eye.slash.fill" : "eye.fill")
                                .opacity(0.8)
                        }
                        .padding(.trailing, 12)
                        .padding(.top, -20)
                    }
                }
                .padding()
                
                Spacer()
                VStack() {
                    // Sign up button
                    Button(action: {
                        validate()
                    }) {
                        Text("登録")
                            .fontWeight(.bold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                }
            }
            
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("登録")
            
            .commonAlert(show: $showAlert, message: alertMsg)
            LoadingOverlayView(isLoading: isLoading)
        }
    }
    
    
    func validate(name: String) {
        // 範例檢查，帳號長度需 > 5，密碼需 > 6
        if name == formData.username {
            usernameError = name.count > 5 ? nil : "使用者名稱太短"
        }
        if name == formData.password {
            passwordError = name.count > 6 ? nil : "密碼太短"
        }
    }

    func validate() {
        validate(name: formData.username)
        validate(name: formData.password)

        if usernameError == nil && passwordError == nil {
            isLoading = true
            Request.request(url: "http://133.242.132.37:3001/iChatGPT/login",
                body: [
                    "user_name": formData.username,
                    "password": formData.password
                ],
                completion: { result in
                    print("result: ", result)
                    isLoading = false
                    switch result {
                        case .success(let json):
                            print("login json: ", json)
                            if let dict = json as? [String: Any],
                               let success = dict["success"] as? Int {
                                 if success == 1 {
                                    userId = dict["user_id"] as? Int
                                    navigationPath.append("TOTP")
                                 } else {
                                     alertMsg = dict["message"] as? String
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
}

struct PreviewLogin: PreviewProvider {
    static var previews: some View {
//        Login(, navigationPath: <#Binding<NavigationPath>#>)
    }
}
