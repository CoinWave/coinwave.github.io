import SwiftUI

/// First launch: pick a player name and collect the free sign-up chips.
struct WelcomeView: View {
    @EnvironmentObject private var player: PlayerStore
    @State private var name = ""
    @FocusState private var nameFocused: Bool

    var body: some View {
        ZStack {
            LobbyBackground()
            HStack(spacing: 40) {
                VStack(spacing: 8) {
                    HStack(spacing: -14) {
                        ForEach(0..<3, id: \.self) { i in
                            ChipView(value: [1_000, 5_000, 25_000][i], colorIndex: i, size: 64)
                        }
                    }
                    Text("ULTIMATE POKER")
                        .font(.system(size: 38, weight: .black, design: .serif))
                        .foregroundStyle(Theme.gold)
                    Text("HOLD'EM CASINO")
                        .font(.system(size: 22, weight: .heavy, design: .serif))
                        .foregroundStyle(.white)
                        .tracking(3)
                    Text("Progressive Jackpot")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }

                VStack(spacing: 14) {
                    Text("WELCOME BONUS")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.85))
                        .tracking(2)
                    Text(GameConfig.welcomeBonus.chipString)
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.gold)
                        .shadow(color: Theme.gold.opacity(0.6), radius: 10)
                    Text("FREE CHIPS")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)

                    TextField("", text: $name, prompt: Text("Player name").foregroundStyle(.white.opacity(0.5)))
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .focused($nameFocused)
                        .submitLabel(.done)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(.black.opacity(0.4)))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.gold.opacity(0.6)))
                        .foregroundStyle(.white)
                        .frame(width: 280)

                    Button("CLAIM & PLAY") {
                        Haptics.win(player.hapticsOn)
                        player.signUp(name: name)
                    }
                    .buttonStyle(GlossyButtonStyle(colors: [Color(hex: "7CD62E"), Color(hex: "2E8B12")], height: 52))
                    .frame(width: 280)

                    Text("For entertainment only. Chips have no cash value\nand cannot be redeemed for money or prizes.")
                        .font(.system(size: 10))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
            .padding()
        }
    }
}
