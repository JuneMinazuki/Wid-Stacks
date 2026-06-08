import AppIntents
import WidgetKit
import Foundation

struct ToggleTodoIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Todo Item"
    
    @Parameter(title: "Item ID")
    var id: String

    init() {}
    
    init(id: UUID) {
        self.id = id.uuidString
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: id) else { return .result() }
        
        await TodoStore.shared.toggleTodo(id: uuid)
        WidgetCenter.shared.reloadAllTimelines()
        
        return .result()
    }
}
