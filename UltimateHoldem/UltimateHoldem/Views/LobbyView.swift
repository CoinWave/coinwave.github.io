import SwiftUI

enum LobbySheet: String, Identifiable {
    case store, promo, wheel, tutorial, settings, stats
    var id: String { rawValue }
}

struct LobbyView: View {
    @EnvironmentObject private var player: PlayerStore
    @EnvironmentObject private var jackpot: JackpotStore
    @EnvironmentObject private var store: StoreManager
    @EnvironmentObject private var promos: PromoCodeService

    @State private var sheet: LobbySheet?
    @State private var openTable: TableTier?
    @State private var now = Date()
    @State private var didPromptWheel = false
    @State private var showRules = false
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            LobbyBackground()

            VStack(spacing: 12) {
                topBar
                HStack(alignment: .center, spacing: 18) {
                    leftMenu.frame(width: 250)
                    tableCarousel
                }
                bottomBar
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .onReceive(ticker) { now = $0 }
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .store: StoreView(focusPromo: false)
            case .promo: StoreView(focusPromo: true)
            case .wheel: DailyWheelView()
            case .tutorial: TutorialView()
            case .settings: SettingsView()
            case .stats: StatsView()
            }
        }
        .fullScreenCover(item: $openTable) { table in
            TableView(table: table, player: player, jackpot: jackpot)
                .environmentObject(player)
                .environmentObject(jackpot)
                .environmentObject(store)
                .environmentObject(promos)
        }
        .overlay { LevelUpOverlay() }
        .overlay {
            if showRules {
                RulesPopup(onClose: { showRules = false },
                           onFullRules: { showRules = false; sheet = .tutorial })
            }
        }
        .animation(.spring(duration: 0.3), value: showRules)
        .onAppear {
            // Pop the daily wheel once per launch when a free spin is ready.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { promptWheelIfReady() }
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack {
            BalancePill(chips: player.chips) { sheet = .store }
            Spacer()
            JackpotMeter(amount: jackpot.amount, compact: true)
            Spacer()
            HStack(spacing: 14) {
                Button { showRules = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "list.bullet.rectangle.portrait.fill")
                        Text("RULES & PAYOUTS")
                    }
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: "4A2A00"))
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(
                        Capsule().fill(LinearGradient(colors: [Color(hex: "FFE08A"), Theme.gold, Theme.goldDark],
                                                      startPoint: .top, endPoint: .bottom))
                            .overlay(Capsule().strokeBorder(.white.opacity(0.5), lineWidth: 1))
                            .shadow(color: Theme.gold.opacity(0.5), radius: 6)
                    )
                }
                .accessibilityLabel("Rules and payouts")
                CircleIconButton(systemName: "gearshape.fill", title: "SETTINGS") { sheet = .settings }
            }
        }
    }

    // MARK: Left menu

    private var leftMenu: some View {
        VStack(spacing: 14) {
            Button { sheet = .store } label: {
                HStack { Text("CHIP STORE"); Image(systemName: "cart.fill") }
            }
            .buttonStyle(GlossyButtonStyle(colors: [Color(hex: "3FD4E8"), Color(hex: "1A8FB5")]))

            Button { sheet = .wheel } label: {
                VStack(spacing: 0) {
                    HStack { Text("DAILY BONUS"); Image(systemName: "dial.medium.fill") }
                    if !player.canSpinWheel(now: now) {
                        Text("Next spin in \(countdown)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                    } else {
                        Text("Spin to win up to \(GameConfig.wheelSegments.map(\.amount).max()!.shortChipString)")
                            .font(.system(size: 11, weight: .bold))
                    }
                }
            }
            .buttonStyle(GlossyButtonStyle(colors: [Color(hex: "D158F0"), Color(hex: "8E1FB5")]))
            .overlay(alignment: .topTrailing) {
                if player.canSpinWheel(now: now) {
                    Text("READY").font(.system(size: 10, weight: .black))
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(Capsule().fill(Color.green))
                        .foregroundStyle(.white)
                        .offset(x: 6, y: -6)
                }
            }

            Button { sheet = .promo } label: {
                HStack { Text("PROMO CODE"); Image(systemName: "ticket.fill") }
            }
            .buttonStyle(GlossyButtonStyle(colors: [Color(hex: "8CE03A"), Color(hex: "3E9A16")]))
        }
    }

    /// Pops the daily wheel once per launch when a spin is ready.
    private func promptWheelIfReady() {
        guard !didPromptWheel, !showRules, sheet == nil, player.canSpinWheel() else { return }
        didPromptWheel = true
        sheet = .wheel
    }

    private var countdown: String {
        let remaining = max(0, Int(player.nextWheelSpin.timeIntervalSince(now)))
        return String(format: "%02d:%02d:%02d", remaining / 3600, (remaining % 3600) / 60, remaining % 60)
    }

    // MARK: Tables

    private var tableCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(GameConfig.tables) { table in
                    TableCard(table: table, unlocked: player.profile.level >= table.unlockLevel) {
                        if player.chips < table.minAnte * 2 {
                            sheet = .store
                        } else {
                            openTable = table
                        }
                    }
                }
            }
            .padding(.vertical, 6)
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
    }

    // MARK: Bottom bar

    private var bottomBar: some View {
        HStack(spacing: 14) {
            Button { sheet = .settings } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().stroke(.white.opacity(0.2), lineWidth: 5)
                        Circle().trim(from: 0, to: player.levelProgress)
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text(String(player.profile.name.prefix(1)).uppercased())
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 50, height: 50)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(player.profile.name)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                            Text("Level \(player.profile.level)")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.gold)
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 12).fill(.black.opacity(0.35)))
            }
            Spacer()
            bottomTile("chart.bar.fill", "STATS") { sheet = .stats }
            bottomTile("list.number", "PAYOUTS") { showRules = true }
            bottomTile("cart.fill", "GET CHIPS") { sheet = .store }
        }
    }

    private func bottomTile(_ icon: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 20))
                Text(title).font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(Color(hex: "5A1010"))
            .frame(width: 104, height: 54)
            .background(RoundedRectangle(cornerRadius: 10).fill(
                LinearGradient(colors: [.white, Color(hex: "C9C9C9")], startPoint: .top, endPoint: .bottom)))
        }
    }
}

