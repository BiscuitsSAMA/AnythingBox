import SwiftUI
import SwiftData

struct CategoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BoxCategory.sortOrder) private var categories: [BoxCategory]
    @Query private var allEntries: [Entry]

    @State private var showingEditor = false
    @State private var editingCategory: BoxCategory?
    @State private var selectedCategory: BoxCategory?

    var body: some View {
        NavigationStack {
            Group {
                if categories.isEmpty {
                    emptyState
                } else {
                    categoryGrid
                }
            }
            .navigationTitle("分类")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editingCategory = nil
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                CategoryEditorView(category: editingCategory)
            }
            .sheet(item: $selectedCategory) { cat in
                CategoryEntriesView(category: cat)
            }
        }
    }

    private var categoryGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(categories) { category in
                    CategoryCardView(
                        category: category,
                        entryCount: allEntries.filter { $0.category?.id == category.id }.count
                    )
                    .onTapGesture { selectedCategory = category }
                    .contextMenu {
                        Button("编辑", systemImage: "pencil") {
                            editingCategory = category
                            showingEditor = true
                        }
                        Button("删除", systemImage: "trash", role: .destructive) {
                            modelContext.delete(category)
                        }
                    }
                }
            }
            .padding()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("还没有分类")
                .font(.title2)
                .fontWeight(.medium)
            Text("创建分类来整理你的记录")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("创建分类") {
                showingEditor = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
        .padding()
    }
}

// MARK: - 分类卡片
struct CategoryCardView: View {
    let category: BoxCategory
    let entryCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: category.iconName)
                    .font(.title2)
                    .foregroundStyle(category.color)
                    .frame(width: 40, height: 40)
                    .background(category.color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Spacer()
                Text("\(entryCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(category.name)
                .font(.headline)
            Text("\(entryCount) 条记录")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - 分类内的记录列表
struct CategoryEntriesView: View {
    @Environment(\.dismiss) private var dismiss
    let category: BoxCategory
    @Query private var entries: [Entry]

    init(category: BoxCategory) {
        self.category = category
        _entries = Query(filter: #Predicate<Entry> { entry in
            entry.category?.id == category.id
        }, sort: \Entry.updatedAt, order: .reverse)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(entries) { entry in
                    EntryRowView(entry: entry)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(category.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}
