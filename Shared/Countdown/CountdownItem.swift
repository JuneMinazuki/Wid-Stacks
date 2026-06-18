import Foundation

struct CountdownItem: Identifiable, Codable, Sendable {
    var id = UUID()
    var title: String
    var date: Date
    var isCountUp: Bool
    var blurAmount: Double
    var selectedGradientIndex: Int
    var selectedEmoji: String?
    var useCustomBackground: Bool?
}
