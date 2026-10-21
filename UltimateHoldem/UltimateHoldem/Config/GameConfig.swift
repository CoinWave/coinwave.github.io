import Foundation

/// Every tunable number in the game lives here so you can rebalance without hunting through code.
enum GameConfig {

    // MARK: Sign-up
    /// Chips granted once, when the player creates their profile on first launch.
    static let welcomeBonus = 1_000_000

    // MARK: Daily bonus wheel
    /// Cooldown between free spins.
    static let wheelCooldown: TimeInterval = 24 * 60 * 60

    /// Wheel segments, in display order around the wheel. `weight` controls odds.
    /// Range is 20,000 – 2,000,000 chips; big prizes are deliberately rare.
    static let wheelSegments: [WheelSegment] = [
        WheelSegment(amount: 20_000,    weight: 22, colorHex: "C62828"),
        WheelSegment(amount: 250_000,   weight: 8,  colorHex: "1565C0"),
        WheelSegment(amount: 50_000,    weight: 20, colorHex: "2E7D32"),
        WheelSegment(amount: 1_000_000, weight: 2,  colorHex: "6A1B9A"),
        WheelSegment(amount: 75_000,    weight: 16, colorHex: "EF6C00"),
        WheelSegment(amount: 500_000,   weight: 4,  colorHex: "00838F"),
        WheelSegment(amount: 100_000,   weight: 14, colorHex: "AD1457"),
        WheelSegment(amount: 2_000_000, weight: 1,  colorHex: "F9A825"),
        WheelSegment(amount: 150_000,   weight: 13, colorHex: "4527A0"),
    ]

    // MARK: Tables (lobby carousel)
    static let tables: [TableTier] = [
        TableTier(id: "t1", minAnte: 1_000,      maxAnte: 25_000,      unlockLevel: 1),
        TableTier(id: "t2", minAnte: 5_000,      maxAnte: 100_000,     unlockLevel: 5),
        TableTier(id: "t3", minAnte: 25_000,     maxAnte: 500_000,     unlockLevel: 15),
        TableTier(id: "t4", minAnte: 100_000,    maxAnte: 2_000_000,   unlockLevel: 30),
        TableTier(id: "t5", minAnte: 500_000,    maxAnte: 10_000_000,  unlockLevel: 50),
        TableTier(id: "t6", minAnte: 2_000_000,  maxAnte: 50_000_000,  unlockLevel: 75),
    ]

    // MARK: Progressive jackpot (local to this device)
    static let jackpotSeed = 25_000_000
    /// Share of every progressive bet that feeds the meter.
    static let jackpotContribution = 0.5
    /// Minimum the 10% straight-flush award can pay.
    static let jackpotFloorAfterHit = jackpotSeed

    // MARK: Levels / XP
    /// XP earned per hand = total wagered / table minimum ante, times this.
    static let xpPerMinBet = 10
    static func xpRequired(forLevel level: Int) -> Int {
        Int(100 * pow(Double(level), 1.35))
    }
    static func levelUpReward(forNewLevel level: Int) -> Int {
        level * 25_000
    }

    // MARK: In-app purchases
    /// Product IDs must match App Store Connect (and Products.storekit for local testing).
    /// Base is 2M chips per dollar; the bonus grows with each pack so bigger packs are always better value:
    static let chipPacks: [ChipPack] = [
        ChipPack(productID: "com.yourname.ultimateholdem.chips.tier1", baseChips: 2_000_000,   bonusPercent: 0,   fallbackPrice: "$0.99"),
        ChipPack(productID: "com.yourname.ultimateholdem.chips.tier2", baseChips: 10_000_000,  bonusPercent: 20,  fallbackPrice: "$4.99"),
        ChipPack(productID: "com.yourname.ultimateholdem.chips.tier3", baseChips: 20_000_000,  bonusPercent: 50,  fallbackPrice: "$9.99",  badge: "MOST POPULAR"),
        ChipPack(productID: "com.yourname.ultimateholdem.chips.tier4", baseChips: 40_000_000,  bonusPercent: 75,  fallbackPrice: "$19.99"),
        ChipPack(productID: "com.yourname.ultimateholdem.chips.tier5", baseChips: 60_000_000,  bonusPercent: 100, fallbackPrice: "$29.99"),
        ChipPack(productID: "com.yourname.ultimateholdem.chips.tier6", baseChips: 100_000_000, bonusPercent: 150, fallbackPrice: "$49.99", badge: "BEST VALUE"),
    ]

    // MARK: Promo codes
    /// Codes are built into the app: edit Resources/promo_codes.json and ship an update to change them.

    // MARK: Links
    /// Hosted on GitHub Pages from the CoinWave.github.io repo (ultimate-poker folder).
    static let privacyPolicyURL = URL(string: "https://coinwave.github.io/ultimate-poker/privacy.html")!
    static let termsURL = URL(string: "https://coinwave.github.io/ultimate-poker/support.html")!
}

struct WheelSegment: Identifiable, Hashable {
    let amount: Int
    let weight: Int
    let colorHex: String
    var id: Int { amount }
}

struct TableTier: Identifiable, Hashable {
    let id: String
    let minAnte: Int
    let maxAnte: Int
    let unlockLevel: Int

    /// Progressive side bet is a fixed amount per table.
    var progressiveBet: Int { minAnte }
    /// Max Trips bet.
    var maxTrips: Int { maxAnte }
}

struct ChipPack: Identifiable, Hashable {
    let productID: String
    let baseChips: Int
    let bonusPercent: Int
    let fallbackPrice: String
    var badge: String? = nil

    var id: String { productID }
    var totalChips: Int { baseChips + baseChips * bonusPercent / 100 }
}
