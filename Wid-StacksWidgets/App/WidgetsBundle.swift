import WidgetKit
import SwiftUI

@main
struct AppWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodoWidget()
    }
}

@MainActor
struct TodoProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodoEntry {
        TodoEntry(date: Date(), todos: [TodoItem(id: UUID(), title: "Sample Task", isCompleted: false)])
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoEntry) -> Void) {
        Task {
            let currentTodos = await TodoStore.shared.getTodos()
            let entry = TodoEntry(date: Date(), todos: currentTodos)
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (WidgetKit.Timeline<TodoEntry>) -> Void) {
        Task {
            let allTodos = await TodoStore.shared.getTodos()
            
            // Filter out old items in memory
            let cal = Calendar.current
            let midnight = cal.startOfDay(for: Date())

            let activeOrRecentTodos = allTodos.filter { item in
                if let completedDate = item.completedAt {
                    return completedDate >= midnight // Keep items completed today
                }
                return !item.isCompleted // Keep uncompleted items
            }
            
            // Create the static timeline entry
            let entry = TodoEntry(date: Date(), todos: activeOrRecentTodos)
            
            // Set the reload policy for the next day's midnight
            let nextMidnight = cal.startOfDay(for: Date().addingTimeInterval(86400)).addingTimeInterval(300)
            let timeline = WidgetKit.Timeline(entries: [entry], policy: .after(nextMidnight))
            
            completion(timeline)
        }
    }
}

struct TodoEntry: TimelineEntry {
    let date: Date
    let todos: [TodoItem]
}
