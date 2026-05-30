import Foundation
import WidgetKit

@MainActor
class CountdownStore {
    static let shared = CountdownStore()
    private let folderName = "WidStacks"
    private let fileName = "countdown.plist"
    
    private var cachedCountdown: CountdownItem?
    private var isCacheInitialized = false
    private var lastModificationDate: Date?

    private init() {
        // Listen for data changes from app or widget
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.juneminazuki.WidStacks.CountdownChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                if await self?.refreshCacheIfNeeded() == true {
                    NotificationCenter.default.post(name: NSNotification.Name("RefreshCountdownData"), object: nil)
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

    func getCountdown() async -> CountdownItem? {
        _ = await refreshCacheIfNeeded()
        if isCacheInitialized {
            return cachedCountdown
        }
        return await loadFromDisk()
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
            self.isCacheInitialized = true
            return decoded
        }
        
        self.cachedCountdown = nil
        self.isCacheInitialized = true
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
            
            // Notify other running targets (e.g., widget/app)
            DistributedNotificationCenter.default().postNotificationName(
                NSNotification.Name("com.juneminazuki.WidStacks.CountdownChanged"),
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
        
        if lastModificationDate != currentModDate {
            self.cachedCountdown = nil
            self.lastModificationDate = currentModDate
            _ = await loadFromDisk()
            return true
        }
        return false
    }
}
