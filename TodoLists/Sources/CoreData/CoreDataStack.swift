
import Foundation
import CoreData

final class CoreDataStack {
    let container: NSPersistentContainer

    init(modelName: String, inMemory: Bool) {
        let model = CoreDataStack.makeModel()
        container = NSPersistentContainer(name: modelName, managedObjectModel: model)
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unresolved error: \(error)")
            }
        }
        self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        self.container.viewContext.automaticallyMergesChangesFromParent = true
    }

    static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // ListMO
        let listEntity = NSEntityDescription()
        listEntity.name = "ListMO"
        listEntity.managedObjectClassName = NSStringFromClass(ListMO.self)

        let listId = NSAttributeDescription()
        listId.name = "id"
        listId.attributeType = .UUIDAttributeType
        listId.isOptional = false

        let listTitle = NSAttributeDescription()
        listTitle.name = "title"
        listTitle.attributeType = .stringAttributeType
        listTitle.isOptional = false

        let listCreatedAt = NSAttributeDescription()
        listCreatedAt.name = "createdAt"
        listCreatedAt.attributeType = .dateAttributeType
        listCreatedAt.isOptional = false

        listEntity.properties = [listId, listTitle, listCreatedAt]

        // ReminderMO
        let remEntity = NSEntityDescription()
        remEntity.name = "ReminderMO"
        remEntity.managedObjectClassName = NSStringFromClass(ReminderMO.self)

        let remId = NSAttributeDescription()
        remId.name = "id"
        remId.attributeType = .UUIDAttributeType
        remId.isOptional = false

        let remTitle = NSAttributeDescription()
        remTitle.name = "title"
        remTitle.attributeType = .stringAttributeType
        remTitle.isOptional = false

        let remIsDone = NSAttributeDescription()
        remIsDone.name = "isDone"
        remIsDone.attributeType = .booleanAttributeType
        remIsDone.isOptional = false
        remIsDone.defaultValue = false

        let remDue = NSAttributeDescription()
        remDue.name = "dueDate"
        remDue.attributeType = .dateAttributeType
        remDue.isOptional = true

        // Relationships
        let relReminders = NSRelationshipDescription()
        relReminders.name = "reminders"
        relReminders.destinationEntity = remEntity
        relReminders.minCount = 0
        relReminders.maxCount = 0 // to-many
        relReminders.deleteRule = .cascadeDeleteRule

        let relList = NSRelationshipDescription()
        relList.name = "list"
        relList.destinationEntity = listEntity
        relList.minCount = 1
        relList.maxCount = 1
        relList.deleteRule = .nullifyDeleteRule

        relReminders.inverseRelationship = relList
        relList.inverseRelationship = relReminders

        listEntity.properties.append(relReminders)
        remEntity.properties = [remId, remTitle, remIsDone, remDue, relList]

        model.entities = [listEntity, remEntity]
        return model
    }
}
