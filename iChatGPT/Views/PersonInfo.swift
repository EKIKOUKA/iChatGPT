//
//  PersonInfo.swift
//  iChatGPT
//
//  Created by 宇都宮　誠 on R 7/05/22.
//
import SwiftUI

struct PersonInfoView: View {
    
    @AppStorage("Country") var selectiedCountry = "JP"
    
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
 
        Form {
//            ModalSettingContent()
            List {
                Picker("国籍", selection: $selectiedCountry) {
                    ForEach(isoCountries, id: \.code) { country in
                        Text(country.name).tag(country.code)
                    }
                }
                // .pickerStyle(.wheel)
                .onChange(of: selectiedCountry) {
                    print(selectiedCountry)
                }
            }
        }
        
        .onAppear() {
//            getGoodsList()
            speakeasy_verify()
        }
        .navigationTitle("個人情報")
    }
    
    func getGoodsList() {
        Request.request(url: "http://133.242.132.37/table_sample/api/getGoodsList") { result in
            // print("result: ", result)
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
    }
    func speakeasy_verify() {
        Request.request(url: "http://133.242.132.37:3000/verify",
            body: [
              "userId": "10001",
              "token": "849515"
            ]
        ) { result in
            switch result {
                case .success(let json):
                    print("json: ", json)
                case .failure(let error):
                    print("❌ 請求失敗: \(error.localizedDescription)")
            }
        }
    }
}

struct PersonInfo_Previews: PreviewProvider {
    static var previews: some View {
        PersonInfoView()
    }
}
