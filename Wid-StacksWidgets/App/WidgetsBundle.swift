import WidgetKit
import SwiftUI

@main
struct AppWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodoWidget()
        CountdownWidget()
    }
}
