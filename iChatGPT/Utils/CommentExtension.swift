//
//  CommentExtension.swift
//  iChatGPT
//
//  Created by 宇都宮　誠 on R 7/05/26.
//

import SwiftUI

extension View {
    func commonAlert(text: String? = nil , show: Binding<Bool>, message: String?) -> some View {
        self.alert(text ?? "失敗が起こった", isPresented: show) {
            Button("閉じる", role: .cancel) {}
        } message: {
            Text(message ?? "")
        }
    }
}
