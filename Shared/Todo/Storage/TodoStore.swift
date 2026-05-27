import Foundation
import WidgetKit

@MainActor
class TodoStore {
    static let shared = TodoStore()
    private let folderName = "WidStacks"
    private let fileName = "todos.plist"
    
    private var cachedTodos: [TodoItem]?
    private var lastModificationDate: Date?

    private init() {
        // Listen for cross-process data changes from the app or widget extension
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.juneminazuki.WidStacks.DataChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                if await self?.refreshCacheIfNeeded() == true {
                    NotificationCenter.default.post(name: NSNotification.Name("RefreshTodoData"), object: nil)
                }
            }
        }
    }

    private var fileURL: URL {
        guard let pw = getpwuid(getuid()), let homeDirCStr = pw.pointee.pw_dir else {
            let fallback = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let customFolder = fallback.appendingPathComponent(folderName)
            try? FileManager.default.createDirectory(at: customFolder, withIntermediateDirectories: true, attributes: nil)
            return customFolder.appendingPathComponent(fileName)
        }
        
        let homeURL = URL(fileURLWithPath: String(cString: homeDirCStr))
        let targetFolder = homeURL
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent(folderName)
        
        if !FileManager.default.fileExists(atPath: targetFolder.path) {
            try? FileManager.default.createDirectory(at: targetFolder, withIntermediateDirectories: true, attributes: nil)
        }
        
        return targetFolder.appendingPathComponent(fileName)
    }

    func getTodos() async -> [TodoItem] {
        _ = await refreshCacheIfNeeded()
        if let cached = cachedTodos {
            return cached
        }
        return await loadFromDisk()
    }

    private func loadFromDisk() async -> [TodoItem] {
        let url = self.fileURL
        
        let result = await Task.detached(priority: .userInitiated) { () -> ([TodoItem], Date?) in
            var loadedTodos: [TodoItem] = []
            var modificationDate: Date? = nil
            
            let coordinator = NSFileCoordinator()
            var error: NSError?
            
            coordinator.coordinate(readingItemAt: url, options: [], error: &error) { readURL in
                guard FileManager.default.fileExists(atPath: readURL.path),
                      let data = try? Data(contentsOf: readURL) else { return }
                      
                let attributes = try? FileManager.default.attributesOfItem(atPath: readURL.path)
                modificationDate = attributes?[.modificationDate] as? Date
                
                if let decoded = try? PropertyListDecoder().decode([TodoItem].self, from: data) {
                    loadedTodos = decoded
                }
            }
            return (loadedTodos, modificationDate)
        }.value
        
        self.lastModificationDate = result.1
        self.cachedTodos = result.0
        return result.0
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
        
        cachedTodos = sortedTodos
        let url = self.fileURL
        
        Task {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .binary
            guard let data = try? encoder.encode(sortedTodos) else { return }
            
            let newModDate = await Task.detached(priority: .background) { () -> Date? in
                var modificationDate: Date? = nil
                let coordinator = NSFileCoordinator()
                var error: NSError?
                
                coordinator.coordinate(writingItemAt: url, options: .forReplacing, error: &error) { writeURL in
                    try? data.write(to: writeURL, options: .atomic)
                    
                    let attributes = try? FileManager.default.attributesOfItem(atPath: writeURL.path)
                    modificationDate = attributes?[.modificationDate] as? Date
                }
                return modificationDate
            }.value
            
            self.lastModificationDate = newModDate
            
            // Notify app and widget to refresh
            DistributedNotificationCenter.default().postNotificationName(
                NSNotification.Name("com.juneminazuki.WidStacks.DataChanged"),
                object: nil,
                userInfo: nil,
                deliverImmediately: true
            )
            
            if reloadWidget {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
    
    func toggleTodo(id: UUID) async {
        var currentTodos = await getTodos()
        
        guard let index = currentTodos.firstIndex(where: { $0.id == id }) else { return }
        
        currentTodos[index].isCompleted.toggle()
        currentTodos[index].completedAt = currentTodos[index].isCompleted ? Date() : nil
        
        saveTodos(currentTodos, reloadWidget: true)
    }
    
    // Instantly remove completed task
    func purgeAllCompletedItems() async {
        let todos = await getTodos()
        let filtered = todos.filter { !$0.isCompleted }
        saveTodos(filtered)
    }

    // For auto remove after midnight
    func purgeOldCompletedItems(reloadWidget: Bool = true) async {
        let todos = await getTodos()
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
    
    func refreshCacheIfNeeded() async -> Bool {
        let url = fileURL
        guard FileManager.default.fileExists(atPath: url.path) else { return false }
        
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        let currentModDate = attributes?[.modificationDate] as? Date
        
        if lastModificationDate != currentModDate {
            self.cachedTodos = nil
            self.lastModificationDate = currentModDate
            _ = await loadFromDisk()
            return true // Data actually changed externally
        }
        return false // Data is identical, do nothing
    }
    
    func invalidateCache() {
        cachedTodos = nil
        lastModificationDate = nil
    }
}
