
import Foundation

protocol ListRepository {
    // Streams
    func listsStream() -> AsyncStream<[TodoList]>
    func listStream(id: UUID) -> AsyncStream<TodoList?>
    func remindersStream(for listId: UUID) -> AsyncStream<[Reminder]>

    // One-shot fetch
    func fetchLists() async throws -> [TodoList]

    // Mutations
    func createList(title: String) async throws -> TodoList
    func deleteList(_ id: UUID) async throws
    func renameList(_ id: UUID, title: String) async throws

    func addReminder(to listId: UUID, title: String, dueDate: Date?) async throws -> Reminder
    func toggleReminder(_ reminderId: UUID) async throws
    func deleteReminder(_ reminderId: UUID) async throws
}
