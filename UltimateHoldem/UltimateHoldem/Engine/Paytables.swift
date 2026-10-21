import Foundation

/// All payout tables in one place. Values are "X to 1" (profit multiples of the bet).
enum Paytables {

    /// Blind pays only when the player BEATS the dealer with a straight or better.
    /// Below a straight, a winning Blind pushes.
    static let blind: [(HandCategory, Double)] = [
        (.royalFlush, 500),
        (.straightFlush, 50),
        (.fourOfAKind, 10),
        (.fullHouse, 3),
        (.flush, 1.5),
        (.straight, 1),
    ]

    /// Trips pays on the player's final 7-card hand, regardless of the dealer.
    static let trips: [(HandCategory, Double)] = [
        (.royalFlush, 50),
        (.straightFlush, 40),
        (.fourOfAKind, 30),
        (.fullHouse, 8),
        (.flush, 6),
        (.straight, 5),
        (.threeOfAKind, 3),
    ]

    enum ProgressivePay {
        case percentOfJackpot(Double)
        case multiple(Double)   // X times the progressive bet
    }

    /// Progressive pays on the player's two hole cards + the 3-card flop (first five cards).
    static let progressive: [(HandCategory, ProgressivePay)] = [
        (.royalFlush, .percentOfJackpot(1.0)),
        (.straightFlush, .percentOfJackpot(0.10)),
        (.fourOfAKind, .multiple(300)),
        (.fullHouse, .multiple(50)),
        (.flush, .multiple(40)),
        (.straight, .multiple(30)),
        (.threeOfAKind, .multiple(9)),
    ]

    static func blindMultiple(for category: HandCategory) -> Double? {
        blind.first { $0.0 == category }?.1
    }

    static func tripsMultiple(for category: HandCategory) -> Double? {
        trips.first { $0.0 == category }?.1
    }

    static func progressivePay(for category: HandCategory) -> ProgressivePay? {
        progressive.first { $0.0 == category }?.1
    }

    static func describe(_ m: Double) -> String {
        m == 1.5 ? "3 to 2" : "\(Int(m)) to 1"
    }
}
