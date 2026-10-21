import Foundation
import SwiftUI

enum GamePhase: Equatable {
    case betting      // placing Ante/Blind, Trips, Progressive
    case preflop      // check, or Play 3x / 4x
    case flop         // check, or Play 2x
    case river        // Play 1x, or fold
    case showdown     // results shown
}

enum BetSpot { case ante, trips }

/// Drives one table session: bets, dealing, decisions, settlement.
@MainActor
final class TableGame: ObservableObject {
    let table: TableTier
    private let player: PlayerStore
    private let jackpot: JackpotStore

    @Published private(set) var phase: GamePhase = .betting
    @Published private(set) var playerHole: [Card] = []
    @Published private(set) var dealerHole: [Card] = []
    @Published private(set) var board: [Card] = []
    @Published private(set) var boardRevealed = 0
    @Published private(set) var dealerRevealed = false
    @Published private(set) var bets = Bets()
    @Published private(set) var settlement: Settlement?
    @Published private(set) var isBusy = false
    @Published var message: String = "Place your Ante to begin"

    // Bets being built during the betting phase.
    @Published var pendingAnte = 0
    @Published var pendingTrips = 0
    @Published var progressiveOn = false
    @Published var selectedChip: Int

    private var lastBets: (ante: Int, trips: Int, prog: Bool)?

    init(table: TableTier, player: PlayerStore, jackpot: JackpotStore) {
        self.table = table
        self.player = player
        self.jackpot = jackpot
        self.selectedChip = table.minAnte
    }

    /// Chip denominations offered at this table.
    var chipValues: [Int] {
        [1, 5, 25, 100].map { $0 * table.minAnte }
    }

    // MARK: Betting phase

    /// Up-front cost to deal: Ante + Blind + Trips + Progressive.
    var pendingCost: Int {
        pendingAnte * 2 + pendingTrips + (progressiveOn ? table.progressiveBet : 0)
    }

    func addChip(to spot: BetSpot) {
        guard phase == .betting, !isBusy else { return }
        let chip = selectedChip
        switch spot {
        case .ante:
            let next = min(table.maxAnte, pendingAnte + chip)
            guard next != pendingAnte else { message = "Table max Ante is \(table.maxAnte.chipString)"; return }
            guard costWith(ante: next) <= player.chips else { message = "Not enough chips"; return }
            pendingAnte = next
        case .trips:
            let next = min(table.maxTrips, pendingTrips + chip)
            guard next != pendingTrips else { message = "Table max Trips is \(table.maxTrips.chipString)"; return }
            guard costWith(trips: next) <= player.chips else { message = "Not enough chips"; return }
            pendingTrips = next
        }
        message = "Tap DEAL when ready"
        Haptics.tap(player.hapticsOn)
    }

    func toggleProgressive() {
        guard phase == .betting, !isBusy else { return }
        if !progressiveOn && costWith(prog: true) > player.chips {
            message = "Not enough chips"; return
        }
        progressiveOn.toggle()
        Haptics.tap(player.hapticsOn)
    }

    func clearBets() {
        guard phase == .betting else { return }
        pendingAnte = 0
        pendingTrips = 0
        progressiveOn = false
        message = "Place your Ante to begin"
    }

    var canRebet: Bool {
        guard phase == .betting, let last = lastBets else { return false }
        return last.ante * 2 + last.trips + (last.prog ? table.progressiveBet : 0) <= player.chips
    }

    func rebet() {
        guard let last = lastBets, canRebet else { return }
        pendingAnte = last.ante
        pendingTrips = last.trips
        progressiveOn = last.prog
        message = "Tap DEAL when ready"
    }

    private func costWith(ante: Int? = nil, trips: Int? = nil, prog: Bool? = nil) -> Int {
        (ante ?? pendingAnte) * 2 + (trips ?? pendingTrips)
            + ((prog ?? progressiveOn) ? table.progressiveBet : 0)
    }

    // MARK: Deal

    var canDeal: Bool {
        phase == .betting && !isBusy && pendingAnte >= table.minAnte && pendingCost <= player.chips
    }

