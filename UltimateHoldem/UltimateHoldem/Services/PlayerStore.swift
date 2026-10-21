import Foundation
import SwiftUI

struct PlayerProfile: Codable {
    var name: String = ""
    var createdAt: Date? = nil
    var chips: Int = 0
    var level: Int = 1
    var xp: Int = 0
    var lastWheelSpin: Date? = nil
    var handsPlayed: Int = 0
    var biggestWin: Int = 0
    var processedTransactionIDs: Set<UInt64> = []
    var redeemedPromoCodes: Set<String> = []
    var hapticsOn: Bool = true
    var fastDeal: Bool = false
}

struct LevelUpEvent: Identifiable, Equatable {
    let id = UUID()
    let level: Int
    let reward: Int
}

/// The player's wallet, level and settings. Saved to UserDefaults on every change.
@MainActor
final class PlayerStore: ObservableObject {
    @Published private(set) var profile: PlayerProfile
    @Published var pendingLevelUp: LevelUpEvent?

    private let key = "uth.player.profile.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let saved = try? JSONDecoder().decode(PlayerProfile.self, from: data) {
            profile = saved
        } else {
            profile = PlayerProfile()
        }
    }

    // MARK: Sign-up

    var isSignedUp: Bool { profile.createdAt != nil }

    /// Creates the profile and grants the one-time welcome bonus.
    func signUp(name: String) {
        guard !isSignedUp else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.name = trimmed.isEmpty ? "Player" : String(trimmed.prefix(16))
        profile.createdAt = Date()
        profile.chips += GameConfig.welcomeBonus
        save()
    }

    func rename(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        profile.name = String(trimmed.prefix(16))
        save()
    }

    // MARK: Chips

    var chips: Int { profile.chips }

    func canAfford(_ amount: Int) -> Bool { amount <= profile.chips }

    @discardableResult
    func spend(_ amount: Int) -> Bool {
        guard amount >= 0, amount <= profile.chips else { return false }
        profile.chips -= amount
        save()
        return true
    }

    func credit(_ amount: Int) {
        guard amount > 0 else { return }
        profile.chips += amount
        save()
    }

    // MARK: Hand bookkeeping / XP

    func recordHand(totalWagered: Int, tableMin: Int, netWin: Int) {
        profile.handsPlayed += 1
        if netWin > profile.biggestWin { profile.biggestWin = netWin }

        let xpGain = max(1, totalWagered / max(1, tableMin)) * GameConfig.xpPerMinBet
        profile.xp += xpGain
        var leveled: LevelUpEvent?
        while profile.xp >= GameConfig.xpRequired(forLevel: profile.level) {
            profile.xp -= GameConfig.xpRequired(forLevel: profile.level)
            profile.level += 1
            let reward = GameConfig.levelUpReward(forNewLevel: profile.level)
            profile.chips += reward
            leveled = LevelUpEvent(level: profile.level,
                                   reward: (leveled?.reward ?? 0) + reward)
        }
        save()
        if let leveled { pendingLevelUp = leveled }
    }

    var levelProgress: Double {
        Double(profile.xp) / Double(GameConfig.xpRequired(forLevel: profile.level))
    }

    // MARK: Daily wheel

    var nextWheelSpin: Date {
        guard let last = profile.lastWheelSpin else { return .distantPast }
        return last.addingTimeInterval(GameConfig.wheelCooldown)
    }

    func canSpinWheel(now: Date = Date()) -> Bool { now >= nextWheelSpin }

    func recordWheelSpin(prize: Int) {
        profile.lastWheelSpin = Date()
        profile.chips += prize
        save()
    }

    // MARK: Purchases / promo codes

    func hasProcessed(transactionID: UInt64) -> Bool {
        profile.processedTransactionIDs.contains(transactionID)
    }

    func recordPurchase(transactionID: UInt64, chips: Int) {
        guard !hasProcessed(transactionID: transactionID) else { return }
        profile.processedTransactionIDs.insert(transactionID)
        profile.chips += chips
        save()
    }

    func hasRedeemed(code: String) -> Bool {
        profile.redeemedPromoCodes.contains(code.uppercased())
    }

    func markRedeemed(code: String) {
        profile.redeemedPromoCodes.insert(code.uppercased())
        save()
    }

    // MARK: Settings

    var hapticsOn: Bool {
        get { profile.hapticsOn }
        set { profile.hapticsOn = newValue; save() }
    }

    var fastDeal: Bool {
        get { profile.fastDeal }
        set { profile.fastDeal = newValue; save() }
    }

    #if DEBUG
    // MARK: Tester tools (Debug builds only)

    func debugResetWheel() {
        profile.lastWheelSpin = nil
        save()
    }

    func debugSetLevel(_ level: Int) {
        profile.level = max(1, level)
        profile.xp = 0
        save()
    }
    #endif

    // MARK: Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(profile) {
            defaults.set(data, forKey: key)
        }
    }
}
