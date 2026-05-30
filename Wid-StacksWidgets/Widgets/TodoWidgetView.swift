import WidgetKit
import SwiftUI
import AppIntents

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

struct TodoWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: TodoProvider.Entry

    private var activeTodos: [TodoItem] {
        entry.todos.filter { !$0.isCompleted }
    }
    
    private var completedTodos: [TodoItem] {
        entry.todos.filter { $0.isCompleted }
    }
    
    // Max items shown in widget
    private var maxVisibleItems: Int {
        switch family {
        case .systemMedium: return 3
        default: return 8
        }
    }
    
    private var visibleTodos: [TodoItem] {
        let combined = activeTodos + completedTodos
        return Array(combined.prefix(maxVisibleItems))
    }
    
    private var hiddenCount: Int {
        let total = entry.todos.count
        return total > maxVisibleItems ? total - maxVisibleItems : 0
    }

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                mediumWidgetLayout
            default:
                largeWidgetLayout
            }
        }
        .containerBackground(.background, for: .widget)
    }
    
    // MARK: - Layout Configurations
    
    private var mediumWidgetLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header (Title, Completion Status, Progress Bar)
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("To-Do Progress")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("\(completedTodos.count) of \(entry.todos.count) Completed (\(activeTodos.count) remaining)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ProgressView(value: Double(completedTodos.count), total: Double(max(1, entry.todos.count)))
                        .progressViewStyle(.linear)
                        .tint(.accentColor)
                        .frame(maxWidth: 140)
                        .scaleEffect(x: 1, y: 0.75, anchor: .leading)
                        .padding(.top, 1)
                }
                
                Spacer()
                
                Link(destination: URL(string: "todo://add")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add Task")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .cornerRadius(6)
                }
            }
            
            Divider()
                .padding(.top, 1)
            
            taskContentList
            
            Spacer(minLength: 0)
        }
    }
    
    private var largeWidgetLayout: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header (Title, Completion Status, Progress Bar)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("To-Do Progress")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("\(completedTodos.count) of \(entry.todos.count) Completed (\(activeTodos.count) remaining)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    ProgressView(value: Double(completedTodos.count), total: Double(max(1, entry.todos.count)))
                        .progressViewStyle(.linear)
                        .tint(.accentColor)
                        .frame(maxWidth: 220)
                }
                
                Spacer()
                
                Link(destination: URL(string: "todo://add")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Add Task")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
                }
            }
            
            Divider()
            
            taskContentList
            Spacer(minLength: 0)
        }
    }
    
    // MARK: - Shared Subviews
    
    @ViewBuilder
    private var taskContentList: some View {
        if entry.todos.isEmpty {
            Text("All done!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(visibleTodos) { item in
                    taskRow(for: item)
                }
                
                if hiddenCount > 0 {
                    viewAllFooter
                }
            }
        }
    }
    
    @ViewBuilder
    private func taskRow(for item: TodoItem) -> some View {
        HStack(spacing: 8) {
            Button(intent: ToggleTodoIntent(id: item.id)) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(item.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            Text(item.title)
                .font(.subheadline)
                .strikethrough(item.isCompleted)
                .foregroundStyle(item.isCompleted ? .secondary : .primary)
                .lineLimit(1)
            
            Spacer()
        }
    }
    
    private var viewAllFooter: some View {
        Link(destination: URL(string: "todo://all")!) {
            HStack(spacing: 4) {
                Text("+ \(hiddenCount) more tasks...")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.accentColor)
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.accentColor)
            }
            .padding(.top, 1)
        }
    }
}

struct TodoWidget: Widget {
    let kind: String = "TodoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodoProvider()) { entry in
            TodoWidgetView(entry: entry)
        }
        .configurationDisplayName("To-Do List")
        .description("Manage your daily tasks directly from your screen.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
