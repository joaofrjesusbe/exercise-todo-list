
import Foundation
internal import Combine

@MainActor
final class ListsViewModel: ObservableObject {
    @Published var lists: [TodoList] = []
    private let repo: ListRepository
    private var streamTask: Task<Void, Never>? = nil

    init(repo: ListRepository) { self.repo = repo }

    func start() {
        streamTask?.cancel()
        streamTask = Task { [weak self] in
            guard let self else { return }
            for await snapshot in repo.listsStream() {
                self.lists = snapshot
            }
        }
    }

    func stop() {
        streamTask?.cancel()
        streamTask = nil
    }

    func addList(title: String) async {
        _ = try? await repo.createList(title: title)
    }

    func delete(at offsets: IndexSet) async {
        for index in offsets { try? await repo.deleteList(lists[index].id) }
    }
}


