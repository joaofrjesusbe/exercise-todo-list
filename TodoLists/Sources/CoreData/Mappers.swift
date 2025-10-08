
import Foundation

struct Mappers: Sendable {
    static func toDomain(_ mo: ListMO) -> TodoList {
        TodoList(
            id: mo.id,
            title: mo.title,
            createdAt: mo.createdAt,
            reminders: mo.reminders
                .sorted { $0.title < $1.title }
                .map { toDomain($0) }
        )
    }

    static func toDomain(_ mo: ReminderMO) -> Reminder {
        Reminder(id: mo.id, title: mo.title, isDone: mo.isDone, dueDate: mo.dueDate)
    }
}
