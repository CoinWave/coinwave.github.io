import SwiftUI

@main
struct UltimateHoldemApp: App {
    @StateObject private var player = PlayerStore()
    @StateObject private var jackpot = JackpotStore()
    @StateObject private var promos = PromoCodeService()
    @StateObject private var store = StoreManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(player)
                .environmentObject(jackpot)
                .environmentObject(promos)
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .task { store.attach(player: player, promos: promos) }
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var player: PlayerStore

    var body: some View {
        Group {
            if player.isSignedUp {
                LobbyView()
            } else {
                WelcomeView()
            }
        }
        .animation(.easeInOut, value: player.isSignedUp)
    }
}
