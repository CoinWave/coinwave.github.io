import SwiftUI

// MARK: Playing card

struct CardView: View {
    let card: Card?
    var faceUp: Bool = true
    var highlighted: Bool = false
    var dimmed: Bool = false
    var width: CGFloat = 50

    private var height: CGFloat { width * 1.4 }

    var body: some View {
        ZStack {
            if let card, faceUp {
                RoundedRectangle(cornerRadius: width * 0.12)
                    .fill(.white)
                VStack(spacing: 0) {
                    HStack {
                        VStack(spacing: -2) {
                            Text(card.rank.label).font(.system(size: width * 0.30, weight: .bold, design: .rounded))
                            Text(card.suit.symbol).font(.system(size: width * 0.24))
                        }
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        Text(card.suit.symbol).font(.system(size: width * 0.48))
                    }
                }
                .padding(width * 0.08)
                .foregroundStyle(card.suit.isRed ? Color(hex: "D32F2F") : .black)
            } else if card != nil {
                RoundedRectangle(cornerRadius: width * 0.12)
                    .fill(LinearGradient(colors: [Color(hex: "B71C1C"), Color(hex: "7F0000")],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                RoundedRectangle(cornerRadius: width * 0.08)
                    .strokeBorder(Color.white.opacity(0.7), lineWidth: 1.5)
                    .padding(width * 0.08)
                Text("♠").font(.system(size: width * 0.4)).foregroundStyle(.white.opacity(0.5))
            } else {
                RoundedRectangle(cornerRadius: width * 0.12)
                    .strokeBorder(Theme.accentRed.opacity(0.9), lineWidth: 2)
            }
        }
        .frame(width: width, height: height)
        .overlay(
            RoundedRectangle(cornerRadius: width * 0.12)
                .strokeBorder(Theme.gold, lineWidth: highlighted ? 3 : 0)
        )
        .shadow(color: .black.opacity(card == nil ? 0 : 0.35), radius: 2, y: 2)
        .opacity(dimmed ? 0.45 : 1)
        .offset(y: highlighted ? -6 : 0)
        .rotation3DEffect(.degrees(faceUp || card == nil ? 0 : 180), axis: (x: 0, y: 1, z: 0))
        .animation(.spring(duration: 0.35), value: faceUp)
        .animation(.spring(duration: 0.35), value: highlighted)
        .accessibilityLabel(card.map { faceUp ? $0.label : "Face-down card" } ?? "Empty")
    }
}

// MARK: Casino chip

struct ChipView: View {
    let value: Int
    var colorIndex: Int = 0
    var size: CGFloat = 44
    var selected: Bool = false

    static let colors: [Color] = [Color(hex: "D32F2F"), Color(hex: "1565C0"), Color(hex: "2E7D32"), Color(hex: "212121"), Color(hex: "6A1B9A")]

    var body: some View {
        let color = Self.colors[colorIndex % Self.colors.count]
        ZStack {
            Circle().fill(color)
            Circle()
                .strokeBorder(style: StrokeStyle(lineWidth: size * 0.1, dash: [size * 0.12, size * 0.12]))
                .foregroundStyle(.white)
            Circle().fill(color).padding(size * 0.18)
            Circle().strokeBorder(.white.opacity(0.6), lineWidth: 1).padding(size * 0.18)
            Text(value.shortChipString.replacingOccurrences(of: "$", with: ""))
                .font(.system(size: size * 0.26, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .padding(size * 0.2)
        }
        .frame(width: size, height: size)
        .shadow(color: selected ? Theme.gold : .black.opacity(0.4), radius: selected ? 6 : 2, y: selected ? 0 : 2)
        .scaleEffect(selected ? 1.12 : 1)
        .animation(.spring(duration: 0.2), value: selected)
    }
}

// MARK: Bet spot on the felt

struct BetSpotView: View {
    let label: String
    let amount: Int
    var diamond: Bool = false
    var active: Bool = true
    var result: BetResult? = nil
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            Group {
                if diamond {
                    Rectangle()
                        .strokeBorder(Theme.accentRed, lineWidth: 2.5)
                        .background(Rectangle().fill(.white.opacity(0.06)))
                        .rotationEffect(.degrees(45))
                        .padding(size * 0.12)
                } else {
                    Circle()
                        .strokeBorder(Theme.feltLine, lineWidth: 2)
                        .background(Circle().fill(.white.opacity(0.06)))
                }
            }
            if amount > 0 {
                ChipView(value: amount, colorIndex: label.count, size: size * 0.7)
            } else {
                Text(label)
                    .font(.system(size: size * 0.22, weight: .bold, design: .serif))
                    .foregroundStyle(Theme.accentRed)
            }
        }
        .frame(width: size, height: size)
        .opacity(active ? 1 : 0.6)
        .overlay(alignment: .bottom) {
            if let result {
                Text(result.net > 0 ? "+\(result.net.shortChipString)" : result.net == 0 ? "PUSH" : "LOSE")
                    .font(.system(size: 10, weight: .heavy))
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(Capsule().fill(result.net > 0 ? Color.green : result.net == 0 ? Color.gray : Color.black.opacity(0.7)))
                    .foregroundStyle(.white)
                    .offset(y: 10)
                    .transition(.scale)
            }
        }
    }
}

// MARK: Lobby-style glossy button

struct GlossyButtonStyle: ButtonStyle {
    let colors: [Color]
    var height: CGFloat = 56

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: height * 0.38, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(colors: [.white.opacity(0.35), .clear], startPoint: .top, endPoint: .center))
                    )
                    .shadow(color: colors.first!.opacity(0.6), radius: configuration.isPressed ? 2 : 8)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}

