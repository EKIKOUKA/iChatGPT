//
//  ContentView.swift
//  iChatGPT
//
//  Created by EKI KOUKA on R 6/09/22.
//

import SwiftUI
import SwiftData
import Combine


enum MessageElementType {
    case plainText // 普通文本
    case mathFormula // 数学公式
    case markdown // Markdown格式语法
    case code // code
    case imageURL
    case special
}

struct MessageElement {
    let type: MessageElementType
    let content: String
}

class ChatMessage: Identifiable, Hashable, ObservableObject {
    let id = UUID()
    @Published var elements: [MessageElement]
    let isUserMessage: Bool

    init(elements: [MessageElement], isUserMessage: Bool) {
        self.elements = elements
        self.isUserMessage = isUserMessage
    }

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


class Conversation: Identifiable, Hashable, ObservableObject {
    let id = UUID()
    var title: String
    @Published var messages: [ChatMessage] = [] // 使用 @Published 以便监控消息数组的变化
    
    init(title: String, messages: [ChatMessage] = []) {
        self.title = title
        self.messages = messages
    }
    
    static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


struct ChatListView: View {
    @State private var selectedConversationId: UUID? = nil // 使用 UUID 而不是対象本身
    @State private var conversations: [Conversation] = []
    @State private var selectedConversation: Conversation? = nil // 選中対話状態変量
    @State private var inputText: String = "" // 存儲用戶入力的文本

    @State private var renamingState: (isRenaming: Bool, newTitle: String, conversationToRename: Conversation?) = (false, "", nil) // isRenaming控制是否顯示重命名的弾窗 newTitle保存新的対話標題
    @State private var navigationPath = NavigationPath() // 新増増状态変量
    @State private var isShowingDeleteConfirmation = false // 新増状態変量
    @State private var conversationToDelete: Conversation? = nil // 保存即將刪除的対話
    @State private var isShowingModal = false // 用于控制模式视图的显示状态

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                List(selection: $selectedConversation) {
                    ForEach(conversations.reversed(), id: \.id) { conversation in
                        NavigationLink(
                            tag: conversation.id,
                            selection: $selectedConversationId
                        ) {
                            ChatDetailView(
                                navigationPath: $navigationPath,
                                selectedConversationId: $selectedConversationId,
                                conversations: $conversations,
                                selectedConversation: $selectedConversation,
                                conversation: conversation
                            )
                        } label: {
                            Text(conversation.title.isEmpty ? "新し会話" : conversation.title)
                        }
                        .contextMenu {
                            if conversations.count > 1 { // 確保不允許刪除最後一個会話
                                Button(role: .destructive) {
                                    conversationToDelete = conversation // 設置即将刪除的対話
                                    isShowingDeleteConfirmation = true // 顯示刪除確認弾窗
                                } label: {
                                    Label("削除する", systemImage: "trash")
                                }
                            }

                            Button {
                                // 显示重命名弾窗 初始化重命名文本框的值 保存当前要重命名的対話
                                renamingState = (true, conversation.title, conversation)
                            } label: {
                                Label("名前を変更する", systemImage: "pencil")
                            }
                        }
                        .alert("チャットの名前を変更する", isPresented: $renamingState.isRenaming) {
                            TextField("新标题", text: $renamingState.newTitle)
                            Button("OK", action: {
                                if let conversation = renamingState.conversationToRename {
                                    renameConversation(conversation: conversation)
                                }
                            })
                            Button("キャンセルする", role: .cancel, action: {})
                        }
                        .confirmationDialog("会話を削除しますか？", isPresented: $isShowingDeleteConfirmation, titleVisibility: .visible) {
                            Button("削除する", role: .destructive) {
                                if let conversation = conversationToDelete {
                                    deleteConversation(conversation)
                                }
                            }
                            Button("キャンセルする", role: .cancel) {
                                isShowingDeleteConfirmation = false
                            }
                        } message: {
                            Text("この操作は元に戻せません。")
                        }
                    }
                }
                
                // 添加底部栏
                ModalSettingContent(isShowingModal: $isShowingModal) // 传递状态绑定
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("会話リスト")
            .navigationDestination(for: Conversation.self) { conversation in
                ChatDetailView(
                   navigationPath: $navigationPath,
                   selectedConversationId: $selectedConversationId,
                   conversations: $conversations,
                   selectedConversation: $selectedConversation,
                   conversation: conversation
                )
            }
            .onAppear {
                if conversations.isEmpty {
                    let newConversation = Conversation(title: "", messages: [])
                    conversations.append(newConversation)
                    DispatchQueue.main.async {
                        if selectedConversation == nil {
                            selectedConversation = newConversation
                            navigationPath.append(newConversation)
                        }
                    }
                }
            }
        }
        // 当選択的対話変化時，確保導航到対應的対話詳情頁面
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $isShowingModal) {
            // Here is the content of the modal view
            ModalContentView(isShowingModal: $isShowingModal) // 传递状態绑定
        }
    }

    // 削除対話
    private func deleteConversation(_ conversation: Conversation) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations.remove(at: index)
        }
        if selectedConversation?.id == conversation.id {
            selectedConversation = conversations.first
        }
    }
    // 重命名対話
    private func renameConversation(conversation: Conversation) {
        guard let index = conversations.firstIndex(where: { $0.id == conversation.id }) else { return }
        conversations[index].title = renamingState.newTitle
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ChatListView()
    }
}
