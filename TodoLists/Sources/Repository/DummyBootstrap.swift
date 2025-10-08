
import Foundation

enum DummyBootstrap {
    final class _NoRepo: ListRepository {
        func listsStream() -> AsyncStream<[TodoList]> { AsyncStream { $0.yield([]) } }
        func listStream(id: UUID) -> AsyncStream<TodoList?> { AsyncStream { $0.yield(nil) } }
        func remindersStream(for listId: UUID) -> AsyncStream<[Reminder]> { AsyncStream { $0.yield([]) } }

        func fetchLists() async throws -> [TodoList] { [] }
        func createList(title: String) async throws -> TodoList { .init(id: .init(), title: title, createdAt: .now, reminders: []) }
        func deleteList(_ id: UUID) async throws {}
        func renameList(_ id: UUID, title: String) async throws {}
        func addReminder(to listId: UUID, title: String, dueDate: Date?) async throws -> Reminder { .init(id: .init(), title: title, isDone: false, dueDate: dueDate) }
        func toggleReminder(_ reminderId: UUID) async throws {}
        func deleteReminder(_ reminderId: UUID) async throws {}
    }
    static let repo: ListRepository = _NoRepo()
}
