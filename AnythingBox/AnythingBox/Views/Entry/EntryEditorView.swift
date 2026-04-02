import SwiftUI
import SwiftData
import PhotosUI

struct EntryEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \BoxCategory.sortOrder) private var categories: [BoxCategory]

    // 编辑已有 entry，或传 nil 新建
    let entry: Entry?

    @State private var title = ""
    @State private var content = ""
    @State private var selectedCategory: BoxCategory?
    @State private var tagsText = ""
    @State private var mood = ""
    @State private var isPinned = false

    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showingFilePicker = false
    @State private var showingMoodPicker = false
    @State private var isSaving = false

    private let moods = ["😊", "😔", "😤", "🤔", "😴", "🥳", "😰", "❤️", "💪", "🌟"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // 标题
                    TextField("标题（可选）", text: $title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                    Divider().padding(.horizontal)

                    // 正文
                    ZStack(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("写下任何你想记录的…")
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                        }
                        TextEditor(text: $content)
                            .frame(minHeight: 200)
                            .padding(.horizontal, 16)
                            .scrollDisabled(true)
                    }
                    .padding(.top, 8)

                    Divider().padding(.horizontal).padding(.top, 8)

                    // 元数据区
                    VStack(spacing: 0) {
                        // 分类选择
                        metaRow(icon: "folder", label: "分类") {
                            Picker("分类", selection: $selectedCategory) {
                                Text("无").tag(Optional<BoxCategory>.none)
                                ForEach(categories) { cat in
                                    Label(cat.name, systemImage: cat.iconName).tag(Optional(cat))
                                }
                            }
                            .labelsHidden()
                            .tint(.secondary)
                        }

                        Divider().padding(.leading, 44)

                        // 心情
                        metaRow(icon: "face.smiling", label: "心情") {
                            Button {
                                showingMoodPicker.toggle()
                            } label: {
                                Text(mood.isEmpty ? "选择心情" : mood)
                                    .foregroundStyle(mood.isEmpty ? .secondary : .primary)
                            }
                        }

                        if showingMoodPicker {
                            moodPicker
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                        }

                        Divider().padding(.leading, 44)

                        // 标签
                        metaRow(icon: "tag", label: "标签") {
                            TextField("#标签，用空格分隔", text: $tagsText)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                        }

                        Divider().padding(.leading, 44)

                        // 置顶
                        metaRow(icon: "pin", label: "置顶") {
                            Toggle("", isOn: $isPinned)
                                .labelsHidden()
                        }
                    }
                    .padding(.top, 8)

                    // 附件区
                    attachmentSection
                        .padding(.top, 16)
                }
            }
            .navigationTitle(entry == nil ? "新建记录" : "编辑记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .fontWeight(.semibold)
                        .disabled(content.isEmpty && title.isEmpty)
                }
            }
        }
        .onAppear { loadEntry() }
    }

    private func metaRow<Content: View>(icon: String, label: String, @ViewBuilder trailing: () -> Content) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            trailing()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private var moodPicker: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
            ForEach(moods, id: \.self) { m in
                Button {
                    mood = m
                    showingMoodPicker = false
                } label: {
                    Text(m)
                        .font(.title2)
                        .padding(8)
                        .background(mood == m ? Color.purple.opacity(0.2) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private var attachmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("附件")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // 添加图片按钮
                    PhotosPicker(selection: $selectedPhotos, matching: .any(of: [.images, .videos])) {
                        attachmentAddButton(icon: "photo", label: "照片/视频")
                    }

                    // 添加文件按钮
                    Button {
                        showingFilePicker = true
                    } label: {
                        attachmentAddButton(icon: "doc", label: "文件")
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func attachmentAddButton(icon: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.purple)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 72, height: 72)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func loadEntry() {
        guard let entry else { return }
        title = entry.title
        content = entry.content
        selectedCategory = entry.category
        tagsText = entry.tags.joined(separator: " ")
        mood = entry.mood
        isPinned = entry.isPinned
    }

    private func save() {
        let tags = tagsText.split(separator: " ").map(String.init).filter { !$0.isEmpty }
        if let entry {
            entry.title = title
            entry.content = content
            entry.category = selectedCategory
            entry.tags = tags
            entry.mood = mood
            entry.isPinned = isPinned
            entry.updatedAt = Date()
        } else {
            let newEntry = Entry(
                title: title,
                content: content,
                tags: tags,
                isPinned: isPinned,
                mood: mood,
                category: selectedCategory
            )
            modelContext.insert(newEntry)
        }
        dismiss()
    }
}
