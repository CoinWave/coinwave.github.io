import SwiftUI

/// "Rules & Payouts" popup: the four steps of a hand plus every paytable, on one screen.
/// Shown from the lobby's RULES & PAYOUTS button, the lobby's PAYOUTS tile, and the table's ⓘ button.
struct RulesPopup: View {
    let onClose: () -> Void
    /// Opens the full written rules (TutorialView).
    let onFullRules: () -> Void

    @EnvironmentObject private var jackpot: JackpotStore

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            VStack(spacing: 10) {
                header
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 10) {
                        steps
                        HStack(alignment: .top, spacing: 8) {
                            PayCard(title: "MAIN BETS", rows: Self.mainRows,
                                    footnote: "* Ante pushes if the dealer has less than a pair")
                            PayCard(title: "BLIND", rows: Self.blindRows,
                                    footnote: "Pays only when you win")
                            PayCard(title: "TRIPS", rows: Self.tripsRows,
                                    footnote: "Pays on your hand, win or lose")
                            PayCard(title: "PROGRESSIVE", rows: Self.progressiveRows,
                                    footnote: "Your 2 cards + the flop",
                                    banner: jackpot.amount.chipString)
                        }
                    }
                }
                footer
            }
            .padding(14)
            .frame(maxWidth: 760)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(colors: [Theme.lobbyTop, Theme.lobbyBottom], startPoint: .top, endPoint: .bottom))
                    .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.gold, lineWidth: 3))
                    .shadow(color: .black.opacity(0.5), radius: 20)
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    // MARK: Pieces

    private var header: some View {
        ZStack {
            Text("RULES & PAYOUTS")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(Theme.gold)
                .tracking(1)
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(.black.opacity(0.4)))
                        .overlay(Circle().strokeBorder(.white.opacity(0.3)))
                }
                .accessibilityLabel("Close")
            }
        }
    }

    private var steps: some View {
        HStack(spacing: 6) {
            step(1, "BET", "Ante = Blind\nTrips & Jackpot optional")
            step(2, "PRE-FLOP", "Check, or\nPlay 3x or 4x Ante")
            step(3, "FLOP", "Check, or\nPlay 2x Ante")
            step(4, "RIVER", "Play 1x Ante\nor Fold")
        }
    }

    private func step(_ n: Int, _ title: String, _ detail: String) -> some View {
        HStack(spacing: 8) {
            Text("\(n)")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Theme.accentRed))
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 11, weight: .black)).foregroundStyle(Theme.gold)
                Text(detail).font(.system(size: 10, weight: .semibold)).foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 10).fill(.black.opacity(0.3)))
    }

    private var footer: some View {
        HStack {
            Text("You make one Play bet per hand. Best 5 cards from your 2 + the 5 on the board wins.")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(2)
            Spacer()
            Button(action: onFullRules) {
                Text("FULL RULES")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(Color(hex: "4A2A00"))
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Capsule().fill(Theme.gold))
            }
        }
    }

    // MARK: Paytable rows (straight from Paytables.swift, so they always match the game)

    static var mainRows: [(String, String)] {
        [("Play", "1 to 1"), ("Ante", "1 to 1*"), ("Blind", "See Blind"), ("Tie", "Push"), ("Fold", "Lose Ante & Blind")]
    }

    static var blindRows: [(String, String)] {
        var rows: [(String, String)] = Paytables.blind.map { entry in (entry.0.name, Paytables.describe(entry.1)) }
        rows.append(("All other wins", "Push"))
        return rows
    }

    static var tripsRows: [(String, String)] {
        Paytables.trips.map { entry in (entry.0.name, Paytables.describe(entry.1)) }
    }

    static var progressiveRows: [(String, String)] {
        Paytables.progressive.map { entry -> (String, String) in
            switch entry.1 {
            case .percentOfJackpot(let p): return (entry.0.name, p >= 1 ? "100% Jackpot" : "\(Int(p * 100))% Jackpot")
            case .multiple(let m): return (entry.0.name, "\(Int(m)) to 1")
            }
        }
    }
}

/// One paytable printed like the casino felt: red title, rows of hand → payout.
private struct PayCard: View {
    let title: String
    let rows: [(String, String)]
    var footnote: String? = nil
    var banner: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 12, weight: .black, design: .serif))
                .foregroundStyle(Theme.accentRed)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 5).fill(.white))
            if let banner {
                Text(banner)
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(Color(hex: "FF5252"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 5).fill(.black.opacity(0.7)))
                    .lineLimit(1).minimumScaleFactor(0.6)
            }
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 4) {
                    Text(row.0)
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1).minimumScaleFactor(0.75)
                    Spacer(minLength: 2)
                    Text(row.1)
                        .font(.system(size: 10.5, weight: .heavy).monospacedDigit())
                        .foregroundStyle(Theme.gold)
                        .lineLimit(1).minimumScaleFactor(0.75)
                }
            }
            if let footnote {
                Text(footnote)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(colors: [Theme.felt, Theme.feltDark], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.white.opacity(0.15)))
        )
        .accessibilityElement(children: .combine)
    }
}
