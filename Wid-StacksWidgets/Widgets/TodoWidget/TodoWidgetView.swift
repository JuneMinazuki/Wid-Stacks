import WidgetKit
import SwiftUI
import AppIntents

struct TodoWidgetView: View {
    var entry: TodoProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today's To-Do")
                    .font(.headline)
                Spacer()
                // Deep link button to add items inside the main app
                Link(destination: URL(string: "todo://add")!) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
            
            if entry.todos.filter({ !$0.isCompleted }).isEmpty {
                Text("All done!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxHeight: .infinity)
            } else {
                ForEach(entry.todos.prefix(3)) { item in
                    HStack {
                        // Interactive button executing the App Intent
                        Button(intent: ToggleTodoIntent(id: item.id)) {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(item.isCompleted ? .green : .secondary)
                        }
                        .buttonStyle(.plain)

                        Text(item.title)
                            .font(.subheadline)
                            .strikethrough(item.isCompleted)
                        Spacer()
                    }
                }
            }
            Spacer()
        }
        .containerBackground(.background, for: .widget)
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
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
