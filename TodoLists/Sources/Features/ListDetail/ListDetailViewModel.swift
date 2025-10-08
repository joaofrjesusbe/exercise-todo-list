import SwiftUI
internal import Combine

@MainActor
final class ListDetailViewModel: ObservableObject {
    @Published var list: TodoList
    @Published var reminders: [Reminder] = []
    var repo: ListRepository
    private var listTask: Task<Void, Never>? = nil
    private var remTask: Task<Void, Never>? = nil

    init(list: TodoList, repo: ListRepository) {
        self.list = list
        self.repo = repo
    }

    func start() {
        listTask?.cancel()
        remTask?.cancel()

        listTask = Task { [weak self] in
            guard let self else { return }
            for await updated in repo.listStream(id: list.id) {
                if let updated { self.list = updated }
            }
        }

        remTask = Task { [weak self] in
            guard let self else { return }
            for await items in repo.remindersStream(for: list.id) {
                self.reminders = items
            }
        }
    }

    func stop() {
        listTask?.cancel(); listTask = nil
        remTask?.cancel(); remTask = nil
    }

    func addReminder(title: String, due: Date?) async {
        _ = try? await repo.addReminder(to: list.id, title: title, dueDate: due)
    }

    func toggle(_ remId: UUID) async {
        try? await repo.toggleReminder(remId)
    }

    func delete(remindersAt offsets: IndexSet) async {
        for idx in offsets { try? await repo.deleteReminder(reminders[idx].id) }
    }
}
