import SwiftUI
import WidgetKit

struct MainDashboardView: View {
    @State private var todos: [TodoItem] = TodoStore.shared.getTodos()
    @State private var showAddTaskSheet = false
    @State private var newTaskTitle = ""

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Widget Configuration: To-Do List")) {
                    Button("Purge Items Manually Now") {
                        TodoStore.shared.purgeOldCompletedItems()
                        refreshData()
                    }
                }
                
                Section(header: Text("Current Active Tasks")) {
                    ForEach(todos) { todo in
                        HStack {
                            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                            Text(todo.title)
                        }
                    }
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                Button(action: { showAddTaskSheet = true }) {
                    Image(systemName: "plus")
                }
            }
            // Listen for deep links coming from the widget
            .onOpenURL { url in
                if url.absoluteString == "todo://add" {
                    showAddTaskSheet = true
                }
            }
            .sheet(isPresented: $showAddTaskSheet) {
                NavigationStack {
                    Form {
                        TextField("Task Title", text: $newTaskTitle)
                    }
                    .navigationTitle("Add New Task")
                    .toolbar {
                        Button("Save") {
                            let newItem = TodoItem(id: UUID(), title: newTaskTitle, isCompleted: false)
                            todos.append(newItem)
                            TodoStore.shared.saveTodos(todos)
                            WidgetCenter.shared.reloadAllTimelines()
                            newTaskTitle = ""
                            showAddTaskSheet = false
                        }
                    }
                }
            }
        }
    }

    func refreshData() {
        todos = TodoStore.shared.getTodos()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
