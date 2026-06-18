import SwiftUI

@main
struct Wid_StacksApp: App {
    init() {
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    var body: some Scene {
        WindowGroup {
            MainDashboardView()
                .handlesExternalEvents(preferring: ["*"], allowing: ["*"]) // Route to opened window
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
