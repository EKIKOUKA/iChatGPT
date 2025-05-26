//
//  CodeInputView.swift
//  iChatGPT
//
//  Created by 宇都宮　誠 on R 7/05/25.
//

import SwiftUI

struct CodeInputView: View {
    @Binding var code: String
    var onCommit: ((String) -> Void)? = nil   // 6位時觸發
    @FocusState private var isFocused: Bool
    let maxDigits = 6
    @State private var alreadyCommitted = false
    
    var body: some View {
        VStack {
            HStack(spacing: 10) {
                ForEach(0..<maxDigits, id: \.self) { i in
                    ZStack {
                        RoundedRectangle(cornerRadius: 6).stroke(isFocused ? Color.blue : Color.gray, lineWidth: 2)
                            .frame(width: 40, height: 54)
                        Text(self.digit(at: i))
                            .font(.title)
                            .fontWeight(.semibold)
                    }
                }
            }
            // 隱藏的 TextField
            TextField("", text: Binding(
                get: { code },
                set: { newValue in
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered.count <= maxDigits {
                        code = filtered
                    } else {
                        code = String(filtered.prefix(maxDigits))
                    }
                    // ***在這裡自動通知**
                    // === 關鍵：只觸發一次
                    if code.count == maxDigits, !alreadyCommitted {
                        onCommit?(code)
                        alreadyCommitted = true
                        isFocused = false
                    }
                    // 只要減少就允許下次再觸發
                    if code.count < maxDigits, alreadyCommitted {
                        alreadyCommitted = false
                    }
                }
            ))
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .focused($isFocused)
            .opacity(0.01)
            .frame(width: 0, height: 0)
        }
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
        .onAppear { isFocused = true }
    }
    private func digit(at i: Int) -> String {
        guard i < code.count else { return "" }
        let idx = code.index(code.startIndex, offsetBy: i)
        return String(code[idx])
    }
}
