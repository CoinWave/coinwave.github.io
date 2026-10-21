import Foundation

struct Bets: Codable, Equatable {
    var ante: Int = 0
    var blind: Int = 0
    var play: Int = 0
    var trips: Int = 0
    var progressive: Int = 0

    var total: Int { ante + blind + play + trips + progressive }
}

enum HandOutcome: String {
    case win, lose, push, fold
}

/// Net result of one bet (`net` is profit; -stake means the bet lost).
struct BetResult: Identifiable {
    let name: String
    let stake: Int
    let net: Int
    let note: String

    var id: String { name }
    /// What goes back to the player's balance (stake + profit, never negative).
    var returned: Int { max(0, stake + net) }
}

struct Settlement {
    let outcome: HandOutcome
    let dealerQualifies: Bool
    let playerHand: EvaluatedHand
    let dealerHand: EvaluatedHand
    let progressiveHand: EvaluatedHand
    let results: [BetResult]
    /// Chips taken out of the progressive jackpot (0 unless a jackpot % was hit).
    let jackpotPaid: Int

    var totalReturned: Int { results.reduce(0) { $0 + $1.returned } }
    var totalStaked: Int { results.reduce(0) { $0 + $1.stake } }
    var netWin: Int { totalReturned - totalStaked }
}

enum UTHRules {

    /// Settles a finished hand. Pure function: no state, easy to test.
    static func settle(playerHole: [Card],
                       dealerHole: [Card],
                       board: [Card],
                       bets: Bets,
                       folded: Bool,
                       jackpot: Int) -> Settlement {
        precondition(playerHole.count == 2 && dealerHole.count == 2 && board.count == 5)

        let player = HandEvaluator.best(playerHole + board)
        let dealer = HandEvaluator.best(dealerHole + board)
        let progHand = HandEvaluator.best(playerHole + Array(board.prefix(3)))
        let qualifies = dealer.category >= .onePair

        var results: [BetResult] = []
        let outcome: HandOutcome

        if folded {
            outcome = .fold
            results.append(BetResult(name: "Ante", stake: bets.ante, net: -bets.ante, note: "Folded"))
            results.append(BetResult(name: "Blind", stake: bets.blind, net: -bets.blind, note: "Folded"))
        } else if player > dealer {
            outcome = .win
            results.append(BetResult(name: "Play", stake: bets.play, net: bets.play, note: "1 to 1"))
            if qualifies {
                results.append(BetResult(name: "Ante", stake: bets.ante, net: bets.ante, note: "1 to 1"))
            } else {
                results.append(BetResult(name: "Ante", stake: bets.ante, net: 0, note: "Push – dealer didn't qualify"))
            }
            if let m = Paytables.blindMultiple(for: player.category) {
                results.append(BetResult(name: "Blind", stake: bets.blind,
                                         net: Int((Double(bets.blind) * m).rounded(.down)),
                                         note: Paytables.describe(m)))
            } else {
                results.append(BetResult(name: "Blind", stake: bets.blind, net: 0, note: "Push"))
            }
        } else if player < dealer {
            outcome = .lose
            results.append(BetResult(name: "Play", stake: bets.play, net: -bets.play, note: "Lost"))
            if qualifies {
                results.append(BetResult(name: "Ante", stake: bets.ante, net: -bets.ante, note: "Lost"))
            } else {
                results.append(BetResult(name: "Ante", stake: bets.ante, net: 0, note: "Push – dealer didn't qualify"))
            }
            results.append(BetResult(name: "Blind", stake: bets.blind, net: -bets.blind, note: "Lost"))
        } else {
            outcome = .push
            results.append(BetResult(name: "Play", stake: bets.play, net: 0, note: "Tie"))
            results.append(BetResult(name: "Ante", stake: bets.ante, net: 0, note: "Tie"))
            results.append(BetResult(name: "Blind", stake: bets.blind, net: 0, note: "Tie"))
        }

        // Trips: player's final hand only, independent of the dealer (also settles on a fold).
        if bets.trips > 0 {
            if let m = Paytables.tripsMultiple(for: player.category) {
                results.append(BetResult(name: "Trips", stake: bets.trips,
                                         net: Int((Double(bets.trips) * m).rounded(.down)),
                                         note: "\(player.category.name) \(Paytables.describe(m))"))
            } else {
                results.append(BetResult(name: "Trips", stake: bets.trips, net: -bets.trips, note: "Lost"))
            }
        }

        // Progressive: hole cards + flop.
        var jackpotPaid = 0
        if bets.progressive > 0 {
            switch Paytables.progressivePay(for: progHand.category) {
            case .percentOfJackpot(let pct):
                jackpotPaid = Int((Double(jackpot) * pct).rounded(.down))
                let pctLabel = pct >= 1 ? "JACKPOT!" : "\(Int(pct * 100))% of jackpot"
                results.append(BetResult(name: "Progressive", stake: bets.progressive,
                                         net: jackpotPaid, note: "\(progHand.category.name) – \(pctLabel)"))
            case .multiple(let m):
                results.append(BetResult(name: "Progressive", stake: bets.progressive,
                                         net: Int(Double(bets.progressive) * m),
                                         note: "\(progHand.category.name) \(Int(m))x"))
            case nil:
                results.append(BetResult(name: "Progressive", stake: bets.progressive,
                                         net: -bets.progressive, note: "Lost"))
            }
        }

        // Drop empty lines (e.g. Play when the player folded) for a clean summary.
        results = results.filter { $0.stake > 0 }

        return Settlement(outcome: outcome,
                          dealerQualifies: qualifies,
                          playerHand: player,
                          dealerHand: dealer,
                          progressiveHand: progHand,
                          results: results,
                          jackpotPaid: jackpotPaid)
    }
}
