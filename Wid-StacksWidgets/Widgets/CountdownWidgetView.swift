import WidgetKit
import SwiftUI

@MainActor
struct CountdownProvider: TimelineProvider {
    func placeholder(in context: Context) -> CountdownEntry {
        CountdownEntry(
            date: Date(),
            item: CountdownItem(title: "Milestone Launch", date: Date().addingTimeInterval(86400 * 10), isCountUp: false, blurAmount: 20, selectedGradientIndex: 0)
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CountdownEntry) -> Void) {
        Task {
            let item = await CountdownStore.shared.getCountdown()
            let entry = CountdownEntry(date: Date(), item: item)
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {
        Task {
            let item = await CountdownStore.shared.getCountdown()
            let entry = CountdownEntry(date: Date(), item: item)
            
            // Reload every hour to keep day calculations accurate
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            
            completion(timeline)
        }
    }
}

struct CountdownEntry: TimelineEntry {
    let date: Date
    let item: CountdownItem?
}

struct CountdownWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: CountdownProvider.Entry
    
    let sampleGradients = [
        LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [.teal, .green], startPoint: .topLeading, endPoint: .bottomTrailing)
    ]

    private var daysRemaining: Int {
        guard let item = entry.item else { return 0 }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: item.date)
        let components = calendar.dateComponents([.day], from: start, to: end)
        return components.day ?? 0
    }

    var body: some View {
        Group {
            if let item = entry.item {
                switch family {
                case .systemMedium:
                    mediumWidgetLayout(item: item)
                default:
                    smallWidgetLayout(item: item)
                }
            } else {
                emptyStateLayout
            }
        }
        .containerBackground(.background, for: .widget)
    }
    
    // MARK: - Layout Configurations
    @ViewBuilder
    private func smallWidgetLayout(item: CountdownItem) -> some View {
        ZStack(alignment: .bottomLeading) {
            sampleGradients[item.selectedGradientIndex]
                .blur(radius: CGFloat(item.blurAmount / 5))
            
            Text("\(abs(daysRemaining))")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(16)
            
            Text(item.isCountUp ? "Days since\n\(item.title)" : "Days until\n\(item.title)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
                .padding(16)
        }
    }
    
    @ViewBuilder
    private func mediumWidgetLayout(item: CountdownItem) -> some View {
        HStack(spacing: 0) {
            ZStack {
                sampleGradients[item.selectedGradientIndex]
                    .blur(radius: CGFloat(item.blurAmount / 5))
                Image(systemName: item.isCountUp ? "clock.arrow.2.circlepath" : "hourglass")
                    .font(.title)
                    .foregroundColor(.white)
            }
            .frame(width: 110)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                Text("\(abs(daysRemaining)) Days")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                
                Text(item.isCountUp ? "Time has accumulated" : "Time remaining to milestone")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
    
    @ViewBuilder
    private var emptyStateLayout: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.plus")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("No Event Configured")
                .font(.headline)
            Text("Open WidStacks to set your milestone.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct CountdownWidget: Widget {
    let kind: String = "CountdownWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CountdownProvider()) { entry in
            CountdownWidgetView(entry: entry)
        }
        .configurationDisplayName("Countdown")
        .description("Track the days remaining or elapsed for your key milestones.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
