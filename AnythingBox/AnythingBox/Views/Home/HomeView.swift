import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Entry.isPinned, order: .reverse), SortDescriptor(\Entry.updatedAt, order: .reverse)])
    private var entries: [Entry]

    @State private var searchText = ""
    @State private var showingEditor = false
    @State private var selectedEntry: Entry?

    private var filteredEntries: [Entry] {
        guard !searchText.isEmpty else { return entries }
        return entries.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText) ||
            $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    emptyState
                } else {
                    entriesList
                }
            }
            .navigationTitle("AnythingBox")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "搜索记录…")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingEditor = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                EntryEditorView(entry: nil)
            }
            .sheet(item: $selectedEntry) { entry in
                EntryDetailView(entry: entry)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("还没有任何记录")
                .font(.title2)
                .fontWeight(.medium)
            Text("点击右上角 ✏️ 开始写下你的第一条记录")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("新建记录") {
                showingEditor = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
        .padding()
    }

    private var entriesList: some View {
        List {
            if !filteredEntries.filter(\.isPinned).isEmpty {
                Section("置顶") {
                    ForEach(filteredEntries.filter(\.isPinned)) { entry in
                        EntryRowView(entry: entry)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedEntry = entry }
                    }
                    .onDelete { offsets in deleteEntries(from: filteredEntries.filter(\.isPinned), offsets: offsets) }
                }
            }

            Section(filteredEntries.filter(\.isPinned).isEmpty ? "" : "全部") {
                ForEach(filteredEntries.filter { !$0.isPinned }) { entry in
                    EntryRowView(entry: entry)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedEntry = entry }
                }
                .onDelete { offsets in deleteEntries(from: filteredEntries.filter { !$0.isPinned }, offsets: offsets) }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func deleteEntries(from source: [Entry], offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(source[index])
            }
        }
    }
}
