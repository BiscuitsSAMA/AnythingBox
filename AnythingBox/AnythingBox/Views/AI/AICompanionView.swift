import SwiftUI
import SwiftData

struct AICompanionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AIConversation.updatedAt, order: .reverse) private var conversations: [AIConversation]

    @ObservedObject var llmService: MockLLMService

    @State private var showingNewChat = false
    @State private var activeConversation: AIConversation?

    var body: some View {
        NavigationStack {
            Group {
                if conversations.isEmpty {
                    emptyState
                } else {
                    conversationList
                }
            }
            .navigationTitle("AI 伙伴")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        startNewConversation()
                    } label: {
                        Image(systemName: "plus.bubble")
                    }
                }
            }
            .sheet(item: $activeConversation) { conversation in
                ChatView(conversation: conversation, llmService: llmService)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundStyle(.purple.opacity(0.6))
            Text("你好，我是你的 AI 伙伴")
                .font(.title2)
                .fontWeight(.semibold)
            Text("我可以帮你校对文字、分析情绪、整理想法，\n也可以陪你聊天，给你情绪价值 ❤️")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("开始对话") {
                startNewConversation()
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
        .padding()
    }

    private var conversationList: some View {
        List {
            ForEach(conversations) { conversation in
                Button {
                    activeConversation = conversation
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(conversation.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if let last = conversation.sortedMessages.last {
                            Text(last.content)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Text(conversation.updatedAt, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    modelContext.delete(conversations[index])
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func startNewConversation() {
        let conversation = AIConversation(title: "新对话")
        modelContext.insert(conversation)
        activeConversation = conversation
    }
}

// MARK: - 聊天界面
struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var conversation: AIConversation
    @ObservedObject var llmService: MockLLMService

    @State private var inputText = ""
    @State private var isGenerating = false
    @State private var streamingContent = ""
    @State private var scrollProxy: ScrollViewProxy?

    private var sortedMessages: [AIMessage] {
        conversation.messages.sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 模型状态栏
                modelStatusBar

                // 消息列表
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // 欢迎消息
                            if sortedMessages.isEmpty {
                                welcomeMessage
                            }

                            ForEach(sortedMessages) { message in
                                MessageBubbleView(message: message)
                                    .id(message.id)
                            }

                            // 流式输出中的消息
                            if isGenerating {
                                streamingBubble
                                    .id("streaming")
                            }
                        }
                        .padding()
                    }
                    .onAppear { scrollProxy = proxy }
                    .onChange(of: sortedMessages.count) {
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: streamingContent) {
                        scrollToBottom(proxy: proxy)
                    }
                }

                Divider()

                // 输入区
                inputBar
            }
            .navigationTitle(conversation.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private var modelStatusBar: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(llmService.isAvailable ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
            Text(llmService.modelName)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
    }

    private var welcomeMessage: some View {
        VStack(spacing: 12) {
            Text("👋")
                .font(.system(size: 50))
            Text("嗨！我是你的 AI 伙伴")
                .font(.headline)
            Text("有什么我可以帮你的吗？")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // 快捷提示
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickPrompts, id: \.self) { prompt in
                        Button(prompt) {
                            inputText = prompt
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.purple.opacity(0.1))
                        .foregroundStyle(.purple)
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .multilineTextAlignment(.center)
    }

    private let quickPrompts = [
        "今天有什么新鲜事可以聊聊",
        "帮我整理一下最近的想法",
        "给我一些写作灵感",
        "陪我聊聊天",
        "帮我放松一下"
    ]

    private var streamingBubble: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundStyle(.purple)
                .frame(width: 32, height: 32)
                .background(Color.purple.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(streamingContent.isEmpty ? "思考中…" : streamingContent)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .animation(.default, value: streamingContent)
            }
            Spacer()
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("和 AI 伙伴说点什么…", text: $inputText, axis: .vertical)
                .lineLimit(1...5)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))

            Button {
                if isGenerating {
                    // TODO: cancel
                } else {
                    sendMessage()
                }
            } label: {
                Image(systemName: isGenerating ? "stop.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(inputText.isEmpty && !isGenerating ? .secondary : .purple)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty && !isGenerating)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        let userMessage = AIMessage(role: .user, content: text)
        conversation.messages.append(userMessage)
        conversation.updatedAt = Date()

        // 自动命名对话
        if conversation.title == "新对话" && !text.isEmpty {
            conversation.title = String(text.prefix(20))
        }

        inputText = ""
        isGenerating = true
        streamingContent = ""

        Task {
            do {
                let history = sortedMessages.map { ChatMessage(role: $0.role, content: $0.content) }
                let stream = try await llmService.chat(messages: history)

                var fullResponse = ""
                for try await chunk in stream {
                    fullResponse += chunk
                    await MainActor.run {
                        streamingContent = fullResponse
                    }
                }

                await MainActor.run {
                    let assistantMessage = AIMessage(role: .assistant, content: fullResponse)
                    conversation.messages.append(assistantMessage)
                    conversation.updatedAt = Date()
                    isGenerating = false
                    streamingContent = ""
                }
            } catch {
                await MainActor.run {
                    let errorMessage = AIMessage(role: .assistant, content: "抱歉，出了点问题：\(error.localizedDescription)")
                    conversation.messages.append(errorMessage)
                    isGenerating = false
                    streamingContent = ""
                }
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.3)) {
            if isGenerating {
                proxy.scrollTo("streaming", anchor: .bottom)
            } else if let last = sortedMessages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - 消息气泡
struct MessageBubbleView: View {
    let message: AIMessage

    var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if isUser {
                Spacer()
            } else {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                    .frame(width: 32, height: 32)
                    .background(Color.purple.opacity(0.1))
                    .clipShape(Circle())
            }

            Text(message.content)
                .padding(12)
                .background(isUser ? Color.purple : Color(.systemGray6))
                .foregroundStyle(isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .textSelection(.enabled)

            if !isUser {
                Spacer()
            } else {
                Image(systemName: "person.circle.fill")
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
            }
        }
    }
}
