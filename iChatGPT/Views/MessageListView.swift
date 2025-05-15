//
//  MessageListView.swift
//  iChatGPT
//
//  Created by EKI KOUKA on R 6/10/03.
//

import Down
import SwiftUI
import AVFoundation

struct MessageListView: View {
    @ObservedObject var message: ChatMessage
    @State private var showControlBar = false
    @Environment(\.colorScheme) var colorScheme //dark mode

    var body: some View {
        HStack {
            if message.isUserMessage {
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(message.elements, id: \.content) { element in
                        renderElement(element)
                    }
                }
                .padding(10)
                .background(colorScheme == .dark ? Color(red: 33/255, green: 33/255, blue: 33/255) : Color(red: 242/255, green: 242/255, blue: 242/255))
                .cornerRadius(16)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal)
            
                .contextMenu {
                    Button(action: {
                        UIPasteboard.general.string = getMessageText(from: message.elements)
                    }) {
                        Text("コピーする")
                        Image(systemName: "doc.on.doc")
                    }
                }
            } else {
//                Text(message.text)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(message.elements, id: \.content) { element in
                        renderElement(element)
                    }
                }
//                .transition(.opacity) // 在進出時使用漸變動畫
                .padding(5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                .contextMenu {
                    Button(action: {
                        UIPasteboard.general.string = getMessageText(from: message.elements)
                    }) {
                        Text("コピーする")
                        Image(systemName: "doc.on.doc")
                    }
                    
                    Button(action: {
                        // 调用语音朗读功能
                        speakText(getMessageText(from: message.elements))
                    }) {
                        Text("音声で読み上げる")
                        Image(systemName: "speaker.wave.2.fill")
                    }
                }
                Spacer()
            }
        }
        .padding(.horizontal, 0)
        .padding(.vertical, 5) // 设置上下边距为 10
    }
    
    private func getMessageText(from elements: [MessageElement]) -> String {
        elements.map { $0.content }.joined(separator: "\n")
    }

    
    @ViewBuilder
    private func renderElement(_ element: MessageElement) -> some View {
        
        switch element.type {
            case .plainText:
                Text(element.content)
                    .foregroundColor(.primary)
            case .mathFormula:
                MathTextView(text: element.content)
            case .markdown:
                if #available(iOS 15.0, *) {
                    // 使用 AttributedString 的 Markdown 初始化器
                    if let attributedString = try? AttributedString(markdown: element.content) {
                        Text(attributedString)
                    } else {
                        Text(element.content)
                    }
                } else {
                    // 使用 Down 庫，將 Markdown 轉換為 NSAttributedString
                    if let markdownText = try? Down(markdownString: element.content).toAttributedString() {
                        // 使用自定義的 AttributedTextView 來顯示 NSAttributedString
                        AttributedTextView(attributedText: markdownText)
                    } else {
                        Text(element.content)
                            .foregroundColor(.primary)
                            .font(.system(size: 25))
                    }
                }
            case .code:
                // 显示代码块，使用等宽字体和特定样式
                ScrollView(.horizontal) {
                    Text(element.content)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.primary)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            case .imageURL:
                AsyncImage(url: URL(string: element.content)) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    ProgressView()
                }
            case .special:
                Text(element.content)
                    .foregroundColor(.primary)
        }
    }

    struct AttributedTextView: UIViewRepresentable {
        let attributedText: NSAttributedString

        func makeUIView(context: Context) -> UILabel {
            let label = UILabel()
            label.numberOfLines = 0 // 允許多行
            return label
        }

        func updateUIView(_ uiView: UILabel, context: Context) {
            uiView.attributedText = attributedText
        }
    }
    
    
    private func speakText(_ text: String) {
        // 实现语音朗读功能，比如使用AVSpeechSynthesizer
        let utterance = AVSpeechUtterance(string: text)
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
}

struct MessageListView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleMessage = ChatMessage(
            elements: [
                MessageElement(
                    type: .plainText,
                    content: """
                    「未だのAIはあまり賢くないね」這句日語的意思是「現在的AI還不是很聰明呢」。這裡對句子的語法做一個詳細分析：

                        1. **未だの (いまだの)**：
                           - 「未だ」是副詞，意思是「還」、「仍然」。
                           - 「の」是連接詞，用來修飾後面的名詞「AI」。

                        2. **AI (エーアイ)**：
                           - 是名詞，指的是「人工智慧」，在日語中通常用片假名表示。

                        3. **は**：
                           - 主題助詞，標示主題「AI」。

                        4. **あまり (あまり)**：
                           - 副詞，表示「不太」、「不是很」。

                        5. **賢くない (かしこくない)**：
                           - 「賢い」是形容詞，意思是「聰明」。
                           - 變形為否定形「賢くない」，即「不聰明」。

                        6. **ね**：
                           - 句尾語助詞，表示語氣的確認或輕微的感慨，讓對方知曉自己的感受。

                        整體句子的結構是：
                        - 主題（AI）+ 助詞（は）+ 副詞（あまり）+ 否定形（賢くない）+ 語氣助詞（ね）。

                        這句話表達出對現有AI技術的看法，認為它的智能水平還有待提高。
                    """
                )
            ],
            isUserMessage: false
        )

        return MessageListView(message: sampleMessage)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
