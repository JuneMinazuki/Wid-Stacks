import SwiftUI
import WidgetKit

struct TodoManagementView: View {
    @State private var todos: [TodoItem] = []
    @State private var showAddTaskSheet = false
    @State private var newTaskTitle = ""

    private var totalTasks: Int { todos.count }
    private var completedTasks: Int { todos.filter { $0.isCompleted }.count }
    
    private let containerBackground = Color(white: 0.16).opacity(0.6)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // Analytics Section Row
                HStack(spacing: 16) {
                    statCard(title: "Total Tasks", count: totalTasks, icon: "list.bullet.clipboard", color: .blue)
                    statCard(title: "Completed", count: completedTasks, icon: "checkmark.circle.fill", color: .green)
                }
                .padding(.horizontal)
                
                // Widget Admin Tasks Container
                VStack(alignment: .leading, spacing: 8) {
                    Text("Widget Configuration")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    VStack(spacing: 0) {
                        Button(action: {
                            TodoStore.shared.purgeOldCompletedItems()
                            refreshData()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Remove Completed Items")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    Text("Instantly clear all completed history records.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "trash")
                                    .font(.title3)
                                    .foregroundColor(.red)
                            }
                            .padding()
                            .background(containerBackground)
                        }
                        .buttonStyle(.plain)
                    }
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                // Active task list
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Active Tasks")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    if todos.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 12) {
                                Image(systemName: "checklist.checked")
                                    .font(.system(size: 36))
                                    .foregroundColor(.secondary)
                                Text("All caught up!")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 40)
                            Spacer()
                        }
                        .background(containerBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(todos) { todo in
                                HStack(spacing: 14) {
                                    Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(todo.isCompleted ? .green : .secondary)
                                        .font(.title3)
                                    
                                    Text(todo.title)
                                        .strikethrough(todo.isCompleted)
                                        .foregroundColor(todo.isCompleted ? .secondary : .primary)
                                    
                                    Spacer()
                                }
                                .padding()
                                
                                if todo.id != todos.last?.id {
                                    Divider().padding(.leading, 50)
                                }
                            }
                        }
                        .background(containerBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(white: 0.09))
        .navigationTitle("To-Do Settings")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showAddTaskSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            refreshData()
        }
        .onOpenURL { url in
            if url.absoluteString == "todo://add" {
                showAddTaskSheet = true
            }
            refreshData()
        }
        .sheet(isPresented: $showAddTaskSheet) {
            NavigationStack {
                Form {
                    Section(header: Text("Task Details")) {
                        TextField("What needs to be done?", text: $newTaskTitle)
                    }
                }
                .navigationTitle("Add New Task")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showAddTaskSheet = false
                            newTaskTitle = ""
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let newItem = TodoItem(title: newTaskTitle)
                            var currentTodos = TodoStore.shared.getTodos()
                            currentTodos.append(newItem)
                            TodoStore.shared.saveTodos(currentTodos)
                            
                            newTaskTitle = ""
                            showAddTaskSheet = false
                            refreshData()
                        }
                        .disabled(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }

    private func refreshData() {
        todos = TodoStore.shared.getTodos()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // Cards for stats items
    @ViewBuilder
    private func statCard(title: String, count: Int, icon: String, color: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                Text("\(count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            Spacer()
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .padding(10)
                .background(color.opacity(0.12))
                .clipShape(Circle())
        }
        .padding()
        .background(containerBackground)
        .cornerRadius(12)
    }
}
