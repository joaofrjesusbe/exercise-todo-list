
import SwiftUI
import CoreData
internal import Combine

@main
struct TodoListsApp: App {
    @StateObject private var appEnv = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            ListsRootView()
                .environmentObject(appEnv)
        }
    }
}

final class AppEnvironment: ObservableObject {
    @Published var isStarting = true
    
    let stack: CoreDataStack
    let listRepository: ListRepository

    init(inMemory: Bool = false) {
        self.stack = CoreDataStack(modelName: "TodoLists", inMemory: inMemory)
        self.listRepository = CoreDataListRepository(container: stack.container)
        seedIfNeeded()
    }

    private func seedIfNeeded() {
        Task { @MainActor in
            let lists = try? await listRepository.fetchLists()
            if lists?.isEmpty == true {
                let _ = try? await listRepository.createList(title: "Personal")
                let work = try? await listRepository.createList(title: "Work")
                if let workId = work?.id {
                    _ = try? await listRepository.addReminder(to: workId, title: "Send status report", dueDate: Date().addingTimeInterval(3600 * 24))
                }
            }
        }
    }
}
