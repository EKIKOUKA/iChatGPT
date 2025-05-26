//
//  PersonInfo.swift
//  iChatGPT
//
//  Created by 宇都宮　誠 on R 7/05/22.
//
import SwiftUI

struct PersonInfoView: View {
    
    @AppStorage("Country") var selectedCountry = "JP"
    @Binding var navigationPath: NavigationPath
    
    @State var isLoading = false
    @State var showAlert = false
    @State var alertMsg: String? = nil
    
    let isoCountries: [(code: String, name: String)] = {
        let overrides: [String: String] = [
            "TW": "台湾（中華民国）",
            "CN": "中国（支那、西朝鮮）",
            "JP": "大日本帝国"
        ]
        
        return Locale.Region.isoRegions.compactMap { region in
            let code = region.identifier
            guard code.count == 2 else { return nil }
            let name = overrides[code] ?? Locale.current.localizedString(forRegionCode: code)
            if let name = name {
                return (code: code, name: name)
            }
            return nil
        }
    } ()
    
    var body: some View {
        ZStack {
            VStack {
                List {
                    Picker("国籍", selection: $selectedCountry) {
                        ForEach(isoCountries, id: \.code) { country in
                            Text(country.name).tag(country.code)
                        }
                    }
                    // .pickerStyle(.wheel)
                    .onChange(of: selectedCountry) {
                        print(selectedCountry)
                    }
                }
                
                NavigationLink(value: "Login") {
                    Text("前往登入頁面")
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                }
                
                .onAppear() {
//                  getGoodsList()
                }
                .navigationTitle("個人情報")
            }
            .frame(maxHeight: .infinity, alignment: .center)
            
            .alert("失敗が起こった", isPresented: $showAlert) {
                Button("閉じる", role: .cancel) {}
            } message: {
                Text(alertMsg ?? "")
            }
            if isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .overlay(
                        ProgressView("ローディング中…")
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                    )
            }
        }
    }
    
    func getGoodsList() {
        Request.request(url: "http://133.242.132.37/table_sample/api/getGoodsList",
            onStart: {
                isLoading = true
            },
            onFailure: { errorMsg in
                isLoading = false
                alertMsg = errorMsg
                showAlert = true
            },
            completion: { result in
                print("result: ", result)
                isLoading = false
                switch result {
                    case .success(let json):
                        if let firstItem = (json as? [[String: Any]])?.first {
                            print("firstItem: {")
                            for (key, value) in firstItem {
                                print("     \(key): \(value)")
                            }
                            print("}")
                        }
                    case .failure(let error):
                        print("❌ 請求失敗: \(error.localizedDescription)")
                }
            }
        )
    }
}

struct PersonInfo_Previews: PreviewProvider {
    @Binding var navigationPath: NavigationPath
    static var previews: some View {
//        PersonInfoView(navigationPath: $navigationPath)
    }
}
