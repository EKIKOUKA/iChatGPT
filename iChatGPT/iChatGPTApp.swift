//
//  iChatGPTApp.swift
//  iChatGPT
//
//  Created by EKI KOUKA on R 6/09/22.
//

import SwiftUI
import SwiftData

@main
struct iChatGPTApp: App {
    @State private var conversations: [Conversation] = [Conversation(title: "示例对话", messages: [])]
    @State private var selectedConversation: Conversation? = nil // 使用可选类型
    @Environment(\.colorScheme) var colorScheme //dark mode

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ChatListView()
        }
        .modelContainer(sharedModelContainer)
    }
    
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ChatListView()
        }
    }

}
