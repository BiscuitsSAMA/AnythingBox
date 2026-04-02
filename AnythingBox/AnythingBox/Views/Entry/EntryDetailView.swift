import SwiftUI
import SwiftData

struct EntryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let entry: Entry

    @State private var showingEditor = false
    @State private var showingAIAnalysis = false
    @State private var analysisResult = ""
    @State private var isAnalyzing = false
    @State private var selectedAnalysis: AnalysisTask?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 标题 + 心情
                    HStack(alignment: .firstTextBaseline) {
                        if !entry.title.isEmpty {
                            Text(entry.title)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        Spacer()
                        if !entry.mood.isEmpty {
                            Text(entry.mood)
                                .font(.title)
                        }
                    }

                    // 元数据
                    HStack(spacing: 12) {
                        Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let category = entry.category {
                            Label(category.name, systemImage: category.iconName)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(category.color.opacity(0.15))
                                .foregroundStyle(category.color)
                                .clipShape(Capsule())
                        }
                    }

                    // 标签
                    if !entry.tags.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(entry.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .foregroundStyle(.purple.opacity(0.8))
                            }
                        }
                    }

                    Divider()

                    // 正文
                    Text(entry.content)
                        .font(.body)
                        .lineSpacing(6)
                        .textSelection(.enabled)

                    // AI 分析区
                    if !analysisResult.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Divider()
                            Label("AI 分析", systemImage: "sparkles")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.purple)
                            Text(analysisResult)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color.purple.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // 字数统计
                    wordStats

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("编辑") {
                        showingEditor = true
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Menu {
                        aiAnalysisMenu
                        Divider()
                        Button(entry.isPinned ? "取消置顶" : "置顶", systemImage: entry.isPinned ? "pin.slash" : "pin") {
                            entry.isPinned.toggle()
                            entry.updatedAt = Date()
                        }
                        Button("删除", systemImage: "trash", role: .destructive) {
                            modelContext.delete(entry)
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                EntryEditorView(entry: entry)
            }
        }
    }

    private var wordStats: some View {
        let charCount = entry.content.count
        let wordCount = entry.content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let lineCount = entry.content.components(separatedBy: "\n").count

        return HStack(spacing: 20) {
            statItem(value: "\(charCount)", label: "字符")
            statItem(value: "\(wordCount)", label: "词")
            statItem(value: "\(lineCount)", label: "行")
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var aiAnalysisMenu: some View {
        Button("文字校对", systemImage: "checkmark.circle") {
            runAnalysis(.proofread)
        }
        Button("情绪分析", systemImage: "heart.text.clipboard") {
            runAnalysis(.sentiment)
        }
        Button("内容摘要", systemImage: "text.quote") {
            runAnalysis(.summarize)
        }
        Button("建议分类", systemImage: "folder.badge.questionmark") {
            runAnalysis(.suggestCategory)
        }
    }

    private func runAnalysis(_ task: AnalysisTask) {
        // LLMService 通过环境注入（在真实场景中），这里先做占位
        analysisResult = "正在分析中…"
    }
}
