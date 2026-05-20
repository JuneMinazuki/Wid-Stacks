import Foundation

struct TodoItem: Codable, Identifiable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var completedAt: Date?
}
