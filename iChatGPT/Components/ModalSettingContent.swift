//
//  ModalSettingContent.swift
//  iChatGPT
//
//  Created by 宇都宮　誠 on R 7/05/24.
//

import SwiftUI

struct ModalSettingContent: View {
    @Binding var isShowingModal: Bool
    
    var body: some View {
        
        HStack {
            Text("宇都宮 誠")
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer() // 使用 Spacer() 将文本和图标分隔开
            
            Button(action: {
                isShowingModal = true // 设置状态为 true 显示模式视图
            }) {
                Image(systemName: "ellipsis") // SwiftUI 提供的菜单图标
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
            }
        }
        .frame(height: 10)
        .padding()
        //.background(Color(UIColor.systemGray6)) // 背景颜色
    }
}
