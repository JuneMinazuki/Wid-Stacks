import SwiftUI
import WidgetKit

struct TodoManagementView: View {
    @State private var todos: [TodoItem] = []
    @State private var showAddTaskSheet = false
    @State private var newTaskTitle = ""
    
    // State to track which item is being edited
    @State private var editingTodoID: UUID? = nil
    @State private var editingText = ""

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
                            TodoStore.shared.purgeAllCompletedItems()
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
                                TodoRowView(
                                    todo: todo,
                                    editingTodoID: $editingTodoID,
                                    editingText: $editingText,
                                    onToggle: { toggleTodo(todo) },
                                    onDelete: { deleteTodo(todo) },
                                    onSaveEdit: { newTitle in saveEdit(for: todo, newTitle: newTitle) }
                                )
                                
                                if todo.id != todos.last?.id {
                                    Divider()
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
            TodoStore.shared.purgeOldCompletedItems(reloadWidget: false)
            refreshData()
        }
        .onOpenURL { url in
            if url.absoluteString == "todo://add" {
                showAddTaskSheet = true
            }
            refreshData()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
            if TodoStore.shared.refreshCacheIfNeeded() {
                refreshData()
            }
        }
        .sheet(isPresented: $showAddTaskSheet) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Add New Task")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                TextField("What needs to be done?", text: $newTaskTitle)
                                    .textFieldStyle(.plain)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(containerBackground)
                                    .cornerRadius(12)
                
                HStack(spacing: 12) {
                    Spacer()
                    
                    Button("Cancel") {
                        showAddTaskSheet = false
                        newTaskTitle = ""
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    
                    Button("Save") {
                        let newItem = TodoItem(title: newTaskTitle)
                        var currentTodos = TodoStore.shared.getTodos()
                        currentTodos.append(newItem)
                        TodoStore.shared.saveTodos(currentTodos, reloadWidget: true)
                        
                        newTaskTitle = ""
                        showAddTaskSheet = false
                        refreshData()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .disabled(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(24)
            .frame(width: 440)
            .background(Color(white: 0.09))
        }
    }

    private func refreshData() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            todos = TodoStore.shared.getTodos()
        }
    }
    
    private func toggleTodo(_ todo: TodoItem) {
        TodoStore.shared.toggleTodo(id: todo.id)
        refreshData()
    }
    
    private func deleteTodo(_ todo: TodoItem) {
        var currentTodos = TodoStore.shared.getTodos()
        currentTodos.removeAll(where: { $0.id == todo.id })
        TodoStore.shared.saveTodos(currentTodos)
        refreshData()
    }
    
    private func saveEdit(for todo: TodoItem, newTitle: String) {
        guard !newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        var currentTodos = TodoStore.shared.getTodos()
        if let index = currentTodos.firstIndex(where: { $0.id == todo.id }) {
            currentTodos[index].title = newTitle
            TodoStore.shared.saveTodos(currentTodos)
            refreshData()
        }
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

// MARK: - Subviews

struct TodoRowView: View {
    let todo: TodoItem
    @Binding var editingTodoID: UUID?
    @Binding var editingText: String
    
    var onToggle: () -> Void
    var onDelete: () -> Void
    var onSaveEdit: (String) -> Void
    
    @FocusState private var isTextFieldFocused: Bool
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onToggle) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(todo.isCompleted ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            
            if editingTodoID == todo.id {
                TextField("", text: $editingText, onCommit: {
                    onSaveEdit(editingText)
                    editingTodoID = nil
                })
                .textFieldStyle(.squareBorder)
                .focused($isTextFieldFocused)
                .onAppear {
                    isTextFieldFocused = true
                }
            } else {
                Text(todo.title)
                    .strikethrough(todo.isCompleted)
                    .foregroundColor(todo.isCompleted ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        editingText = todo.title
                        editingTodoID = todo.id
                    }
            }
            
            // Show delete button on hover
            if isHovering {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding()
        .background(Color(white: 0.16).opacity(0.6))
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: todo.isCompleted)
    }
}