// MARK: Table card in the carousel

struct TableCard: View {
    let table: TableTier
    let unlocked: Bool
    let onPlay: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            Text("MIN ANTE")
                .font(.system(size: 11, weight: .heavy)).tracking(1)
                .foregroundStyle(unlocked ? Color(hex: "7A4A10") : .gray)
            Text(table.minAnte.shortChipString)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(unlocked ? Color(hex: "8B5A12") : .gray)
            Text("Max \(table.maxAnte.shortChipString)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(unlocked ? Color(hex: "8B5A12").opacity(0.8) : .gray)

            if unlocked {
                HStack(spacing: -10) {
                    ChipView(value: table.minAnte, colorIndex: 0, size: 34)
                    ChipView(value: table.minAnte * 5, colorIndex: 1, size: 34)
                }
                .padding(.vertical, 2)
                Button("PLAY", action: onPlay)
                    .buttonStyle(GlossyButtonStyle(colors: [Color(hex: "F44336"), Color(hex: "B71C1C")], height: 44))
            } else {
                Image(systemName: "lock.fill").font(.system(size: 30)).foregroundStyle(.gray)
                Text("Unlocks @ Level \(table.unlockLevel)")
                    .font(.system(size: 12, weight: .semibold)).foregroundStyle(.gray)
                Text("LOCKED")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.6)))
            }
        }
        .padding(14)
        .frame(width: 180)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(unlocked
                      ? LinearGradient(colors: [Color(hex: "FFE7A8"), Color(hex: "F5D68A")], startPoint: .top, endPoint: .bottom)
                      : LinearGradient(colors: [Color(hex: "D6D6D6"), Color(hex: "A8A8A8")], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(unlocked ? Theme.goldDark : .gray, lineWidth: 3))
        )
        .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
    }
}

// MARK: Level-up celebration

struct LevelUpOverlay: View {
    @EnvironmentObject private var player: PlayerStore

    var body: some View {
        if let event = player.pendingLevelUp {
            ZStack {
                Color.black.opacity(0.6).ignoresSafeArea()
                VStack(spacing: 10) {
                    Image(systemName: "star.fill").font(.system(size: 50)).foregroundStyle(Theme.gold)
                    Text("LEVEL \(event.level)!")
                        .font(.system(size: 36, weight: .black, design: .rounded)).foregroundStyle(.white)
                    Text("+\(event.reward.chipString) bonus chips")
                        .font(.system(size: 18, weight: .bold)).foregroundStyle(Theme.gold)
                    if let unlocked = GameConfig.tables.first(where: { $0.unlockLevel == event.level }) {
                        Text("New table unlocked: \(unlocked.minAnte.shortChipString) min")
                            .font(.system(size: 14, weight: .semibold)).foregroundStyle(.white.opacity(0.85))
                    }
                    Button("COLLECT") { player.pendingLevelUp = nil }
                        .buttonStyle(GlossyButtonStyle(colors: [Color(hex: "7CD62E"), Color(hex: "2E8B12")], height: 46))
                        .frame(width: 200)
                }
                .padding(28)
                .background(RoundedRectangle(cornerRadius: 20).fill(Theme.lobbyTop)
                    .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.gold, lineWidth: 3)))
            }
            .transition(.opacity.combined(with: .scale))
        }
    }
}
