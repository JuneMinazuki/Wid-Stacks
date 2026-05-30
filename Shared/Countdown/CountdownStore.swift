import Foundation
import WidgetKit

@MainActor
class CountdownStore {
    static let shared = CountdownStore()
    private let folderName = "WidStacks"
    private let fileName = "countdown.plist"
    
    private var cachedCountdown: CountdownItem?
    private var lastModificationDate: Date?

    private let distributedNotificationName = "com.juneminazuki.WidStacks.CountdownDataChanged"
    nonisolated static let localDataChangedNotification = Notification.Name("com.juneminazuki.WidStacks.LocalCountdownChanged")
    
    private init() {
        // Listen for cross-process data changes from the app or widget extension
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name(distributedNotificationName),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                if await self?.refreshCacheIfNeeded() == true {
                    NotificationCenter.default.post(name: CountdownStore.localDataChangedNotification, object: nil)
                }
            }
        }
    }

    private var fileURL: URL {
        if let pw = getpwuid(getuid()), let homeDirCStr = pw.pointee.pw_dir {
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
        
        let fileManager = FileManager.default
        let fallback = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let targetFolder = fallback.appendingPathComponent(folderName)
        if !fileManager.fileExists(atPath: targetFolder.path) {
            try? fileManager.createDirectory(at: targetFolder, withIntermediateDirectories: true, attributes: nil)
        }
        return targetFolder.appendingPathComponent(fileName)
    }

    func getCountdown() async -> CountdownItem? {
        if cachedCountdown == nil {
            if let diskItem = await loadFromDisk() {
                return diskItem
            } else {
                let defaultItem = CountdownItem(title: "New Milestone", date: Date().addingTimeInterval(86400 * 7), isCountUp: false, blurAmount: 10, selectedGradientIndex: 0)
                self.saveCountdown(defaultItem, reloadWidget: false)
                return defaultItem
            }
        }
        _ = await refreshCacheIfNeeded()
        return cachedCountdown
    }

    private func loadFromDisk() async -> CountdownItem? {
        let url = self.fileURL
        
        let result = await Task.detached(priority: .userInitiated) { () -> (Data?, Date?) in
            var loadedData: Data? = nil
            var modificationDate: Date? = nil
            
            let coordinator = NSFileCoordinator()
            var error: NSError?
            
            coordinator.coordinate(readingItemAt: url, options: [], error: &error) { readURL in
                guard FileManager.default.fileExists(atPath: readURL.path),
                      let data = try? Data(contentsOf: readURL) else { return }
                      
                let attributes = try? FileManager.default.attributesOfItem(atPath: readURL.path)
                modificationDate = attributes?[.modificationDate] as? Date
                loadedData = data
            }
            return (loadedData, modificationDate)
        }.value
        
        self.lastModificationDate = result.1
        
        if let data = result.0,
           let decoded = try? PropertyListDecoder().decode(CountdownItem.self, from: data) {
            self.cachedCountdown = decoded
            return decoded
        }
        
        self.cachedCountdown = nil
        return nil
    }

    func saveCountdown(_ item: CountdownItem, reloadWidget: Bool = true) {
        cachedCountdown = item
        let url = self.fileURL
        
        Task {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .binary
            guard let data = try? encoder.encode(item) else { return }
            
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
            
            NotificationCenter.default.post(name: CountdownStore.localDataChangedNotification, object: nil)
            
            DistributedNotificationCenter.default().postNotificationName(
                NSNotification.Name(distributedNotificationName),
                object: nil,
                userInfo: nil,
                deliverImmediately: true
            )
            
            if reloadWidget {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
    
    func refreshCacheIfNeeded() async -> Bool {
        let url = fileURL
        guard FileManager.default.fileExists(atPath: url.path) else { return false }
        
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        let currentModDate = attributes?[.modificationDate] as? Date
        
        if lastModificationDate != currentModDate || cachedCountdown == nil {
            self.lastModificationDate = currentModDate
            let updatedItem = await loadFromDisk()
            return updatedItem != nil
        }
        return false
    }
}
