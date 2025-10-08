# Project Overview

This project is a Swift/SwiftUI application that uses Core Data for persistence and modern Swift Concurrency (async/await) for reactive data flows. 
A key architectural pattern in the codebase is bridging `NSFetchedResultsController` updates into `AsyncStream` so that SwiftUI views and view models can consume Core Data changes as an async sequence.

## Features
- SwiftUI UI layer with state-driven rendering
- Core Data persistence using `NSPersistentContainer`
- Reactive data streams via `AsyncStream` bridged from `NSFetchedResultsController`
- Clean separation between domain models and Core Data managed objects
- Background context merging with `automaticallyMergesChangesFromParent`

## Architecture
- UI: SwiftUI views bind to observable view models that consume async sequences.
- Data: A repository layer exposes domain-friendly APIs (e.g., `listsStream()`) that translate Core Data entities into domain types.
- Persistence: Core Data stack with `NSPersistentContainer`, using `NSManagedObjectContext` for reads/writes and `NSFetchedResultsController` for change observation.

## The AsyncStream Pattern

Below is the pattern used in this project to surface Core Data changes as an async sequence using NSFetchedResultsController. The helper `FetchRequestStream` wraps an `NSFetchRequest` and yields snapshots whenever results change:

```swift
import CoreData

// A repository method that streams Core Data entities using NSFetchedResultsController
final class CoreDataListRepository: ListRepository {
    private let context: NSManagedObjectContext

    init(container: NSPersistentContainer) {
        self.context = container.viewContext
        self.context.automaticallyMergesChangesFromParent = true
    }

    // Stream domain lists by bridging an NSFetchRequest through FetchRequestStream
    func listsStream() -> AsyncStream<[List]> {
        // Build an NSFetchRequest for the backing NSManagedObject (e.g., CDList)
        let request: NSFetchRequest<CDList> = CDList.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDList.title, ascending: true)]

        // Create a stream of managed objects using the helper
        let managedObjectsStream: AsyncStream<[CDList]> = streamFetch(request: request, context: context)

        // Map to domain models for presentation
        return AsyncStream { continuation in
            let task = Task { @MainActor in
                for await objects in managedObjectsStream {
                    let lists = objects.map(List.init(managedObject:))
                    continuation.yield(lists)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
