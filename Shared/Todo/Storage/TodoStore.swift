import Foundation
import WidgetKit

@MainActor
class TodoStore {
    static let shared = TodoStore()
    private let folderName = "WidStacks"
    private let fileName = "todos.plist"
    
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
        if let cached = cachedTodos {
            return cached
        }
        return loadFromDisk()
    }

    private func loadFromDisk() -> [TodoItem] {
        let url = fileURL
        var loadedTodos: [TodoItem] = []
        
        let coordinator = NSFileCoordinator()
        var error: NSError?
        
        coordinator.coordinate(readingItemAt: url, options: [], error: &error) { readURL in
            guard FileManager.default.fileExists(atPath: readURL.path),
                  let data = try? Data(contentsOf: readURL) else { return }
                  
            let attributes = try? FileManager.default.attributesOfItem(atPath: readURL.path)
            self.lastModificationDate = attributes?[.modificationDate] as? Date
            
            if let decoded = try? PropertyListDecoder().decode([TodoItem].self, from: data) {
                loadedTodos = decoded
            }
        }
        
        if loadedTodos.isEmpty && error != nil { return [] }
        cachedTodos = loadedTodos
        return loadedTodos
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
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        guard let data = try? encoder.encode(sortedTodos) else { return }
        
        let coordinator = NSFileCoordinator()
        var error: NSError?
        
        coordinator.coordinate(writingItemAt: url, options: .forReplacing, error: &error) { writeURL in
            try? data.write(to: writeURL, options: .atomic)
            
            let attributes = try? FileManager.default.attributesOfItem(atPath: writeURL.path)
            self.lastModificationDate = attributes?[.modificationDate] as? Date
        }
        
        cachedTodos = sortedTodos
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
        
        if filtered.count != todos.count {
            saveTodos(filtered, reloadWidget: reloadWidget)
        }
    }
    
    func refreshCacheIfNeeded() -> Bool {
        let url = fileURL
        guard FileManager.default.fileExists(atPath: url.path) else { return false }
        
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        let currentModDate = attributes?[.modificationDate] as? Date
        
        if lastModificationDate != currentModDate {
            _ = loadFromDisk()
            return true // Data actually changed externally
        }
        return false // Data is identical, do nothing
    }
    
    func invalidateCache() {
        cachedTodos = nil
        lastModificationDate = nil
    }
}
