import SwiftUI

struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    section("How to play") {
                        step(1, "Place equal Ante and Blind bets (the Blind matches your Ante automatically). Trips and the Progressive Jackpot are optional side bets.")
                        step(2, "You and the dealer each get two cards. Check, or bet 3x or 4x your Ante on the Play spot.")
                        step(3, "After the 3-card flop, if you checked: check again or bet 2x your Ante.")
                        step(4, "After the turn and river, if you still haven't bet: bet 1x your Ante or fold.")
                        step(5, "You can only make one Play bet per hand. Best five cards from your two cards plus the five community cards wins.")
                    }

                    section("Payouts") {
                        bullet("Play: pays 1 to 1 when you beat the dealer.")
                        bullet("Ante: pays 1 to 1 when you win, but pushes if the dealer doesn't have at least a pair.")
                        bullet("Blind: pays per the table below only if you win with a straight or better; otherwise a winning Blind pushes.")
                        bullet("Ties push all main bets. If you fold, you lose Ante and Blind.")
                    }

                    HStack(alignment: .top, spacing: 16) {
                        paytable("BLIND", Self.blindRows)
                        paytable("TRIPS", Self.tripsRows)
                        paytable("PROGRESSIVE", Self.progressiveRows)
                    }

                    section("Side bets") {
                        bullet("Trips pays on your final hand no matter what the dealer has.")
                        bullet("The Progressive Jackpot is a fixed bet equal to the table minimum. It pays on your two cards plus the flop. A Royal Flush wins the whole jackpot; a Straight Flush wins 10%.")
                    }

                    Text("For entertainment only. Chips have no cash value. Practice or success at social casino gaming does not imply future success at real-money gambling.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Rules & Paytables")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private static var blindRows: [(String, String)] {
        var rows: [(String, String)] = Paytables.blind.map { entry in (entry.0.name, Paytables.describe(entry.1)) }
        rows.append(("All other", "Push"))
        return rows
    }

    private static var tripsRows: [(String, String)] {
        Paytables.trips.map { entry in (entry.0.name, Paytables.describe(entry.1)) }
    }

    private static var progressiveRows: [(String, String)] {
        Paytables.progressive.map { entry -> (String, String) in
            switch entry.1 {
            case .percentOfJackpot(let p): return (entry.0.name, p >= 1 ? "100% Jackpot" : "\(Int(p * 100))% Jackpot")
            case .multiple(let m): return (entry.0.name, "\(Int(m)) to 1")
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.title3.bold()).foregroundStyle(Theme.gold)
            content()
        }
    }

    private func step(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(n)").font(.headline).frame(width: 26, height: 26).background(Circle().fill(Theme.accentRed))
            Text(text)
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) { Text("•"); Text(text) }
    }

    private func paytable(_ title: String, _ rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline).foregroundStyle(Theme.accentRed)
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack {
                    Text(row.0).font(.caption)
                    Spacer()
                    Text(row.1).font(.caption.bold().monospacedDigit())
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.felt))
    }
}