    func deal() async {
        guard canDeal else {
            if pendingAnte < table.minAnte { message = "Minimum Ante is \(table.minAnte.chipString)" }
            return
        }
        guard player.spend(pendingCost) else { message = "Not enough chips"; return }

        bets = Bets(ante: pendingAnte, blind: pendingAnte, play: 0,
                    trips: pendingTrips, progressive: progressiveOn ? table.progressiveBet : 0)
        lastBets = (pendingAnte, pendingTrips, progressiveOn)
        if bets.progressive > 0 { jackpot.contribute(bet: bets.progressive) }

        var deck = Deck()
        playerHole = deck.draw(2)
        dealerHole = deck.draw(2)
        board = deck.draw(5)
        boardRevealed = 0
        dealerRevealed = false
        settlement = nil

        isBusy = true
        await pause(0.35)
        isBusy = false
        phase = .preflop
        message = "Check, or Play 3x / 4x your Ante"
        Haptics.tap(player.hapticsOn)
    }

    // MARK: Decisions

    /// Multipliers available in the current phase.
    var playOptions: [Int] {
        switch phase {
        case .preflop: return [4, 3]
        case .flop: return [2]
        case .river: return [1]
        default: return []
        }
    }

    func canAffordPlay(_ multiple: Int) -> Bool {
        bets.ante * multiple <= player.chips
    }

    var canCheck: Bool { phase == .preflop || phase == .flop }
    var canFold: Bool { phase == .river }

    func play(_ multiple: Int) async {
        guard playOptions.contains(multiple), !isBusy else { return }
        guard player.spend(bets.ante * multiple) else { message = "Not enough chips"; return }
        bets.play = bets.ante * multiple
        Haptics.tap(player.hapticsOn)
        await finishHand(folded: false)
    }

    func check() async {
        guard canCheck, !isBusy else { return }
        isBusy = true
        if phase == .preflop {
            await revealBoard(to: 3)
            phase = .flop
            message = "Check, or Play 2x your Ante"
        } else {
            await revealBoard(to: 5)
            phase = .river
            message = "Play 1x your Ante, or Fold"
        }
        isBusy = false
    }

    func fold() async {
        guard canFold, !isBusy else { return }
        await finishHand(folded: true)
    }

    // MARK: Settlement

    private func finishHand(folded: Bool) async {
        isBusy = true
        await revealBoard(to: 5)
        await pause(0.3)
        withAnimation(.spring) { dealerRevealed = true }
        await pause(0.5)

        let result = UTHRules.settle(playerHole: playerHole,
                                     dealerHole: dealerHole,
                                     board: board,
                                     bets: bets,
                                     folded: folded,
                                     jackpot: jackpot.amount)
        if result.jackpotPaid > 0 { jackpot.pay(result.jackpotPaid) }
        player.credit(result.totalReturned)
        player.recordHand(totalWagered: result.totalStaked, tableMin: table.minAnte, netWin: result.netWin)

        settlement = result
        phase = .showdown
        isBusy = false
        message = summaryLine(result)
        if result.netWin > 0 { Haptics.win(player.hapticsOn) }
    }

    func nextHand() {
        guard phase == .showdown else { return }
        playerHole = []
        dealerHole = []
        board = []
        boardRevealed = 0
        dealerRevealed = false
        settlement = nil
        bets = Bets()
        phase = .betting
        // Keep the same bets ready if still affordable.
        if canRebet { rebet() } else { clearBets() }
    }

    private func summaryLine(_ s: Settlement) -> String {
        let hand = s.playerHand.category.name
        switch s.outcome {
        case .fold: return "Folded"
        case .push: return "Push – \(hand) ties"
        case .win: return "You win with \(hand)! +\(s.netWin.chipString)"
        case .lose:
            return s.netWin >= 0
                ? "Dealer wins, side bets paid +\(s.netWin.chipString)"
                : "Dealer wins with \(s.dealerHand.category.name)"
        }
    }

    // MARK: Helpers

    private func revealBoard(to count: Int) async {
        while boardRevealed < count {
            withAnimation(.spring(duration: 0.3)) { boardRevealed += 1 }
            Haptics.tap(player.hapticsOn)
            await pause(boardRevealed <= 3 && count == 3 ? 0.15 : 0.3)
        }
    }

    private func pause(_ seconds: Double) async {
        let s = player.fastDeal ? seconds * 0.4 : seconds
        try? await Task.sleep(nanoseconds: UInt64(s * 1_000_000_000))
    }
}
