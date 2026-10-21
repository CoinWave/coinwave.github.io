import Foundation

struct PromoCode: Codable, Hashable {
    let code: String
    /// Extra chips added to the purchased pack, as a percent of the pack's total chips.
    let bonusPercent: Int
    /// "yyyy-MM-dd" (inclusive). Omit for no expiry.
    let expires: String?
    /// If true (default), each player can use the code once.
    let oncePerPlayer: Bool?
    /// Optional: only valid on packs at or above this product ID's tier.
    let minProductID: String?
    /// Optional short text shown when applied, e.g. "Holiday bonus!"
    let label: String?

    var expiryDate: Date? {
        guard let expires else { return nil }
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        // End of that day, local time.
        return f.date(from: expires).map { Calendar.current.date(byAdding: .day, value: 1, to: $0)! }
    }
}

private struct PromoCodeList: Codable {
    let codes: [PromoCode]
}

enum PromoError: LocalizedError {
    case empty, notFound, expired, alreadyUsed

    var errorDescription: String? {
        switch self {
        case .empty: return "Enter a promo code."
        case .notFound: return "That code isn't valid."
        case .expired: return "That code has expired."
        case .alreadyUsed: return "You've already used that code."
        }
    }
}

/// Validates promo codes against the list built into the app (Resources/promo_codes.json).
@MainActor
final class PromoCodeService: ObservableObject {
    @Published private(set) var codes: [PromoCode] = []

    init() {
        codes = Self.loadBundled()
    }

    func validate(_ raw: String, player: PlayerStore, now: Date = Date()) -> Result<PromoCode, PromoError> {
        let entered = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !entered.isEmpty else { return .failure(.empty) }
        guard let match = codes.first(where: { $0.code.uppercased() == entered }) else {
            return .failure(.notFound)
        }
        if let expiry = match.expiryDate, now >= expiry { return .failure(.expired) }
        if match.oncePerPlayer ?? true, player.hasRedeemed(code: entered) { return .failure(.alreadyUsed) }
        return .success(match)
    }

    /// Whether a code applies to a given pack (respects `minProductID`).
    func applies(_ code: PromoCode, to pack: ChipPack) -> Bool {
        guard let minID = code.minProductID,
              let minIndex = GameConfig.chipPacks.firstIndex(where: { $0.productID == minID }),
              let packIndex = GameConfig.chipPacks.firstIndex(of: pack) else { return true }
        return packIndex >= minIndex
    }

    func bonusChips(for code: PromoCode, pack: ChipPack) -> Int {
        guard applies(code, to: pack) else { return 0 }
        return pack.totalChips * code.bonusPercent / 100
    }

    private static func loadBundled() -> [PromoCode] {
        guard let url = Bundle.main.url(forResource: "promo_codes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder().decode(PromoCodeList.self, from: data) else { return [] }
        return list.codes
    }
}
