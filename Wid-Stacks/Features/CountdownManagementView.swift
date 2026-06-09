import SwiftUI
import PhotosUI

struct CountdownManagementView: View {
    @State private var item: CountdownItem = CountdownItem(
        title: "", date: Date(), isCountUp: false, blurAmount: 0.0, selectedGradientIndex: 0, selectedEmoji: nil, useCustomBackground: false
    )
    @State private var isLoading = true
    @State private var saveTask: Task<Void, Never>? = nil
    @State private var isSavingInternally = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    
    private let availableEmojis = ["🎯", "🚀", "🎂", "🎓", "💍", "🏖️", "🎄", "🍿", "💼", "🏋️‍♂️", "🎮", "🏡"]
    
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
    
    var autoIsCountUp: Bool {
        daysRemaining < 0
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
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                            Text("Widget Configuration")
                        }
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 20) {
                            // Event Title Text Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Event Title")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                TextField("e.g., Project Launch", text: $item.title)
                                    .textFieldStyle(.plain)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(Color(white: 0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .foregroundColor(.white)
                            }
                            
                            // Date Pickers
                            HStack {
                                Label("Target Date", systemImage: "calendar")
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.9))
                                Spacer()
                                DatePicker("", selection: $item.date, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                            }
                            .padding(.vertical, 4)

                            Divider().background(Color.white.opacity(0.1))
                            
                            // Emoji Picker
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Label("Widget Icon Emoji", systemImage: "face.smiling")
                                        .font(.body)
                                        .foregroundColor(.white.opacity(0.9))
                                    Spacer()
                                    if item.selectedEmoji != nil {
                                        Button(action: {
                                            item.selectedEmoji = nil
                                            save()
                                        }) {
                                            Text("Clear")
                                                .font(.caption2)
                                                .fontWeight(.medium)
                                                .foregroundColor(.red.opacity(0.8))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(availableEmojis, id: \.self) { emoji in
                                            Text(emoji)
                                                .font(.title2)
                                                .frame(width: 44, height: 44)
                                                .background(item.selectedEmoji == emoji ? Color.white.opacity(0.15) : Color(white: 0.12))
                                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                        .stroke(Color.accentColor, lineWidth: item.selectedEmoji == emoji ? 2 : 0)
                                                )
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    if item.selectedEmoji == emoji { item.selectedEmoji = nil }
                                                    else { item.selectedEmoji = emoji }
                                                    save()
                                                }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            // Blur Amount Slider
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Label("Background Blur", systemImage: "sparkles")
                                    Spacer()
                                    Text("\(Int(item.blurAmount))%")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .foregroundColor(.white.opacity(0.9))
                                Slider(value: $item.blurAmount, in: 0...100, step: 5)
                                    .tint(.accentColor)
                            }
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            // Custom Image Background Picker
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Custom Background Photo")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 12) {
                                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                        Label((item.useCustomBackground ?? false) ? "Change Photo" : "Choose Photo", systemImage: "photo.on.rectangle")
                                            .font(.body)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(Color(white: 0.12))
                                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                    
                                    if item.useCustomBackground == true {
                                        Button(action: {
                                            item.useCustomBackground = false
                                            CountdownStore.shared.deleteBackgroundImage()
                                            save()
                                        }) {
                                            Text("Remove Photo")
                                                .font(.caption2)
                                                .fontWeight(.medium)
                                                .foregroundColor(.red.opacity(0.8))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 4)
                            }

                            Divider().background(Color.white.opacity(0.1))
                            
                            // Color Matrix Themes
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Theme Preset")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                HStack(spacing: 16) {
                                   ForEach(0..<sampleGradients.count, id: \.self) { index in
                                       Circle()
                                           .fill(sampleGradients[index])
                                           .frame(width: 36, height: 36)
                                           .overlay(
                                               Circle()
                                                   .stroke(Color.white, lineWidth: item.selectedGradientIndex == index ? 2 : 0)
                                                   .padding(-4)
                                           )
                                           .onTapGesture {
                                               if item.selectedGradientIndex != index {
                                                   item.selectedGradientIndex = index
                                                   save()
                                               }
                                           }
                                   }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(20)
                        .background(containerBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal)
                    }
                    
                    // Widget Preview Section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "eye")
                            Text("Widget Preview")
                        }
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
                                    if item.useCustomBackground == true, let nsImage = NSImage(contentsOf: CountdownStore.shared.backgroundImageURL) {
                                        Image(nsImage: nsImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 155, height: 155)
                                            .blur(radius: CGFloat(item.blurAmount / 5))
                                            .clipped()
                                    } else {
                                        sampleGradients[item.selectedGradientIndex]
                                            .blur(radius: CGFloat(item.blurAmount / 5))
                                    }
                                    
                                    if let emoji = item.selectedEmoji {
                                        Text(emoji)
                                            .font(.title)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                            .padding(16)
                                    }
                                    
                                    Text("\(abs(daysRemaining))")
                                        .font(.system(size: 42, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                        .padding(16)
                                    
                                    Text(autoIsCountUp ? "Days since\n\(item.title.isEmpty ? "Event" : item.title)" : "Days until\n\(item.title.isEmpty ? "Event" : item.title)")
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
                                        if item.useCustomBackground == true, let nsImage = NSImage(contentsOf: CountdownStore.shared.backgroundImageURL) {
                                            Image(nsImage: nsImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 110, height: 155)
                                                .blur(radius: CGFloat(item.blurAmount / 5))
                                                .clipped()
                                        } else {
                                            sampleGradients[item.selectedGradientIndex]
                                                .blur(radius: CGFloat(item.blurAmount / 5))
                                        }
                                        
                                        if let emoji = item.selectedEmoji {
                                            Text(emoji)
                                                .font(.system(size: 34))
                                        } else {
                                            Image(systemName: autoIsCountUp ? "clock.arrow.2.circlepath" : "hourglass")
                                                .font(.title)
                                                .foregroundColor(.white)
                                        }
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
                                        
                                        Text(autoIsCountUp ? "Time has accumulated" : "Time remaining to milestone")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
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
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .background(Color(white: 0.09))
        .navigationTitle("Moments & Countdowns")
        
        .onChange(of: item.title) { old, new in if old != new { save() } }
        .onChange(of: item.date) { old, new in if old != new { save() } }
        .onChange(of: item.blurAmount) { old, new in if old != new { save() } }
        .onChange(of: item.selectedEmoji) { old, new in if old != new { save() } }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    CountdownStore.shared.saveBackgroundImage(data: data)
                    item.useCustomBackground = true
                    save()
                }
            }
        }
        .task {
            if let fetchedItem = await CountdownStore.shared.getCountdown() {
                self.item = fetchedItem
            }
            isLoading = false
        }
        .onReceive(NotificationCenter.default.publisher(for: CountdownStore.localDataChangedNotification)) { _ in
            guard !isSavingInternally else { return }
            
            Task {
                if let fetchedItem = await CountdownStore.shared.getCountdown() {
                    if self.item.title != fetchedItem.title ||
                        self.item.date != fetchedItem.date ||
                        self.item.blurAmount != fetchedItem.blurAmount ||
                        self.item.selectedGradientIndex != fetchedItem.selectedGradientIndex ||
                        self.item.selectedEmoji != fetchedItem.selectedEmoji ||
                        self.item.useCustomBackground != fetchedItem.useCustomBackground {
                        
                        self.item = fetchedItem
                    }
                }
            }
        }
    }

    private func save() {
        saveTask?.cancel()
        saveTask = Task {
            isSavingInternally = true
            
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            guard !Task.isCancelled else { return }
            
            var finalItem = item
            finalItem.isCountUp = autoIsCountUp
            
            CountdownStore.shared.saveCountdown(finalItem)
            
            try? await Task.sleep(nanoseconds: 50_000_000)
            isSavingInternally = false
        }
    }
}
