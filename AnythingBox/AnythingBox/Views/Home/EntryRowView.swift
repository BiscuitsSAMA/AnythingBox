import SwiftUI

struct EntryRowView: View {
    let entry: Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(entry.displayTitle)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                if entry.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                if !entry.mood.isEmpty {
                    Text(entry.mood)
                        .font(.body)
                }
            }

            if !entry.content.isEmpty {
                Text(entry.content)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 8) {
                // 分类标签
                if let category = entry.category {
                    Label(category.name, systemImage: category.iconName)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(category.color.opacity(0.15))
                        .foregroundStyle(category.color)
                        .clipShape(Capsule())
                }

                // 附件指示
                if !entry.attachments.isEmpty {
                    Label("\(entry.attachments.count)", systemImage: "paperclip")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // 标签
                ForEach(entry.tags.prefix(2), id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption2)
                        .foregroundStyle(.purple.opacity(0.8))
                }

                Spacer()

                Text(entry.updatedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
