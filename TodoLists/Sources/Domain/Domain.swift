
import Foundation

struct TodoList: Identifiable, Equatable, Hashable {
    let id: UUID
    var title: String
    var createdAt: Date
    var reminders: [Reminder]
}

struct Reminder: Identifiable, Equatable, Hashable {
    let id: UUID
    var title: String
    var isDone: Bool
    var dueDate: Date?
}
