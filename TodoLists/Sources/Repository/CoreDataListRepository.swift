import Foundation
import CoreData

final class CoreDataListRepository: ListRepository {
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
    }

    // MARK: - Streams (FRC-backed)

    func listsStream() -> AsyncStream<[TodoList]> {
        let ctx = container.viewContext
        let req = NSFetchRequest<ListMO>(entityName: "ListMO")
        req.fetchBatchSize = 50
        req.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]

        return AsyncStream { continuation in
            let moStream = streamFetch(request: req, context: ctx)
            let task = Task {
                for await mos in moStream {
                    let domain: [TodoList] = await MainActor.run {
                        mos.map(Mappers.toDomain)
                    }
                    continuation.yield(domain)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func listStream(id: UUID) -> AsyncStream<TodoList?> {
        let ctx = container.viewContext
        let req = NSFetchRequest<ListMO>(entityName: "ListMO")
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        req.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        req.fetchLimit = 1

        return AsyncStream { continuation in
            let moStream = streamFetch(request: req, context: ctx)
            let task = Task {
                for await mos in moStream {
                    let domain: TodoList? = await MainActor.run {
                        mos.first.map(Mappers.toDomain)
                    }
                    continuation.yield(domain)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func remindersStream(for listId: UUID) -> AsyncStream<[Reminder]> {
        let ctx = container.viewContext
        let req = NSFetchRequest<ReminderMO>(entityName: "ReminderMO")
        req.predicate = NSPredicate(format: "list.id == %@", listId as CVarArg)
        req.fetchBatchSize = 50
        req.sortDescriptors = [NSSortDescriptor(key: "dueDate", ascending: true)]

        return AsyncStream { continuation in
            let moStream = streamFetch(request: req, context: ctx)
            let task = Task {
                for await mos in moStream {
                    let domain: [Reminder] = await MainActor.run {
                        mos.map(Mappers.toDomain)
                    }
                    continuation.yield(domain)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - One-shot fetch

    func fetchLists() async throws -> [TodoList] {
        let ctx = container.viewContext
        return try await ctx.perform {
            let req = NSFetchRequest<ListMO>(entityName: "ListMO")
            req.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
            let result = try ctx.fetch(req)
            return result
        }.map(Mappers.toDomain)
    }

    // MARK: - Mutations

    func createList(title: String) async throws -> TodoList {
        let ctx = container.viewContext
        return try await ctx.perform {
            let mo = ListMO(context: ctx)
            mo.id = UUID()
            mo.title = title
            mo.createdAt = Date()
            try ctx.save()
            return Mappers.toDomain(mo)
        }
    }

    func deleteList(_ id: UUID) async throws {
        let ctx = container.viewContext
        try await ctx.perform {
            let req = NSFetchRequest<ListMO>(entityName: "ListMO")
            req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            if let mo = try ctx.fetch(req).first {
                ctx.delete(mo)
                try ctx.save()
            }
        }
    }

    func renameList(_ id: UUID, title: String) async throws {
        let ctx = container.viewContext
        try await ctx.perform {
            let req = NSFetchRequest<ListMO>(entityName: "ListMO")
            req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            if let mo = try ctx.fetch(req).first {
                mo.title = title
                try ctx.save()
            }
        }
    }

    func addReminder(to listId: UUID, title: String, dueDate: Date?) async throws -> Reminder {
        let ctx = container.viewContext
        return try await ctx.perform {
            let listReq = NSFetchRequest<ListMO>(entityName: "ListMO")
            listReq.predicate = NSPredicate(format: "id == %@", listId as CVarArg)
            guard let list = try ctx.fetch(listReq).first else { throw NSError(domain: "ListNotFound", code: 404) }
            let rem = ReminderMO(context: ctx)
            rem.id = UUID()
            rem.title = title
            rem.isDone = false
            rem.dueDate = dueDate
            rem.list = list
            try ctx.save()
            return Mappers.toDomain(rem)
        }
    }

    func toggleReminder(_ reminderId: UUID) async throws {
        let ctx = container.viewContext
        try await ctx.perform {
            let req = NSFetchRequest<ReminderMO>(entityName: "ReminderMO")
            req.predicate = NSPredicate(format: "id == %@", reminderId as CVarArg)
            if let mo = try ctx.fetch(req).first {
                mo.isDone.toggle()
                try ctx.save()
            }
        }
    }

    func deleteReminder(_ reminderId: UUID) async throws {
        let ctx = container.viewContext
        try await ctx.perform {
            let req = NSFetchRequest<ReminderMO>(entityName: "ReminderMO")
            req.predicate = NSPredicate(format: "id == %@", reminderId as CVarArg)
            if let mo = try ctx.fetch(req).first {
                ctx.delete(mo)
                try ctx.save()
            }
        }
    }
}

