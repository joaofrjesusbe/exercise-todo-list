import SwiftUI

struct ListDetailRootView: View {
    @EnvironmentObject private var env: AppEnvironment
    private let list: TodoList
    @StateObject private var vmCache = CachedBox<ListDetailViewModel>()

    init(list: TodoList) {
        self.list = list
    }

    var body: some View {
        let vm = vmCache.resolve {
            ListDetailViewModel(list: list, repo: env.listRepository)
        }
        ListDetailView(vm: vm)
    }
}

struct ListDetailView: View {
    @StateObject private var vm: ListDetailViewModel
    @State private var isPresentingNewReminder: Bool = false
    @State private var newTitle: String = ""
    @State private var newHoursFromNow: String = ""

    init(vm: ListDetailViewModel) {
        _vm = StateObject(wrappedValue: vm)
    }

    var body: some View {
        List {
            Section {
                ForEach(vm.reminders) { r in
                    HStack {
                        Button(action: { Task { await vm.toggle(r.id) } }) {
                            Image(systemName: r.isDone ? "checkmark.circle.fill" : "circle")
                        }
                        .buttonStyle(.plain)
                        VStack(alignment: .leading) {
                            Text(r.title)
                            if let due = r.dueDate { Text(due.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary) }
                        }
                    }
                }
                .onDelete { idx in Task { await vm.delete(remindersAt: idx) } }
            }
        }
        .navigationTitle(vm.list.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isPresentingNewReminder = true } label: { Image(systemName: "plus") }
            }
        }
        .task {
            vm.start()
        }
        .onDisappear { vm.stop() }
        .sheet(isPresented: $isPresentingNewReminder) {
            NavigationStack {
                Form {
                    Section("Details") {
                        TextField("Title", text: $newTitle)
                        TextField("Due date (hours from now, optional)", text: $newHoursFromNow)
                            .keyboardType(.numberPad)
                    }
                }
                .navigationTitle("New Reminder")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isPresentingNewReminder = false
                            newTitle = ""
                            newHoursFromNow = ""
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                            let hours = Int(newHoursFromNow)
                            let due = hours.map { Date().addingTimeInterval(TimeInterval($0 * 3600)) }
                            guard !title.isEmpty else { return }
                            Task { await vm.addReminder(title: title, due: due) }
                            isPresentingNewReminder = false
                            newTitle = ""
                            newHoursFromNow = ""
                        }
                        .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }
}
