import Foundation
import WidgetKit

@MainActor
class TodoStore {
    static let shared = TodoStore()
    private let sharedSuiteName = "group.com.juneminazuki.Wid-Stacks"
    private let storageKey = "saved_todos"
    
    private var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: sharedSuiteName)
    }

    func getTodos() -> [TodoItem] {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) else {
            return []
        }
        return decoded
    }

    func saveTodos(_ todos: [TodoItem], reloadWidget: Bool = true) {
        guard let defaults = sharedDefaults,
              let encoded = try? JSONEncoder().encode(todos) else { return }
        
        defaults.set(encoded, forKey: storageKey)
        
        if reloadWidget {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    func toggleTodo(id: UUID) {
        var currentTodos = getTodos()
        if let index = currentTodos.firstIndex(where: { $0.id == id }) {
            currentTodos[index].isCompleted.toggle()
            currentTodos[index].completedAt = currentTodos[index].isCompleted ? Date() : nil
            saveTodos(currentTodos, reloadWidget: false)
        }
    }
    
    // Instantly remove completed task
    func purgeAllCompletedItems() {
        let todos = getTodos()
        let filtered = todos.filter { !$0.isCompleted }
        saveTodos(filtered)
    }

    // For auto remove after midnight
    func purgeOldCompletedItems(reloadWidget: Bool = true) {
        let todos = getTodos()
        let cal = Calendar.current
        let midnight = cal.startOfDay(for: Date())

        let filtered = todos.filter { item in
            if let completedDate = item.completedAt {
                return completedDate >= midnight // Keep if completed after today midnight
            }
            return !item.isCompleted // Keep uncompleted items
        }
        
        saveTodos(filtered, reloadWidget: reloadWidget)
    }
}
