import SwiftUI

struct TableView: View {
    @EnvironmentObject private var player: PlayerStore
    @EnvironmentObject private var jackpot: JackpotStore
    @Environment(\.dismiss) private var dismiss

    @StateObject private var game: TableGame
    @State private var showStore = false
    @State private var showPaytables = false
    @State private var showRules = false

    init(table: TableTier, player: PlayerStore, jackpot: JackpotStore) {
        _game = StateObject(wrappedValue: TableGame(table: table, player: player, jackpot: jackpot))
    }

    var body: some View {
        GeometryReader { geo in
            let cardW = min(54, max(36, geo.size.height * 0.115))
            ZStack {
                FeltBackground()

                VStack(spacing: 4) {
                    topBar
                    HStack(alignment: .center, spacing: 8) {
                        betPanel.frame(width: 170)
                        centerCards(cardW: cardW).frame(maxWidth: .infinity)
                        actionPanel.frame(width: 180)
                    }
                    .frame(maxHeight: .infinity)
                    bottomTray
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)

                if let paid = jackpotWinBanner {
                    JackpotWinBanner(amount: paid)
                }
            }
        }
        .sheet(isPresented: $showStore) { StoreView(focusPromo: false) }
        .sheet(isPresented: $showPaytables) { TutorialView() }
        .overlay { LevelUpOverlay() }
        .overlay {
            if showRules {
                RulesPopup(onClose: { showRules = false },
                           onFullRules: { showRules = false; showPaytables = true })
            }
        }
        .animation(.spring(duration: 0.3), value: showRules)
    }