struct ActionButtonStyle: ButtonStyle {
    var color: Color = Theme.gold
    var textColor: Color = Color(hex: "4A2A00")
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .heavy, design: .rounded))
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(colors: [color, color.opacity(0.75)], startPoint: .top, endPoint: .bottom))
            )
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

// MARK: Balance pill

struct BalancePill: View {
    let chips: Int
    var onPlus: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 10) {
            Text(chips.chipString)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.gold)
                .contentTransition(.numericText())
                .animation(.default, value: chips)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if let onPlus {
                Button(action: onPlus) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color(hex: "4A2A00"), Theme.gold)
                }
                .accessibilityLabel("Buy chips")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(.black.opacity(0.45)))
    }
}

// MARK: Jackpot meter

struct JackpotMeter: View {
    let amount: Int
    var compact = false

    var body: some View {
        VStack(spacing: 0) {
            Text("PROGRESSIVE JACKPOT")
                .font(.system(size: compact ? 9 : 11, weight: .heavy))
                .foregroundStyle(.white.opacity(0.85))
                .tracking(1)
            Text(amount.chipString)
                .font(.system(size: compact ? 17 : 24, weight: .black, design: .monospaced))
                .foregroundStyle(Color(hex: "FF5252"))
                .shadow(color: .red.opacity(0.8), radius: 6)
                .contentTransition(.numericText())
                .animation(.default, value: amount)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, compact ? 4 : 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.black.opacity(0.75))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.gold.opacity(0.8), lineWidth: 1.5))
        )
    }
}

// MARK: Circle icon button (lobby top bar)

struct CircleIconButton: View {
    let systemName: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: systemName)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(.black.opacity(0.3)))
                    .overlay(Circle().strokeBorder(.white.opacity(0.25)))
                Text(title).font(.system(size: 11, weight: .bold)).tracking(0.5)
            }
            .foregroundStyle(.white)
        }
    }
}

// MARK: Suit-pattern background

struct LobbyBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.lobbyTop, Theme.lobbyBottom], startPoint: .top, endPoint: .bottom)
            GeometryReader { geo in
                let symbols = ["suit.spade.fill", "suit.heart.fill", "suit.diamond.fill", "suit.club.fill"]
                ForEach(0..<28, id: \.self) { i in
                    Image(systemName: symbols[i % 4])
                        .font(.system(size: CGFloat(30 + (i * 17) % 50)))
                        .foregroundStyle(.white.opacity(0.05))
                        .position(x: geo.size.width * CGFloat((i * 37) % 100) / 100,
                                  y: geo.size.height * CGFloat((i * 61) % 100) / 100)
                }
            }
        }
        .ignoresSafeArea()
    }
}
