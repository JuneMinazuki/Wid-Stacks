import WidgetKit
import SwiftUI

@main
struct AppWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodoWidget()
    }
}

// Simple Timeline Provider for the Todo Widget
@MainActor
struct TodoProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodoEntry {
        TodoEntry(date: Date(), todos: [TodoItem(id: UUID(), title: "Sample Task", isCompleted: false)])
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoEntry) -> Void) {
        let entry = TodoEntry(date: Date(), todos: TodoStore.shared.getTodos())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (WidgetKit.Timeline<TodoEntry>) -> Void) {
        // Run midnight cleanup
        TodoStore.shared.purgeOldCompletedItems()
        
        // Get fresh data
        let entries = [TodoEntry(date: Date(), todos: TodoStore.shared.getTodos())]
        
        // Refresh exactly at midnight
        let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        let timeline = WidgetKit.Timeline(entries: entries, policy: .after(midnight))
        
        completion(timeline)
    }
}

struct TodoEntry: TimelineEntry {
    let date: Date
    let todos: [TodoItem]
}
