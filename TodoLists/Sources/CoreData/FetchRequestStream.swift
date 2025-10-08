
import CoreData

/// A tiny, reusable wrapper that exposes any NSFetchRequest<T: NSManagedObject> as AsyncStream<[T]>,
/// powered by NSFetchedResultsController under the hood.
///
@MainActor
final class FetchRequestStream<T: NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate {
    private let frc: NSFetchedResultsController<T>
    private var continuation: AsyncStream<[T]>.Continuation?

    init(request: NSFetchRequest<T>, context: NSManagedObjectContext, sectionNameKeyPath: String? = nil) {
        self.frc = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: nil
        )
        super.init()
        frc.delegate = self
        try? frc.performFetch()
    }

    func stream() -> AsyncStream<[T]> {
        AsyncStream { continuation in
            self.continuation = continuation
            continuation.yield(self.frc.fetchedObjects ?? [])
            continuation.onTermination = { _ in
                Task { @MainActor in
                    self.clearReferences()
                }
            }
        }
    }
    
    private func clearReferences() {
        continuation = nil
        frc.delegate = nil
    }

    // Yield a new snapshot whenever content changes.
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        continuation?.yield(frc.fetchedObjects ?? [])
    }
}

/// Convenience factory for building a stream for a request/context pair.
func streamFetch<T: NSManagedObject>(
    request: NSFetchRequest<T>,
    context: NSManagedObjectContext
) -> AsyncStream<[T]> {
    FetchRequestStream(request: request, context: context).stream()
}
