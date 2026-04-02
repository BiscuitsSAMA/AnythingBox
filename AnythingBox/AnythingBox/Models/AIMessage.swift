import Foundation
import SwiftData

enum ChatRole: String, Codable {
    case user
    case assistant
    case system
}

@Model
final class AIConversation {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var linkedEntryID: UUID?  // 可选：关联到某条记录

    @Relationship(deleteRule: .cascade, inverse: \AIMessage.conversation)
    var messages: [AIMessage]

    init(title: String = "新对话", linkedEntryID: UUID? = nil) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.linkedEntryID = linkedEntryID
        self.messages = []
    }

    var sortedMessages: [AIMessage] {
        messages.sorted { $0.createdAt < $1.createdAt }
    }
}

@Model
final class AIMessage {
    var id: UUID
    var role: ChatRole
    var content: String
    var createdAt: Date
    var conversation: AIConversation?

    init(role: ChatRole, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.createdAt = Date()
    }
}
