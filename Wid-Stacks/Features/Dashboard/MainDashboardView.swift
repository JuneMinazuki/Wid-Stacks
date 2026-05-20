import SwiftUI
import WidgetKit

struct MainDashboardView: View {
    @State private var todos: [TodoItem] = []
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
                                .strikethrough(todo.isCompleted)
                                .foregroundColor(todo.isCompleted ? .secondary : .primary)
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
            // Refresh the list whenever the app comes into view
            .onAppear {
                refreshData()
            }
            .onOpenURL { url in
                if url.absoluteString == "todo://add" {
                    showAddTaskSheet = true
                }
                // Always pull latest data
                refreshData()
            }
            .sheet(isPresented: $showAddTaskSheet) {
                NavigationStack {
                    Form {
                        TextField("Task Title", text: $newTaskTitle)
                    }
                    .navigationTitle("Add New Task")
                    .toolbar {
                        Button("Save") {
                            let newItem = TodoItem(title: newTaskTitle)
                            var currentTodos = TodoStore.shared.getTodos()
                            currentTodos.append(newItem)
                            TodoStore.shared.saveTodos(currentTodos)
                            
                            newTaskTitle = ""
                            showAddTaskSheet = false
                            refreshData()
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