    private var jackpotWinBanner: Int? {
        guard game.phase == .showdown, let s = game.settlement, s.jackpotPaid > 0 else { return nil }
        return s.jackpotPaid
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(.black.opacity(0.35)))
            }
            .foregroundStyle(.white)
            .disabled(game.phase != .betting && game.phase != .showdown)
            .opacity(game.phase == .betting || game.phase == .showdown ? 1 : 0.3)

            BalancePill(chips: player.chips) { showStore = true }
            Spacer()
            JackpotMeter(amount: jackpot.amount, compact: true)
            Spacer()
            Text("ANTE \(game.table.minAnte.shortChipString)–\(game.table.maxAnte.shortChipString)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.7))
            Button { showRules = true } label: {
                Image(systemName: "info.circle.fill").font(.system(size: 26))
            }
            .accessibilityLabel("Rules and payouts")
            .foregroundStyle(.white.opacity(0.85))
        }
    }

    // MARK: Left: bet spots

    private func result(_ name: String) -> BetResult? {
        game.settlement?.results.first { $0.name == name }
    }

    private var betPanel: some View {
        let betting = game.phase == .betting
        let anteAmount = betting ? game.pendingAnte : game.bets.ante
        let tripsAmount = betting ? game.pendingTrips : game.bets.trips
        let progOn = betting ? game.progressiveOn : game.bets.progressive > 0

        return VStack(spacing: 10) {
            HStack(spacing: 12) {
                Button { game.addChip(to: .trips) } label: {
                    BetSpotView(label: "Trips", amount: tripsAmount, diamond: true, result: result("Trips"), size: 54)
                }
                .buttonStyle(.plain)
                .disabled(!betting)

                Button { game.toggleProgressive() } label: {
                    ProgressiveSpot(on: progOn, amount: game.table.progressiveBet, result: result("Progressive"))
                }
                .buttonStyle(.plain)
                .disabled(!betting)
            }

            HStack(spacing: 6) {
                Button { game.addChip(to: .ante) } label: {
                    BetSpotView(label: "Ante", amount: anteAmount, result: result("Ante"), size: 58)
                }
                .buttonStyle(.plain)
                .disabled(!betting)
                Text("=").font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                BetSpotView(label: "Blind", amount: anteAmount, result: result("Blind"), size: 58)
            }

            BetSpotView(label: "Play", amount: game.bets.play, active: game.bets.play > 0 || !betting,
                        result: result("Play"), size: 58)
        }
    }

    // MARK: Center: cards

    private func centerCards(cardW: CGFloat) -> some View {
        let winning = Set(game.settlement?.playerHand.cards.map(\.id) ?? [])
        let showdown = game.phase == .showdown
        let playerWon = game.settlement?.outcome == .win

        return VStack(spacing: 6) {
            // Dealer
            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    ForEach(0..<2, id: \.self) { i in
                        CardView(card: game.dealerHole[safe: i], faceUp: game.dealerRevealed, width: cardW)
                    }
                }
                Text(dealerLabel)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(height: 14)
            }

            // Board
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { i in
                    let card = game.board[safe: i]
                    CardView(card: card,
                             faceUp: i < game.boardRevealed,
                             highlighted: showdown && playerWon && card.map { winning.contains($0.id) } == true,
                             dimmed: showdown && playerWon && card.map { !winning.contains($0.id) } == true,
                             width: cardW)
                }
            }

            Text("Ante pushes if dealer has less than a pair")
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .foregroundStyle(.white.opacity(0.8))

            // Player
            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    ForEach(0..<2, id: \.self) { i in
                        let card = game.playerHole[safe: i]
                        CardView(card: card, faceUp: true,
                                 highlighted: showdown && playerWon && card.map { winning.contains($0.id) } == true,
                                 width: cardW)
                    }
                }
                Text(playerLabel)
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(Theme.gold)
                    .frame(height: 15)
            }
        }
    }

    private var playerLabel: String {
        guard game.playerHole.count == 2 else { return "" }
        let visible = game.playerHole + game.board.prefix(game.boardRevealed)
        if visible.count >= 5 { return HandEvaluator.best(visible).category.name }
        return game.playerHole[0].rank == game.playerHole[1].rank ? "Pair" : "High Card"
    }

    private var dealerLabel: String {
        guard game.dealerRevealed, let s = game.settlement else { return "DEALER" }
        return "Dealer: \(s.dealerHand.category.name)" + (s.dealerQualifies ? "" : " – does not qualify")
    }

    // MARK: Right: actions

    private var actionPanel: some View {
        VStack(spacing: 8) {
            Text(game.message)
                .font(.system(size: 13, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .frame(minHeight: 34)
                .animation(.default, value: game.message)

            switch game.phase {
            case .betting:
                Button("DEAL") { Task { await game.deal() } }
                    .buttonStyle(ActionButtonStyle())
                    .disabled(!game.canDeal)
                HStack(spacing: 8) {
                    Button("REBET") { game.rebet() }
                        .buttonStyle(ActionButtonStyle(color: Color(hex: "455A64"), textColor: .white))
                        .disabled(!game.canRebet)
                    Button("CLEAR") { game.clearBets() }
                        .buttonStyle(ActionButtonStyle(color: Color(hex: "455A64"), textColor: .white))
                }
                if game.pendingAnte > 0 {
                    Text("Total bet: \(game.pendingCost.chipString)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.75))
                }
            case .preflop, .flop, .river:
                ForEach(game.playOptions, id: \.self) { m in
                    Button("PLAY \(m)X  \((game.bets.ante * m).shortChipString)") { Task { await game.play(m) } }
                        .buttonStyle(ActionButtonStyle(color: Color(hex: "43A047"), textColor: .white))
                        .disabled(game.isBusy || !game.canAffordPlay(m))
                }
                if game.canCheck {
                    Button("CHECK") { Task { await game.check() } }
                        .buttonStyle(ActionButtonStyle())
                        .disabled(game.isBusy)
                }
                if game.canFold {
                    Button("FOLD") { Task { await game.fold() } }
                        .buttonStyle(ActionButtonStyle(color: Color(hex: "C62828"), textColor: .white))
                        .disabled(game.isBusy)
                }
                if let m = game.playOptions.first, !game.canAffordPlay(m) {
                    Button("GET CHIPS") { showStore = true }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.gold)
                }
            case .showdown:
                if let s = game.settlement { ResultsCard(settlement: s) }
                Button("NEW HAND") { game.nextHand() }
                    .buttonStyle(ActionButtonStyle())
            }
        }
    }

    // MARK: Bottom: chip tray

    @ViewBuilder
    private var bottomTray: some View {
        if game.phase == .betting {
            HStack(spacing: 14) {
                Text("Tap a chip, then tap Ante or Trips")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                ForEach(Array(game.chipValues.enumerated()), id: \.element) { idx, value in
                    Button { game.selectedChip = value; Haptics.tap(player.hapticsOn) } label: {
                        ChipView(value: value, colorIndex: idx, size: 42, selected: game.selectedChip == value)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 48)
        } else {
            Color.clear.frame(height: 48)
        }
    }
}

// MARK: Pieces

private struct ProgressiveSpot: View {
    let on: Bool
    let amount: Int
    let result: BetResult?

    var body: some View {
        VStack(spacing: 2) {
            Circle()
                .fill(on ? Color(hex: "FF1744") : Color(hex: "7F1D1D"))
                .overlay(Circle().strokeBorder(.white.opacity(0.6), lineWidth: 2))
                .shadow(color: on ? .red : .clear, radius: 10)
                .frame(width: 34, height: 34)
            Text("JACKPOT").font(.system(size: 9, weight: .heavy)).foregroundStyle(.white)
            Text(amount.shortChipString).font(.system(size: 9, weight: .bold)).foregroundStyle(.white.opacity(0.7))
        }
        .overlay(alignment: .top) {
            if let result, result.net > 0 {
                Text("+\(result.net.shortChipString)")
                    .font(.system(size: 10, weight: .heavy))
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(Capsule().fill(Color.green))
                    .foregroundStyle(.white)
                    .offset(y: -12)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: on)
    }
}

private struct ResultsCard: View {
    let settlement: Settlement

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(settlement.results) { r in
                HStack {
                    Text(r.name).font(.system(size: 11, weight: .bold))
                    Spacer()
                    Text(r.net > 0 ? "+\(r.net.shortChipString)" : r.net == 0 ? "Push" : "-\(r.stake.shortChipString)")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundStyle(r.net > 0 ? .green : r.net == 0 ? .white : Color(hex: "FF8A80"))
                }
            }
            Divider().overlay(.white.opacity(0.3))
            HStack {
                Text("NET").font(.system(size: 12, weight: .black))
                Spacer()
                Text((settlement.netWin >= 0 ? "+" : "-") + abs(settlement.netWin).shortChipString)
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(settlement.netWin > 0 ? .green : settlement.netWin == 0 ? .white : Color(hex: "FF8A80"))
            }
        }
        .foregroundStyle(.white)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(.black.opacity(0.45)))
    }
}

private struct JackpotWinBanner: View {
    let amount: Int
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 4) {
            Text("JACKPOT!")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(Theme.gold)
            Text("+\(amount.chipString)")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 18).fill(.black.opacity(0.8))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.gold, lineWidth: 3)))
        .scaleEffect(pulse ? 1.05 : 0.95)
        .onAppear { withAnimation(.easeInOut(duration: 0.6).repeatForever()) { pulse = true } }
        .allowsHitTesting(false)
    }
}

struct FeltBackground: View {
    var body: some View {
        ZStack {
            Color(hex: "2A1A10").ignoresSafeArea()   // rail
            RadialGradient(colors: [Theme.felt, Theme.feltDark], center: .center, startRadius: 40, endRadius: 600)
                .clipShape(RoundedRectangle(cornerRadius: 40))
                .padding(4)
                .ignoresSafeArea(edges: .horizontal)
            Text("ULTIMATE POKER · HOLD'EM CASINO")
                .font(.system(size: 13, weight: .heavy, design: .serif))
                .tracking(4)
                .foregroundStyle(.white.opacity(0.12))
                .offset(y: 120)
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
