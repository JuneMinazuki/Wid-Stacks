import SwiftUI

struct CountdownManagementView: View {
    @State private var item: CountdownItem = CountdownItem(
        title: "", date: Date(), isCountUp: false, blurAmount: 0.0, selectedGradientIndex: 0
    )
    @State private var isLoading = true
    
    let sampleGradients = [
        LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [.teal, .green], startPoint: .topLeading, endPoint: .bottomTrailing)
    ]

    var daysRemaining: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: item.date)
        let components = calendar.dateComponents([.day], from: start, to: end)
        return components.day ?? 0
    }

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView().padding(100)
            } else {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Block
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Moments & Countdowns")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Configure your desktop canvas tracking parameters.")
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
                                TextField("e.g., Project Launch", text: $item.title)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: item.title) {
                                        save()
                                    }
                            }
                            
                            DatePicker("Target Date", selection: $item.date, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .onChange(of: item.date) {
                                    save()
                                }
                            
                            Picker("Counter Mode", selection: $item.isCountUp) {
                                Text("Count Down (Remaining)").tag(false)
                                Text("Count Up (Elapsed)").tag(true)
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: item.isCountUp) {
                                save()
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Background Blur Style")
                                    Spacer()
                                    Text("\(Int(item.blurAmount))%")
                                        .font(.caption).foregroundColor(.secondary)
                                }
                                Slider(value: $item.blurAmount, in: 0...100, step: 5)
                                    .onChange(of: item.blurAmount) {
                                        save()
                                    }
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
                                                   .stroke(Color.primary, lineWidth: item.selectedGradientIndex == index ? 2 : 0)
                                           )
                                           .onTapGesture {
                                               item.selectedGradientIndex = index
                                               save()
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
                                        
                                        if !item.isCountUp {
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
        .task {
            if let fetchedItem = await CountdownStore.shared.getCountdown() {
                item = fetchedItem
            }
            isLoading = false
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshCountdownData"))) { _ in
            Task {
                if let fetchedItem = await CountdownStore.shared.getCountdown() {
                    self.item = fetchedItem
                }
            }
        }
    }
    
    private func save() {
        CountdownStore.shared.saveCountdown(item)
    }
}
