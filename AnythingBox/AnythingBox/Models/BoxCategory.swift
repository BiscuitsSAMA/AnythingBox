import Foundation
import SwiftData
import SwiftUI

@Model
final class BoxCategory {
    var id: UUID
    var name: String
    var iconName: String   // SF Symbol name
    var colorHex: String
    var createdAt: Date
    var sortOrder: Int

    @Relationship(inverse: \Entry.category)
    var entries: [Entry]

    init(name: String, iconName: String = "folder", colorHex: String = "#5E5CE6", sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.createdAt = Date()
        self.sortOrder = sortOrder
        self.entries = []
    }

    var color: Color {
        Color(hex: colorHex) ?? .purple
    }
}

// MARK: - 预设分类
extension BoxCategory {
    static let presets: [(name: String, icon: String, hex: String)] = [
        ("日记", "book.closed", "#FF9F0A"),
        ("工作", "briefcase", "#30D158"),
        ("想法", "lightbulb", "#5E5CE6"),
        ("收藏", "heart", "#FF375F"),
        ("学习", "graduationcap", "#32ADE6"),
    ]
}

// MARK: - Color hex 扩展
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&int) else { return nil }
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }

    var hexString: String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
