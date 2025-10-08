import SwiftUI

struct ListsRootView: View {
    @EnvironmentObject private var env: AppEnvironment
    @StateObject private var vmCache = CachedBox<ListsViewModel>()

    var body: some View {
        let vm = vmCache.resolve {
            ListsViewModel(repo: env.listRepository)
        }
        
        ListsView(vm: vm)
    }
}

struct ListsView: View {
    @StateObject private var vm: ListsViewModel
    
    @State private var isPresentingNewList: Bool = false
    @State private var newListTitle: String = ""
    
    init(vm: ListsViewModel) {
        _vm = StateObject(wrappedValue: vm)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(vm.lists) { list in
                    NavigationLink(value: list) {
                        VStack(alignment: .leading) {
                            Text(list.title).font(.headline)
                            Text("\(list.reminders.filter{ !$0.isDone }.count) open • \(list.reminders.count) total")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { idx in Task { await vm.delete(at: idx) } }
            }
            .navigationTitle("Lists")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { isPresentingNewList = true } label: { Image(systemName: "plus") }
                }
            }
            .navigationDestination(for: TodoList.self) { list in
                ListDetailRootView(list: list)
            }
            .task {
                vm.start()
            }
            .onDisappear { vm.stop() }
            .sheet(isPresented: $isPresentingNewList) {
                NavigationStack {
                    Form {
                        Section("Details") {
                            TextField("Title", text: $newListTitle)
                        }
                    }
                    .navigationTitle("New List")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                isPresentingNewList = false
                                newListTitle = ""
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Add") {
                                let title = newListTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !title.isEmpty else { return }
                                Task { await vm.addList(title: title) }
                                isPresentingNewList = false
                                newListTitle = ""
                            }
                            .disabled(newListTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
            }
        }
    }
}

