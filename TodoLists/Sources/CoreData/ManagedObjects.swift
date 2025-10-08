
import CoreData

@objc(ListMO)
final class ListMO: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var createdAt: Date
    @NSManaged var reminders: Set<ReminderMO>
}

@objc(ReminderMO)
final class ReminderMO: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var isDone: Bool
    @NSManaged var dueDate: Date?
    @NSManaged var list: ListMO
}
