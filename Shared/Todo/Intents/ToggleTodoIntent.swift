import AppIntents
import WidgetKit

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
        if let uuid = UUID(uuidString: id) {
            TodoStore.shared.toggleTodo(id: uuid)
        }
        return .result()
    }
}
