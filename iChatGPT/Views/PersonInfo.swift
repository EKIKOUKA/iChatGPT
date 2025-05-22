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
            "CN": "中国（支那、西朝鮮）"
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
            
            List {
                Picker("国籍", selection: $selectiedCountry) {
                    ForEach(isoCountries, id: \.code) { country in
                        Text(country.name).tag(country.code)
                    }
                }
//                    .pickerStyle(.wheel)
                .onChange(of: selectiedCountry) {
                    print(selectiedCountry)
                }
            }
        }
    }
}

struct PersonInfo_Previews: PreviewProvider {
    static var previews: some View {
        PersonInfoView()
    }
}
