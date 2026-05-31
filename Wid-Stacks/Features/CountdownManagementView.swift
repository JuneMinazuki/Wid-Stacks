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
    
    private let containerBackground = Color(white: 0.16).opacity(0.6)

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .padding(100)
                    .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 24) {
                    
                    // Widget Configuration Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Widget Configuration")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 20) {
                            // Event Title Text Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Event Title")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("e.g., Project Launch", text: $item.title)
                                    .textFieldStyle(.plain)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Color(white: 0.12))
                                    .cornerRadius(8)
                            }
                            
                            // Date Picker
                            DatePicker("Target Date", selection: $item.date, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                            
                            // Picker Mode
                            Picker("Counter Mode", selection: $item.isCountUp) {
                                Text("Count Down").tag(false)
                                Text("Count Up").tag(true)
                            }
                            .pickerStyle(.segmented)
                            
                            // Blur Amount Slider
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Background Blur Style")
                                    Spacer()
                                    Text("\(Int(item.blurAmount))%")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Slider(value: $item.blurAmount, in: 0...100, step: 5)
                            }
                            
                            // Color Matrix Themes
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Theme Preset")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                HStack(spacing: 12) {
                                   ForEach(0..<sampleGradients.count, id: \.self) { index in
                                       Circle()
                                           .fill(sampleGradients[index])
                                           .frame(width: 32, height: 32)
                                           .overlay(
                                               Circle()
                                                   .stroke(Color.white, lineWidth: item.selectedGradientIndex == index ? 2 : 0)
                                           )
                                           .onTapGesture {
                                               item.selectedGradientIndex = index
                                               save()
                                           }
                                   }
                                }
                            }
                        }
                        .padding(20)
                        .background(containerBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Widget Preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Widget Preview")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 24) {
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
                                    
                                    Text(item.isCountUp ? "Days since\n\(item.title.isEmpty ? "Event" : item.title)" : "Days until\n\(item.title.isEmpty ? "Event" : item.title)")
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
                                        Text((item.title.isEmpty ? "Event" : item.title).uppercased())
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.secondary)
                                        
                                        Text("\(abs(daysRemaining)) Days")
                                            .font(.system(size: 26, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        
                                        Text(item.isCountUp ? "Time has accumulated" : "Time remaining to milestone")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        
                                        if !item.isCountUp {
                                            ProgressView(value: 0.65)
                                                .progressViewStyle(.linear)
                                                .tint(.white)
                                                .padding(.top, 4)
                                        }
                                    }
                                    .padding(16)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                    .background(Color(white: 0.12))
                                }
                                .frame(width: 320, height: 155)
                                .cornerRadius(22)
                                .shadow(radius: 4)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(containerBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .background(Color(white: 0.09))
        .navigationTitle("Moments & Countdowns")
        .onChange(of: item.title) { save() }
        .onChange(of: item.date) { save() }
        .onChange(of: item.isCountUp) { save() }
        .onChange(of: item.blurAmount) { save() }
        .task {
            if let fetchedItem = await CountdownStore.shared.getCountdown() {
                item = fetchedItem
            }
            isLoading = false
        }
        .onReceive(NotificationCenter.default.publisher(for: CountdownStore.localDataChangedNotification)) { _ in
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
