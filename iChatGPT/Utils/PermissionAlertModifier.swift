//
//  PermissionAlertModifier.swift
//  iChatGPT
//
//  Created by 宇都宮　誠 on R 7/05/11.
//

import SwiftUI

struct PermissionAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    var title: String
    var message: String

    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: $isPresented) {
                Button("設定を開く") {
                    /// 開啟系統設定畫面
                    if let appSettingsURL = URL(string: UIApplication.openSettingsURLString),
                       UIApplication.shared.canOpenURL(appSettingsURL) {
                        UIApplication.shared.open(appSettingsURL)
                    }
//                    PermissionManager.openSettings()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text(message)
            }
    }
}

extension View {
    func permissionAlert(isPresented: Binding<Bool>, title: String, message: String) -> some View {
        self.modifier(PermissionAlertModifier(isPresented: isPresented, title: title, message: message))
    }
}
