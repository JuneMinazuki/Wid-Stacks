import WidgetKit
import SwiftUI
import AppIntents

struct CountdownProvider: TimelineProvider {
    func placeholder(in context: Context) -> CountdownEntry {
        CountdownEntry(
            date: Date(),
            item: CountdownItem(title: "Milestone Launch", date: Date().addingTimeInterval(86400 * 10), isCountUp: false, blurAmount: 20, selectedGradientIndex: 0, useCustomBackground: false)
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
            
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
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
        .widgetURL(URL(string: "widstacks://countdown"))
        .containerBackground(.background, for: .widget)
    }
    
    // MARK: - Layout Configurations
    @ViewBuilder
    private func smallWidgetLayout(item: CountdownItem) -> some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if item.useCustomBackground == true, let nsImage = NSImage(contentsOf: CountdownStore.shared.backgroundImageURL) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    let gradientIndex = item.selectedGradientIndex
                    let activeGradient = sampleGradients.indices.contains(gradientIndex) ? sampleGradients[gradientIndex] : sampleGradients[0]
                    activeGradient
                }
            }
            .blur(radius: max(0, CGFloat(item.blurAmount / 5)))
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .clipped()
            
            if let emoji = item.selectedEmoji {
                Text(emoji)
                    .font(.title)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(12)
            }
            
            Text("\(abs(daysRemaining))")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .minimumScaleFactor(0.6)
            
            Text(item.isCountUp ? "Days since\n\(item.title.isEmpty ? "Event" : item.title)" : "Days until\n\(item.title.isEmpty ? "Event" : item.title)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func mediumWidgetLayout(item: CountdownItem) -> some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ZStack {
                    Group {
                        if item.useCustomBackground == true, let nsImage = NSImage(contentsOf: CountdownStore.shared.backgroundImageURL) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            let gradientIndex = item.selectedGradientIndex
                            let activeGradient = sampleGradients.indices.contains(gradientIndex) ? sampleGradients[gradientIndex] : sampleGradients[0]
                            activeGradient
                        }
                    }
                    .blur(radius: max(0, CGFloat(item.blurAmount / 5)))
                    
                    if let emoji = item.selectedEmoji {
                        Text(emoji)
                            .font(.system(size: 38))
                    } else {
                        Image(systemName: item.isCountUp ? "clock.arrow.2.circlepath" : "hourglass")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: geometry.size.width * 0.32)
                .clipped()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title.isEmpty ? "EVENT" : item.title.uppercased())
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Text("\(abs(daysRemaining)) Days")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.8)
                    
                    Text(item.isCountUp ? "Time has accumulated" : "Time remaining to milestone")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(Color(white: 0.12))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var emptyStateLayout: some View {
        VStack(spacing: 8) {
            Image(systemName: "hourglass.badge.plus")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("No Active Countdown")
                .font(.headline)
            Text("Open app sidebar to set an event.")
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
        .contentMarginsDisabled()
    }
}
