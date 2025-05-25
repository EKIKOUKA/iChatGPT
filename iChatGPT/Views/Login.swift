//
//  Login.swift
//  iChatGPT
//
//  Created by 宇都宮　誠 on R 7/05/25.
//

import SwiftUI

struct FormData {
    var username: String = "a@yahoo.co.jp"
    var password: String = "test.101"
}

struct Login: View {
    
    @AppStorage("userId") var userId: Int?
    @State private var formData = FormData()
    @FocusState private var passwordFieldIsFocused: Bool
    @State var visible = false
    @State private var usernameError: String? = nil
    @State private var passwordError: String? = nil
    
    @State private var selectedScreen: String? = nil
//    @State private var navigationPath = NavigationPath()
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        VStack {
            Spacer()
            Text("Sign up a new account")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 40)
                
            TextField("Username", text: $formData.username)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(6)
                .padding(.leading)
                .padding(.trailing)

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
                        TextField("Password", text: $formData.password)
                            .focused($passwordFieldIsFocused)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(6)
                    } else {
                        SecureField("Password", text: $formData.password)
                            .focused($passwordFieldIsFocused)
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
                    Text("Sign up")
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

            Request.request(url: "http://133.242.132.37:3000/login",
                body: [
                    "user_name": formData.username,
                    "password": formData.password
                ]
            ) { result in
                switch result {
                    case .success(let json):
                        print("login json: ", json)
                        if let dict = json as? [String: Any],
                           let success = dict["success"] as? Int,
                           success == 1 {
                            userId = dict["user_id"] as? Int
                            navigationPath.append("TOTP")
                        }
                    case .failure(let error):
                        print("❌ 請求失敗: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct PreviewLogin: PreviewProvider {
    static var previews: some View {
//        Login(, navigationPath: <#Binding<NavigationPath>#>)
    }
}
