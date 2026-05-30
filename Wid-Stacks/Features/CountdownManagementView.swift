import SwiftUI

struct CountdownEvent: Identifiable {
    let id = UUID()
    var title: String
    var date: Date
    var isCountUp: Bool
    var blurAmount: Double
    var selectedGradient: LinearGradient
}

struct CountdownManagementView: View {
    @State private var eventTitle: String = "Finals Exam"
    @State private var targetDate: Date = Date().addingTimeInterval(86400 * 14)
    @State private var isCountUp: Bool = false
    @State private var blurAmount: Double = 20.0
    
    let sampleGradients = [
        LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [.teal, .green], startPoint: .topLeading, endPoint: .bottomTrailing)
    ]
    @State private var currentGradientIndex = 0

    var daysRemaining: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: targetDate)
        let components = calendar.dateComponents([.day], from: start, to: end)
        return components.day ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Block
                VStack(alignment: .leading, spacing: 6) {
                    Text("Moments & Countdowns")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Configure your desktop canvas canvas tracking parameters.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                HStack(alignment: .top, spacing: 32) {
                    // Left Column: Configuration Controls
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Widget Configuration")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Event Title")
                                .font(.caption).foregroundColor(.secondary)
                            TextField("e.g., Project Launch", text: $eventTitle)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        DatePicker("Target Date", selection: $targetDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                        
                        Picker("Counter Mode", selection: $isCountUp) {
                            Text("Count Down (Remaining)").tag(false)
                            Text("Count Up (Elapsed)").tag(true)
                        }
                        .pickerStyle(.segmented)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Background Blur Style")
                                Spacer()
                                Text("\(Int(blurAmount))%")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Slider(value: $blurAmount, in: 0...100, step: 5)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Theme Preset")
                                .font(.caption).foregroundColor(.secondary)
                            HStack(spacing: 12) {
                               ForEach(0..<sampleGradients.count, id: \.self) { index in
                                   Circle()
                                       .fill(sampleGradients[index])
                                       .frame(width: 32, height: 32)
                                       .overlay(
                                           Circle()
                                               .stroke(Color.primary, lineWidth: currentGradientIndex == index ? 2 : 0)
                                       )
                                       .onTapGesture {
                                           currentGradientIndex = index
                                       }
                               }
                            }
                        }
                    }
                    .frame(maxWidth: 340)
                    
                    // Right Column: Canvas Live Widget Previews
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Live Layout Previews")
                            .font(.headline)
                        
                        // Small Widget Family Preview
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Small Family (2x2)")
                                .font(.caption).foregroundColor(.secondary)
                            
                            ZStack(alignment: .bottomLeading) {
                                sampleGradients[currentGradientIndex]
                                    .blur(radius: CGFloat(blurAmount / 5))
                                
                                Text("\(abs(daysRemaining))")
                                    .font(.system(size: 42, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                    .padding(16)
                                
                                Text(isCountUp ? "Days since\n\(eventTitle)" : "Days until\n\(eventTitle)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(16)
                            }
                            .frame(width: 155, height: 155)
                            .cornerRadius(22)
                            .shadow(radius: 4)
                        }
                        
                        // Medium Widget Family Preview
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Medium Family (4x2)")
                                .font(.caption).foregroundColor(.secondary)
                            
                            HStack(spacing: 0) {
                                ZStack {
                                    sampleGradients[currentGradientIndex]
                                        .blur(radius: CGFloat(blurAmount / 5))
                                    Image(systemName: isCountUp ? "clock.arrow.2.circlepath" : "hourglass")
                                        .font(.title)
                                        .foregroundColor(.white)
                                }
                                .frame(width: 110)
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(eventTitle.uppercased())
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                    
                                    Text("\(abs(daysRemaining)) Days")
                                        .font(.system(size: 26, weight: .bold, design: .rounded))
                                    
                                    Text(isCountUp ? "Time has accumulated" : "Time remaining to milestone")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    
                                    if !isCountUp {
                                        ProgressView(value: 0.65)
                                            .progressViewStyle(.linear)
                                            .tint(.primary)
                                            .padding(.top, 4)
                                    }
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                .background(Color(NSColor.windowBackgroundColor))
                            }
                            .frame(width: 320, height: 155)
                            .cornerRadius(22)
                            .shadow(radius: 4)
                        }
                    }
                }
            }
            .padding(30)
        }
    }
}

#Preview {
    CountdownManagementView()
}
