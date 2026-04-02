import Foundation
import SwiftData

enum AttachmentType: String, Codable {
    case image
    case video
    case file
    case audio
}

@Model
final class EntryAttachment {
    var id: UUID
    var type: AttachmentType
    var filename: String
    var mimeType: String
    var fileSize: Int64
    var createdAt: Date
    var entry: Entry?

    // 存储路径（相对于 App Documents 目录）
    var relativePath: String

    init(type: AttachmentType, filename: String, mimeType: String = "", fileSize: Int64 = 0, relativePath: String) {
        self.id = UUID()
        self.type = type
        self.filename = filename
        self.mimeType = mimeType
        self.fileSize = fileSize
        self.relativePath = relativePath
        self.createdAt = Date()
    }

    var fileURL: URL? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return docs?.appendingPathComponent(relativePath)
    }

    var fileSizeString: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}
