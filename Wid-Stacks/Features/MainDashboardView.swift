import SwiftUI

struct MainDashboardView: View {
    // Enum for each widget type
    enum WidgetType: String, CaseIterable, Identifiable {
        case todo = "To-Do List"
        case countdown = "Countdown"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .todo: return "checkmark.circle.fill"
            case .countdown: return "hourglass"
            }
        }
    }
    
    @State private var selectedWidget: WidgetType? = .todo

    var body: some View {
        NavigationSplitView {
            List(WidgetType.allCases, selection: $selectedWidget) { widget in
                NavigationLink(value: widget) {
                    Label(widget.rawValue, systemImage: widget.icon)
                        .font(.body)
                        .fontWeight(.medium)
                        .padding(.vertical, 4)
                }
            }
            .navigationTitle("Widgets")
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 300)
        } detail: {
            if let selectedWidget {
                switch selectedWidget {
                case .todo:
                    TodoManagementView()
                case .countdown:
                    CountdownManagementView()
                }
            } else {
                // Placeholder state for unknown state
                VStack(spacing: 16) {
                    Image(systemName: "widget.badge")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Select a Widget Type")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Choose a category from the sidebar to configure its settings.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        // Route to appropriate sidebar tab
        .onOpenURL { url in
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }
            
            if url.host == "add" || url.absoluteString == "todo://add" {
                selectedWidget = .todo
            } else if url.host == "countdown" || url.absoluteString.contains("countdown") {
                selectedWidget = .countdown
            } else if url.host == "toggle" {
                selectedWidget = .todo
                if let queryItem = components.queryItems?.first(where: { $0.name == "id" }),
                   let idString = queryItem.value,
                   let uuid = UUID(uuidString: idString) {
                    Task {
                        await TodoStore.shared.toggleTodo(id: uuid)
                        NotificationCenter.default.post(name: Notification.Name("RefreshTodoData"), object: nil)
                    }
                }
            }
        }
    }
}
