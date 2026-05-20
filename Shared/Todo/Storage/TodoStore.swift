import Foundation
import WidgetKit

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

    func saveTodos(_ todos: [TodoItem]) {
        guard let defaults = sharedDefaults,
              let encoded = try? JSONEncoder().encode(todos) else { return }
        
        defaults.set(encoded, forKey: storageKey)
        
        // Force update widget
        WidgetCenter.shared.reloadAllTimelines()
    }

    func purgeOldCompletedItems() {
        let todos = getTodos()
        let cal = Calendar.current
        let midnight = cal.startOfDay(for: Date())

        let filtered = todos.filter { item in
            if let completedDate = item.completedAt {
                return completedDate >= midnight // Keep if completed after today midnight
            }
            return true // Keep uncompleted items
        }
        saveTodos(filtered)
    }
}
