import Foundation
import WidgetKit

@MainActor
class TodoStore {
    static let shared = TodoStore()
    private let folderName = "WidStacks"
    private let fileName = "todos.json"
    
    private var cachedTodos: [TodoItem]?
    private var lastModificationDate: Date?

    private var fileURL: URL {
        let widgetBundleIdentifier = "com.juneminazuki.Wid-Stacks.Widgets" 
        
        let appSupportURL: URL
        let currentBundleID = Bundle.main.bundleIdentifier ?? ""
        
        if currentBundleID.hasSuffix(".Widgets") { 
            // Running inside the sandboxed widget
            appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        } else {
            // Running inside the unsandboxed main app
            let homeURL = FileManager.default.homeDirectoryForCurrentUser
            appSupportURL = homeURL.appendingPathComponent("Library/Containers/\(widgetBundleIdentifier)/Data/Library/Application Support")
        }
        
        let customFolder = appSupportURL.appendingPathComponent(folderName)
        
        if !FileManager.default.fileExists(atPath: customFolder.path) {
            try? FileManager.default.createDirectory(at: customFolder, withIntermediateDirectories: true, attributes: nil)
        }
        
        return customFolder.appendingPathComponent(fileName)
    }

    func getTodos() -> [TodoItem] {
        let url = fileURL
        
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        let currentModDate = attributes?[.modificationDate] as? Date
        
        if let cached = cachedTodos, let lastMod = lastModificationDate, lastMod == currentModDate {
            return cached
        }

        // Read from disk if file had changed
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) else {
            return []
        }
        
        cachedTodos = decoded
        lastModificationDate = currentModDate
        return decoded
    }

    func saveTodos(_ todos: [TodoItem], reloadWidget: Bool = true) {
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
        
        let url = fileURL
        guard let data = try? JSONEncoder().encode(sortedTodos) else { return }
        
        try? data.write(to: url, options: .atomic)
        
        cachedTodos = sortedTodos
        
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        lastModificationDate = attributes?[.modificationDate] as? Date
        
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
        let url = fileURL
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        let currentModDate = attributes?[.modificationDate] as? Date
        
        if lastModificationDate != currentModDate {
            invalidateCache()
            return true // Data actually changed externally
        }
        return false // Data is identical, do nothing
    }
    
    func invalidateCache() {
        cachedTodos = nil
        lastModificationDate = nil
    }
}
