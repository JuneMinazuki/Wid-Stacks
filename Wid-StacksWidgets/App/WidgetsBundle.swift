import WidgetKit
import SwiftUI

@main
struct AppWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodoWidget()
    }
}

// Simple Timeline Provider for the Todo Widget
struct TodoProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodoEntry {
        TodoEntry(date: Date(), todos: [TodoItem(id: UUID(), title: "Sample Task", isCompleted: false)])
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoEntry) -> Void) {
        let entry = TodoEntry(date: Date(), todos: TodoStore.shared.getTodos())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (WidgetKit.Timeline<TodoEntry>) -> Void) {
        // Run the midnight cleanup before rendering data
        TodoStore.shared.purgeOldCompletedItems()
        
        let entries = [TodoEntry(date: Date(), todos: TodoStore.shared.getTodos())]
        let timeline = WidgetKit.Timeline(entries: entries, policy: .after(Date().addingTimeInterval(900))) // Refresh every 15 min
        completion(timeline)
    }
}

struct TodoEntry: TimelineEntry {
    let date: Date
    let todos: [TodoItem]
}
