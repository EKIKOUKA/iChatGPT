//
//  ChatDetailView.swift
//  iChatGPT
//
//  Created by EKI KOUKA on R 6/10/21.
//  first create on R 6/09/22.

import SwiftUI

struct ChatDetailView: View {
    @State private var lightFeedbackGenerator = UIImpactFeedbackGenerator(style: .light) // 震動
    @Binding var navigationPath: NavigationPath // 传入Binding类型navigationPath
    @Binding var selectedConversationId: UUID? //更新选中的ID
    @Binding var conversations: [Conversation] // 从父视图传入
    @Binding var selectedConversation: Conversation?
    @ObservedObject var conversation: Conversation
    @State private var inputText: String = ""
    @State private var mediaFileOnlineAddress: String? = nil
    @State private var completeMessage = "" // 定义一个状态变量来保存完整的消息内容
    @State private var shouldScrollToBottom = true //  用于控制是否自动滚动到底部
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme //dark mode

    private let chatGPTAIChatAPI = ChatGPTAIChatAPI()

    var body: some View {
        VStack {
            /* HStack {// 顶部工具栏，包含返回按钮和添加会话按钮
                 Button(action: {
                 // 清除选中的对话，返回到列表页
                 selectedConversation = nil
                 if navigationPath.count > 1 {
                 navigationPath.removeLast() // 保证路径不再返回到会话页
                 } else {
                 presentationMode.wrappedValue.dismiss()
                 }
                 }) {
                 Image(systemName: "chevron.left").padding()
                 }
                 Spacer()
                 
                 Button(action: {
                 createNewConversation()
                 }) {
                 Text("新しい会話")
                 }.padding()
             } */
            
            ScrollViewReader { proxy in
                // 显示聊天记录
                ScrollView {
                    VStack(spacing: 8) { // 使用VStack来将所有消息垂直排列
                        if conversation.messages.isEmpty {
                            VStack(alignment: .center) {
                                // 创建一个盒子
                                Rectangle()
                                    .fill(Color.clear) // 设置盒子的颜色和透明度
                                    .frame(height: 200) // 设置盒子的高度
                                Spacer()
                                Image("ChatGPT_icon")
                                    .resizable()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.gray)
                                // 使用 NavigationLink 实现跳转
                                /* NavigationLink(destination: VideoTranscriptionView()) {
                                    Text("跳转到视频识别页面")
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                } */
                                Spacer()
                            }
                        } else {
                            ForEach(conversation.messages) { message in
                                MessageListView(message: message)
                                    .id(message.id) // 标记消息的唯一ID，以便于滚动
                            }
                        }
                    }
                    .padding(.horizontal, 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // 占满可用空间
                    .onChange(of: conversation.messages) {
                        if shouldScrollToBottom {
                            scrollToBottom(proxy: proxy)
                        }
                    }
                    .onAppear {
                        scrollToBottom(proxy: proxy)
                    }
                }
                /*.simultaneousGesture(
                     DragGesture().onEnded { _ in
                         shouldScrollToBottom = false
                         print("User scrolled, disable auto-scrolling")
                     }
                 )*/
                .onTapGesture {
                   self.hideKeyboard()
                }
            }
            
            // 输入框
            ChatInputView(inputText: $inputText, onSend: sendMessage, mediaFileOnlineAddress: $mediaFileOnlineAddress)
        }
        .background(Color.clear)
        /* 使用透明背景，这样点击事件不会被消耗而无法传递给容器。防止背景消耗点击事件
            .onTapGesture {
               self.hideKeyboard()
            }
         */
        .toolbar {
            /* ToolbarItem(placement: .topBarLeading) {
                HStack() {
                    Button(action: {
                        // 在此處添加返回按鈕的點擊處理程式
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                }
            } */
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 5) {
                    /* Button(action: createNewConversation) {
                        Image(systemName: "waveform.circle.fill")
                            .frame(width: 30, height: 30)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    } */
                    Button(action: createNewConversation) {
                        Image(systemName: "bubble.and.pencil")
                            .font(.system(size: 14))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                }
            }
        }
        .navigationTitle("iChatGPT")
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = conversation.messages.last {
            proxy.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }

    // 添加新会话的方法
    func createNewConversation() {
        // 创建一个新的空会话
        let newConversation = Conversation(title: "", messages: [])
        // 将新会话添加到列表中
        conversations.append(newConversation)
        // 更新选中的会话
//        DispatchQueue.main.async {
            // 设置选中的会话为新会话，并导航
            selectedConversationId = newConversation.id
            selectedConversation = newConversation
//        }
        // 清空当前导航路径
        navigationPath.removeLast(navigationPath.count) // 清空导航堆栈
        // 使用导航路径来确保视图切换
        navigationPath.append(newConversation)
    }

    private func sendMessage() {
        guard !inputText.isEmpty || mediaFileOnlineAddress != nil else { return }
        print("mediaFileOnlineAddress: ", mediaFileOnlineAddress)
        var userElements: [MessageElement] = []
        // 加入文字
        if !inputText.isEmpty {
            userElements.append(MessageElement(type: .plainText, content: inputText))
        }
        // 加入圖片（如果有）
        if let imageData = mediaFileOnlineAddress {
            userElements.append(MessageElement(type: .imageURL, content: imageData))
        }
        let userMessage = ChatMessage(
            elements: userElements,
            isUserMessage: true
        )
        
//        let userMessage = ChatMessage(
//            elements: [MessageElement(type: .plainText, content: inputText)],
//            isUserMessage: true
//        )
        conversation.messages.append(userMessage)
        if conversation.title.isEmpty { conversation.title = inputText }
        inputText = ""
        hideKeyboard()
        
        let botMessage = ChatMessage(
            elements: [],
            isUserMessage: false
        )
        conversation.messages.append(botMessage)
        
        shouldScrollToBottom = true
        lightFeedbackGenerator.prepare()
        
        chatGPTAIChatAPI.callChatGPTAPI(for: conversation, mediaFileOnlineAddress: mediaFileOnlineAddress, onUpdate: { elements in
            DispatchQueue.main.async {
                self.updateChatGPTMessage(elements: elements)
                
                // 在新的响应数据到达时，触发轻度震动 バイブレーション
                self.lightFeedbackGenerator.impactOccurred()
                self.mediaFileOnlineAddress = nil // 清除圖片資料
            }
        })
    }
    
    private func updateChatGPTMessage(elements: [MessageElement]) {
        print("更新的 MessageElement 為: \(elements)") // 調試日誌
        if let lastIndex = conversation.messages.indices.last {
//            withAnimation(.easeIn(duration: 0.4)) { // 漸顯動畫
                conversation.messages[lastIndex].elements = elements
//            }
        }
    }
}

// 隱藏鍵盤的擴展
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
