import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var llmService = MockLLMService()
    @State private var selectedTab: Tab = .home

    enum Tab {
        case home, categories, ai, settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("记录", systemImage: "square.and.pencil")
                }
                .tag(Tab.home)

            CategoryListView()
                .tabItem {
                    Label("分类", systemImage: "folder")
                }
                .tag(Tab.categories)

            AICompanionView(llmService: llmService)
                .tabItem {
                    Label("伙伴", systemImage: "bubble.left.and.bubble.right")
                }
                .tag(Tab.ai)

            SettingsView(llmService: llmService)
                .tabItem {
                    Label("设置", systemImage: "gearshape")
                }
                .tag(Tab.settings)
        }
        .tint(.purple)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Entry.self, BoxCategory.self, EntryAttachment.self, AIConversation.self, AIMessage.self], inMemory: true)
}
