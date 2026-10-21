import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var player: PlayerStore
    @EnvironmentObject private var store: StoreManager
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Player") {
                    HStack {
                        TextField("Player name", text: $name)
                            .onSubmit { player.rename(name) }
                        Button("Save") { player.rename(name) }
                            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || name == player.profile.name)
                    }
                    LabeledContent("Level", value: "\(player.profile.level)")
                    LabeledContent("Chips", value: player.chips.chipString)
                }
                Section("Game") {
                    Toggle("Haptics", isOn: Binding(get: { player.hapticsOn }, set: { player.hapticsOn = $0 }))
                    Toggle("Fast deal", isOn: Binding(get: { player.fastDeal }, set: { player.fastDeal = $0 }))
                }
                Section("Purchases") {
                    Button("Restore Purchases") { Task { await store.restore() } }
                }
                #if DEBUG
                // Only exists in builds run from Xcode (Debug). Compiled out of TestFlight and App Store builds.
                Section("Tester tools (Xcode builds only)") {
                    Button("+ 10,000,000 chips") { player.credit(10_000_000) }
                    Button("+ 100,000,000 chips") { player.credit(100_000_000) }
                    Button("Reset daily wheel") { player.debugResetWheel() }
                    Button("Unlock all tables (level 75)") { player.debugSetLevel(75) }
                }
                #endif
                Section("About") {
                    Link("Privacy Policy", destination: GameConfig.privacyPolicyURL)
                    Link("Support", destination: GameConfig.termsURL)
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    Text("This game is intended for an adult audience (17+) for amusement purposes only. It does not offer real-money gambling or an opportunity to win real money or prizes.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .onAppear { name = player.profile.name }
        }
    }
}

struct StatsView: View {
    @EnvironmentObject private var player: PlayerStore
    @EnvironmentObject private var jackpot: JackpotStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                LabeledContent("Hands played", value: player.profile.handsPlayed.formatted())
                LabeledContent("Biggest win", value: player.profile.biggestWin.chipString)
                LabeledContent("Level", value: "\(player.profile.level)")
                LabeledContent("XP to next level",
                               value: (GameConfig.xpRequired(forLevel: player.profile.level) - player.profile.xp).formatted())
                LabeledContent("Current jackpot", value: jackpot.amount.chipString)
                if let since = player.profile.createdAt {
                    LabeledContent("Playing since", value: since.formatted(date: .abbreviated, time: .omitted))
                }
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
