import SwiftUI

struct MainDashboardView: View {
    // Enum for each widget type
    enum WidgetType: String, CaseIterable, Identifiable {
        case todo = "To-Do List"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .todo: return "checkmark.circle.fill"
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
            if url.absoluteString == "todo://add" {
                selectedWidget = .todo
            }
        }
    }
}
