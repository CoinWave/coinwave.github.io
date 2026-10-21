import SwiftUI
import UIKit

extension Int {
    /// 15016580 -> "$15,016,580"
    var chipString: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return "$" + (f.string(from: NSNumber(value: self)) ?? String(self))
    }

    /// 1500000 -> "$1.5M", 250000 -> "$250K"
    var shortChipString: String {
        let v = Double(self)
        func trim(_ d: Double) -> String {
            d.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(d)) : String(format: "%.1f", d)
        }
        switch v {
        case 1_000_000_000...: return "$" + trim(v / 1_000_000_000) + "B"
        case 1_000_000...: return "$" + trim(v / 1_000_000) + "M"
        case 1_000...: return "$" + trim(v / 1_000) + "K"
        default: return "$\(self)"
        }
    }
}

enum Haptics {
    static func tap(_ enabled: Bool) {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func win(_ enabled: Bool) {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

extension Color {
    init(hex: String) {
        var value: UInt64 = 0
        Scanner(string: hex.replacingOccurrences(of: "#", with: "")).scanHexInt64(&value)
        self.init(red: Double((value >> 16) & 0xFF) / 255,
                  green: Double((value >> 8) & 0xFF) / 255,
                  blue: Double(value & 0xFF) / 255)
    }
}

/// Shared visual theme (casino red lobby + blue felt table).
enum Theme {
    static let lobbyTop = Color(hex: "7A0A0A")
    static let lobbyBottom = Color(hex: "3A0303")
    static let felt = Color(hex: "1E3F73")
    static let feltDark = Color(hex: "142B52")
    static let gold = Color(hex: "F2B529")
    static let goldDark = Color(hex: "C88A12")
    static let feltLine = Color.white.opacity(0.85)
    static let accentRed = Color(hex: "E53935")
}
