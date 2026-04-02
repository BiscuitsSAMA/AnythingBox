import Foundation
import SwiftData

@Model
final class Entry {
    var id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var tags: [String]
    var isPinned: Bool
    var mood: String // emoji 或情绪描述
    var category: BoxCategory?

    @Relationship(deleteRule: .cascade, inverse: \EntryAttachment.entry)
    var attachments: [EntryAttachment]

    init(
        title: String = "",
        content: String = "",
        tags: [String] = [],
        isPinned: Bool = false,
        mood: String = "",
        category: BoxCategory? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
        self.tags = tags
        self.isPinned = isPinned
        self.mood = mood
        self.category = category
        self.attachments = []
    }

    var displayTitle: String {
        if !title.isEmpty { return title }
        let preview = content.prefix(30)
        return preview.isEmpty ? "无标题" : String(preview) + (content.count > 30 ? "..." : "")
    }
}
