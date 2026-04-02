import SwiftUI
import SwiftData

struct SettingsView: View {
    @ObservedObject var llmService: MockLLMService
    @Query private var entries: [Entry]
    @Query private var categories: [BoxCategory]

    @AppStorage("llmMode") private var llmMode: String = "mock"
    @AppStorage("ollamaURL") private var ollamaURL: String = "http://localhost:11434"
    @AppStorage("ollamaModel") private var ollamaModel: String = "qwen2.5:4b"
    @AppStorage("systemPersona") private var systemPersona: String = "你是一个温暖的 AI 伙伴，用轻松、关心的语气和用户交流，给予情绪支持。"

    @State private var showingClearAlert = false
    @State private var showingAbout = false

    var body: some View {
        NavigationStack {
            Form {
                // 数据统计
                statsSection

                // AI 模型设置
                aiSection

                // AI 人设
                personaSection

                // 数据管理
                dataSection

                // 关于
                aboutSection
            }
            .navigationTitle("设置")
            .alert("确定清空所有数据？", isPresented: $showingClearAlert) {
                Button("取消", role: .cancel) {}
                Button("清空", role: .destructive) {
                    // 清空在实际实现中需要通过 modelContext
                }
            } message: {
                Text("此操作不可恢复，所有记录、分类和对话将被永久删除。")
            }
        }
    }

    private var statsSection: some View {
        Section("数据统计") {
            HStack {
                Label("记录总数", systemImage: "doc.text")
                Spacer()
                Text("\(entries.count) 条")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Label("分类数量", systemImage: "folder")
                Spacer()
                Text("\(categories.count) 个")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Label("总字数", systemImage: "character.cursor.ibeam")
                Spacer()
                Text("\(entries.reduce(0) { $0 + $1.content.count }) 字")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var aiSection: some View {
        Section {
            Picker("运行模式", selection: $llmMode) {
                Text("调试模式（Mock）").tag("mock")
                Text("Ollama 本地服务").tag("ollama")
                // Text("MLX Swift（Apple Silicon）").tag("mlx")  // 待实现
            }

            if llmMode == "ollama" {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ollama 地址")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("http://localhost:11434", text: $ollamaURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("模型名称")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("qwen2.5:4b", text: $ollamaModel)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }

            HStack {
                Label("当前状态", systemImage: "circle.fill")
                    .foregroundStyle(llmService.isAvailable ? .green : .orange)
                Spacer()
                Text(llmService.isAvailable ? "就绪" : "未连接")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("AI 模型")
        } footer: {
            if llmMode == "ollama" {
                Text("需要先在终端运行：ollama pull \(ollamaModel)")
                    .font(.caption)
            } else if llmMode == "mock" {
                Text("调试模式使用模拟回复，不需要真实模型")
                    .font(.caption)
            }
        }
    }

    private var personaSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("AI 人设提示词")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $systemPersona)
                    .frame(minHeight: 80)
                    .font(.subheadline)
            }
        } header: {
            Text("AI 人设")
        } footer: {
            Text("这段话会作为 AI 的系统提示，影响它的回复风格和人设")
                .font(.caption)
        }
    }

    private var dataSection: some View {
        Section("数据管理") {
            Button {
                // TODO: 导出数据
            } label: {
                Label("导出所有数据", systemImage: "square.and.arrow.up")
            }

            Button(role: .destructive) {
                showingClearAlert = true
            } label: {
                Label("清空所有数据", systemImage: "trash")
                    .foregroundStyle(.red)
            }
        }
    }

    private var aboutSection: some View {
        Section("关于") {
            HStack {
                Label("版本", systemImage: "info.circle")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Label("AnythingBox", systemImage: "shippingbox")
                Spacer()
                Text("你的私人记录空间")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }

            // MLX Swift 集成说明
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 8) {
                    Text("接入本地大模型（Apple Silicon）")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("1. 在 Xcode 中添加 Swift Package：\nhttps://github.com/ml-explore/mlx-swift-examples")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("2. 在 Services/LLMService.swift 中实现 MLXLLMService")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("3. 支持模型：Qwen2.5-4B、Llama-3.2-3B 等")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } label: {
                Label("本地 LLM 接入指南", systemImage: "cpu")
            }
        }
    }
}
