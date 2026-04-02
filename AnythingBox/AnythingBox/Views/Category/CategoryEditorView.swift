import SwiftUI
import SwiftData

struct CategoryEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let category: BoxCategory?

    @State private var name = ""
    @State private var selectedIcon = "folder"
    @State private var selectedColor = "#5E5CE6"

    private let icons = [
        "folder", "book.closed", "briefcase", "lightbulb", "heart",
        "graduationcap", "camera", "music.note", "gamecontroller", "airplane",
        "house", "cart", "dumbbell", "fork.knife", "car",
        "leaf", "pawprint", "globe", "star", "flame"
    ]

    private let colors = [
        "#5E5CE6", "#FF9F0A", "#30D158", "#FF375F", "#32ADE6",
        "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7",
        "#DDA0DD", "#98D8C8", "#F7DC6F", "#BB8FCE", "#82E0AA"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("名称") {
                    TextField("分类名称", text: $name)
                }

                Section("图标") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon ? Color(hex: selectedColor)?.opacity(0.2) ?? Color.purple.opacity(0.2) : Color(.systemGray6))
                                    .foregroundStyle(selectedIcon == icon ? (Color(hex: selectedColor) ?? .purple) : .secondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("颜色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(colors, id: \.self) { hex in
                            Button {
                                selectedColor = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex) ?? .purple)
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        if selectedColor == hex {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.white)
                                                .fontWeight(.bold)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // 预览
                Section("预览") {
                    HStack(spacing: 12) {
                        Image(systemName: selectedIcon)
                            .font(.title2)
                            .foregroundStyle(Color(hex: selectedColor) ?? .purple)
                            .frame(width: 44, height: 44)
                            .background((Color(hex: selectedColor) ?? .purple).opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        Text(name.isEmpty ? "分类名称" : name)
                            .font(.headline)
                    }
                }
            }
            .navigationTitle(category == nil ? "新建分类" : "编辑分类")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear { loadCategory() }
    }

    private func loadCategory() {
        guard let category else { return }
        name = category.name
        selectedIcon = category.iconName
        selectedColor = category.colorHex
    }

    private func save() {
        if let category {
            category.name = name.trimmingCharacters(in: .whitespaces)
            category.iconName = selectedIcon
            category.colorHex = selectedColor
        } else {
            let newCategory = BoxCategory(
                name: name.trimmingCharacters(in: .whitespaces),
                iconName: selectedIcon,
                colorHex: selectedColor,
                sortOrder: 0
            )
            modelContext.insert(newCategory)
        }
        dismiss()
    }
}
