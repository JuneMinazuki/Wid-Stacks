import Foundation
import WidgetKit

@MainActor
class TodoStore {
    static let shared = TodoStore()
    private let sharedSuiteName = "group.com.juneminazuki.Wid-Stacks"
    private let storageKey = "saved_todos"
    private let syncKey = "todos_sync_token"
    
    private var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: sharedSuiteName)
    }

    private var cachedTodos: [TodoItem]?
    private var localSyncToken: Double = 0

    func getTodos() -> [TodoItem] {
        guard let defaults = sharedDefaults else { return [] }
        let externalToken = defaults.double(forKey: syncKey)
        
        if localSyncToken == externalToken, let cached = cachedTodos {
            return cached
        }

        // Read from disk if file had changed
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) else {
            return []
        }
        
        cachedTodos = decoded
        localSyncToken = externalToken
        return decoded
    }

    func saveTodos(_ todos: [TodoItem], reloadWidget: Bool = true) {
        let newToken = Date().timeIntervalSince1970
        
        // Sorts tasks to show uncompleted (false) first
        let sortedTodos = todos.sorted { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted {
                return !lhs.isCompleted
            }
            // Sort by completion date
            if lhs.isCompleted, let lhsDate = lhs.completedAt, let rhsDate = rhs.completedAt {
                return lhsDate > rhsDate
            }
            return false
        }
        
        guard let defaults = sharedDefaults,
              let encoded = try? JSONEncoder().encode(sortedTodos) else { return }
        
        defaults.set(encoded, forKey: storageKey)
        defaults.set(newToken, forKey: syncKey)
        
        cachedTodos = sortedTodos
        localSyncToken = newToken
        
        if reloadWidget {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    func toggleTodo(id: UUID) {
        var currentTodos = getTodos()
        
        guard let index = currentTodos.firstIndex(where: { $0.id == id }) else { return }
        
        currentTodos[index].isCompleted.toggle()
        currentTodos[index].completedAt = currentTodos[index].isCompleted ? Date() : nil
        
        saveTodos(currentTodos, reloadWidget: true)
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
    
    func refreshCacheIfNeeded() -> Bool {
        guard let defaults = sharedDefaults else { return false }
        let externalToken = defaults.double(forKey: syncKey)
        
        if localSyncToken != externalToken {
            invalidateCache()
            return true // Data actually changed externally
        }
        return false // Data is identical, do nothing
    }
    
    func invalidateCache() {
        cachedTodos = nil
    }
}
