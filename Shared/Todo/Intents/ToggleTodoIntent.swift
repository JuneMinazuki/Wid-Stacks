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
        var todos = TodoStore.shared.getTodos()
        if let uuid = UUID(uuidString: id),
           let index = todos.firstIndex(where: { $0.id == uuid }) {
            todos[index].isCompleted.toggle()
            todos[index].completedAt = todos[index].isCompleted ? Date() : nil
            TodoStore.shared.saveTodos(todos)
            
            // Forces the widget timeline to reload immediately
            WidgetCenter.shared.reloadAllTimelines()
        }
        return .result()
    }
}
