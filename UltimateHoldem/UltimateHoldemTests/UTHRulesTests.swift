import XCTest
@testable import UltimateHoldem

final class UTHRulesTests: XCTestCase {

    /// "Ah" "Ts" "2c" ... -> Card
    private func c(_ s: String) -> Card {
        let suitChar = s.last!
        let rankStr = String(s.dropLast())
        let rank: Int = ["A": 14, "K": 13, "Q": 12, "J": 11, "T": 10][rankStr] ?? Int(rankStr)!
        let suit: Suit = ["c": .clubs, "d": .diamonds, "h": .hearts, "s": .spades][suitChar]!
        return Card(rank: Rank(value: rank), suit: suit)
    }
    private func cards(_ s: String) -> [Card] { s.split(separator: " ").map { c(String($0)) } }

    func testCategories() {
        XCTAssertEqual(HandEvaluator.best(cards("Ah Kh Qh Jh Th 2c 3d")).category, .royalFlush)
        XCTAssertEqual(HandEvaluator.best(cards("9h Kh Qh Jh Th 2c 3d")).category, .straightFlush)
        XCTAssertEqual(HandEvaluator.best(cards("Ah 2h 3h 4h 5h 9c 9d")).category, .straightFlush)
        XCTAssertEqual(HandEvaluator.best(cards("9h 9c 9d 9s Th 2c 3d")).category, .fourOfAKind)
        XCTAssertEqual(HandEvaluator.best(cards("9h 9c 9d Ts Th 2c 3d")).category, .fullHouse)
        XCTAssertEqual(HandEvaluator.best(cards("2h 7h 9h Jh Kh 2c 3d")).category, .flush)
        XCTAssertEqual(HandEvaluator.best(cards("Ah 2c 3d 4s 5h Kc Kd")).category, .straight)
        XCTAssertEqual(HandEvaluator.best(cards("9h 9c 9d 2s Th 4c 6d")).category, .threeOfAKind)
        XCTAssertEqual(HandEvaluator.best(cards("9h 9c Td 2s Th 4c 6d")).category, .twoPair)
        XCTAssertEqual(HandEvaluator.best(cards("9h 9c Kd 2s Th 4c 6d")).category, .onePair)
        XCTAssertEqual(HandEvaluator.best(cards("9h 8c Kd 2s Th 4c 6d")).category, .highCard)
    }

    func testWheelLosesToSixHighStraight() {
        let wheel = HandEvaluator.best(cards("Ah 2c 3d 4s 5h"))
        let six = HandEvaluator.best(cards("6h 2c 3d 4s 5h"))
        XCTAssertLessThan(wheel, six)
    }

    func testKickers() {
        let a = HandEvaluator.best(cards("Ah Ac Kd 7s 4h 3c 2d"))
        let b = HandEvaluator.best(cards("Ah Ac Qd 7s 4h 3c 2d"))
        XCTAssertGreaterThan(a, b)
    }

    func testPlayerWinsDealerQualifiesBlindStraight() {
        let bets = Bets(ante: 100, blind: 100, play: 400, trips: 0, progressive: 0)
        let s = UTHRules.settle(playerHole: cards("9c Tc"),
                                dealerHole: cards("Kd Kh"),
                                board: cards("Jd Qs 8h 2c 3s"),
                                bets: bets, folded: false, jackpot: 1_000_000)
        XCTAssertEqual(s.outcome, .win)
        XCTAssertTrue(s.dealerQualifies)
        XCTAssertEqual(s.results.first { $0.name == "Play" }?.net, 400)
        XCTAssertEqual(s.results.first { $0.name == "Ante" }?.net, 100)
        XCTAssertEqual(s.results.first { $0.name == "Blind" }?.net, 100)   // straight 1:1
    }

    func testAntePushesWhenDealerDoesNotQualify() {
        let bets = Bets(ante: 100, blind: 100, play: 100)
        let s = UTHRules.settle(playerHole: cards("Ac Kc"),
                                dealerHole: cards("4d 7h"),
                                board: cards("Jd 9s 8h 2c 3s"),
                                bets: bets, folded: false, jackpot: 0)
        XCTAssertEqual(s.outcome, .win)
        XCTAssertFalse(s.dealerQualifies)
        XCTAssertEqual(s.results.first { $0.name == "Ante" }?.net, 0)
        XCTAssertEqual(s.results.first { $0.name == "Blind" }?.net, 0)
        XCTAssertEqual(s.netWin, 100)
    }

    func testFoldLosesAnteAndBlindButTripsPays() {
        let bets = Bets(ante: 100, blind: 100, play: 0, trips: 50)
        let s = UTHRules.settle(playerHole: cards("2c 7d"),
                                dealerHole: cards("Ad Ah"),
                                board: cards("Qs Qh Qd 4c 9s"),
                                bets: bets, folded: true, jackpot: 0)
        XCTAssertEqual(s.outcome, .fold)
        XCTAssertEqual(s.results.first { $0.name == "Trips" }?.net, 150)  // trips 3:1
        XCTAssertEqual(s.netWin, -200 + 150)
    }

    func testProgressiveRoyalPaysWholeJackpot() {
        let bets = Bets(ante: 100, blind: 100, play: 400, progressive: 100)
        let s = UTHRules.settle(playerHole: cards("Ah Kh"),
                                dealerHole: cards("2d 3c"),
                                board: cards("Qh Jh Th 4c 9s"),
                                bets: bets, folded: false, jackpot: 5_000_000)
        XCTAssertEqual(s.jackpotPaid, 5_000_000)
        XCTAssertEqual(s.results.first { $0.name == "Blind" }?.net, 50_000)  // 500:1
    }

    func testTieIsPush() {
        let bets = Bets(ante: 100, blind: 100, play: 100)
        let s = UTHRules.settle(playerHole: cards("2c 3d"),
                                dealerHole: cards("2h 3s"),
                                board: cards("Ah Ks Qd Jc 9s"),
                                bets: bets, folded: false, jackpot: 0)
        XCTAssertEqual(s.outcome, .push)
        XCTAssertEqual(s.netWin, 0)
    }

    func testWheelLandsOnChosenSegment() {
        let n = GameConfig.wheelSegments.count
        for index in 0..<n {
            let r = WheelSpinner.targetRotation(for: index, segmentCount: n, currentRotation: 123)
            let slice = 360.0 / Double(n)
            // Angle (clockwise from top) that ends up under the pointer.
            let under = (360 - r.truncatingRemainder(dividingBy: 360)).truncatingRemainder(dividingBy: 360)
            XCTAssertEqual(Int(under / slice), index)
        }
    }
}

final class ChipPackTests: XCTestCase {
    func testBiggerPacksAreAlwaysBetterValue() {
        let prices = [0.99, 4.99, 9.99, 19.99, 29.99, 49.99]
        let perDollar = zip(GameConfig.chipPacks, prices).map { Double($0.totalChips) / $1 }
        XCTAssertEqual(GameConfig.chipPacks.map(\.totalChips),
                       [2_000_000, 12_000_000, 30_000_000, 70_000_000, 120_000_000, 250_000_000])
        for i in 1..<perDollar.count { XCTAssertGreaterThan(perDollar[i], perDollar[i - 1]) }
    }
}
