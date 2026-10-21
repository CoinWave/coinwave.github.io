import Foundation

enum Suit: Int, CaseIterable, Codable {
    case clubs = 0, diamonds, hearts, spades

    var symbol: String {
        switch self {
        case .clubs: return "♣"
        case .diamonds: return "♦"
        case .hearts: return "♥"
        case .spades: return "♠"
        }
    }

    var isRed: Bool { self == .diamonds || self == .hearts }
}

/// Ranks 2...14 (14 = Ace).
struct Rank: Comparable, Hashable, Codable {
    let value: Int

    static func < (lhs: Rank, rhs: Rank) -> Bool { lhs.value < rhs.value }

    var label: String {
        switch value {
        case 14: return "A"
        case 13: return "K"
        case 12: return "Q"
        case 11: return "J"
        case 10: return "10"
        default: return String(value)
        }
    }

    static let all: [Rank] = (2...14).map { Rank(value: $0) }
}

struct Card: Hashable, Codable, Identifiable {
    let rank: Rank
    let suit: Suit

    var id: Int { rank.value * 4 + suit.rawValue }
    var label: String { rank.label + suit.symbol }
}

struct Deck {
    private(set) var cards: [Card]

    init<G: RandomNumberGenerator>(using generator: inout G) {
        var all: [Card] = []
        for suit in Suit.allCases {
            for rank in Rank.all {
                all.append(Card(rank: rank, suit: suit))
            }
        }
        all.shuffle(using: &generator)
        cards = all
    }

    init() {
        var g = SystemRandomNumberGenerator()
        self.init(using: &g)
    }

    mutating func draw() -> Card {
        cards.removeLast()
    }

    mutating func draw(_ n: Int) -> [Card] {
        (0..<n).map { _ in draw() }
    }
}
