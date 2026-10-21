import Foundation

enum HandCategory: Int, Comparable, CaseIterable, Codable {
    case highCard = 0, onePair, twoPair, threeOfAKind, straight, flush, fullHouse, fourOfAKind, straightFlush, royalFlush

    static func < (lhs: HandCategory, rhs: HandCategory) -> Bool { lhs.rawValue < rhs.rawValue }

    var name: String {
        switch self {
        case .highCard: return "High Card"
        case .onePair: return "Pair"
        case .twoPair: return "Two Pair"
        case .threeOfAKind: return "Three of a Kind"
        case .straight: return "Straight"
        case .flush: return "Flush"
        case .fullHouse: return "Full House"
        case .fourOfAKind: return "Four of a Kind"
        case .straightFlush: return "Straight Flush"
        case .royalFlush: return "Royal Flush"
        }
    }
}

struct EvaluatedHand: Comparable {
    let category: HandCategory
    /// Tie-break ranks, most significant first.
    let tiebreak: [Int]
    /// The five cards that make the hand.
    let cards: [Card]

    /// Single comparable integer: category, then up to 5 tiebreak ranks (4 bits each).
    var score: Int {
        var s = category.rawValue
        for i in 0..<5 {
            s = (s << 4) | (i < tiebreak.count ? tiebreak[i] : 0)
        }
        return s
    }

    static func < (lhs: EvaluatedHand, rhs: EvaluatedHand) -> Bool { lhs.score < rhs.score }
    static func == (lhs: EvaluatedHand, rhs: EvaluatedHand) -> Bool { lhs.score == rhs.score }
}

enum HandEvaluator {

    /// Best five-card hand from 5, 6 or 7 cards.
    static func best(_ cards: [Card]) -> EvaluatedHand {
        precondition(cards.count >= 5 && cards.count <= 7, "Need 5–7 cards")
        var best: EvaluatedHand?
        forEachCombination(of: cards, choose: 5) { combo in
            let hand = evaluate5(combo)
            if best == nil || hand > best! { best = hand }
        }
        return best!
    }

    static func evaluate5(_ cards: [Card]) -> EvaluatedHand {
        precondition(cards.count == 5)

        let values = cards.map { $0.rank.value }.sorted(by: >)
        let isFlush = Set(cards.map { $0.suit }).count == 1

        // Straight detection (including A-2-3-4-5 "wheel").
        let unique = Array(Set(values)).sorted(by: >)
        var straightHigh: Int? = nil
        if unique.count == 5 {
            if unique[0] - unique[4] == 4 {
                straightHigh = unique[0]
            } else if unique == [14, 5, 4, 3, 2] {
                straightHigh = 5
            }
        }

        // Group ranks by count, ordered by (count desc, rank desc).
        var counts: [Int: Int] = [:]
        for v in values { counts[v, default: 0] += 1 }
        let groups = counts.sorted { a, b in
            a.value != b.value ? a.value > b.value : a.key > b.key
        }
        let groupRanks = groups.map { $0.key }
        let pattern = groups.map { $0.value }

        let category: HandCategory
        var tiebreak: [Int]

        if let high = straightHigh, isFlush {
            category = high == 14 ? .royalFlush : .straightFlush
            tiebreak = [high]
        } else if pattern == [4, 1] {
            category = .fourOfAKind
            tiebreak = groupRanks
        } else if pattern == [3, 2] {
            category = .fullHouse
            tiebreak = groupRanks
        } else if isFlush {
            category = .flush
            tiebreak = values
        } else if let high = straightHigh {
            category = .straight
            tiebreak = [high]
        } else if pattern == [3, 1, 1] {
            category = .threeOfAKind
            tiebreak = groupRanks
        } else if pattern == [2, 2, 1] {
            category = .twoPair
            tiebreak = groupRanks
        } else if pattern == [2, 1, 1, 1] {
            category = .onePair
            tiebreak = groupRanks
        } else {
            category = .highCard
            tiebreak = values
        }

        return EvaluatedHand(category: category, tiebreak: tiebreak, cards: cards)
    }

    private static func forEachCombination(of items: [Card], choose k: Int, _ body: ([Card]) -> Void) {
        var indices = Array(0..<k)
        let n = items.count
        while true {
            body(indices.map { items[$0] })
            var i = k - 1
            while i >= 0 && indices[i] == n - k + i { i -= 1 }
            if i < 0 { return }
            indices[i] += 1
            for j in (i + 1)..<k { indices[j] = indices[j - 1] + 1 }
        }
    }
}
