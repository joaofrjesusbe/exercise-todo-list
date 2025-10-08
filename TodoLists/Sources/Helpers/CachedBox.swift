import SwiftUI
internal import Combine

@MainActor
final class CachedBox<T>: ObservableObject {
    @Published private(set) var value: T?

    func resolve(build: () -> T) -> T {
        if let existing = value { return existing }
        let newValue = build()
        // Defer publishing to avoid updating @Published during view updates
        if value == nil {
            Task { @MainActor in
                // Only set if still unset to avoid racing multiple callers
                if self.value == nil {
                    self.value = newValue
                }
            }
        }
        return newValue
    }

    // If you need to respond to changes (e.g., repo swap), you can reset:
    func reset() {
        value = nil
    }
}

