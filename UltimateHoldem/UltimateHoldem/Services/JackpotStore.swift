import Foundation

/// Local progressive jackpot. Grows by a share of every progressive bet; resets to the seed when hit.
/// To make it shared across all players later, swap this class for one backed by a server
/// (the rest of the app only calls `contribute`, `pay` and reads `amount`).
@MainActor
final class JackpotStore: ObservableObject {
    @Published private(set) var amount: Int
    @Published private(set) var lastWinAmount: Int?

    private let key = "uth.jackpot.amount.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let saved = defaults.integer(forKey: key)
        amount = saved > 0 ? saved : GameConfig.jackpotSeed
    }

    func contribute(bet: Int) {
        amount += Int(Double(bet) * GameConfig.jackpotContribution)
        save()
    }

    /// Removes a paid award from the meter. A full jackpot resets to the seed.
    func pay(_ paid: Int) {
        guard paid > 0 else { return }
        lastWinAmount = paid
        // A full hit leaves 0, so the meter reseeds; a 10% hit just drops it (never below the seed).
        amount = max(GameConfig.jackpotFloorAfterHit, amount - paid)
        save()
    }

    private func save() { defaults.set(amount, forKey: key) }
}
