import SwiftUI

struct StoreView: View {
    var focusPromo: Bool

    @EnvironmentObject private var player: PlayerStore
    @EnvironmentObject private var store: StoreManager
    @EnvironmentObject private var promos: PromoCodeService
    @Environment(\.dismiss) private var dismiss

    @State private var codeText = ""
    @State private var promoError: String?
    @FocusState private var promoFocused: Bool

    var body: some View {
        ZStack {
            LobbyBackground()
            VStack(spacing: 10) {
                header
                promoBar
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(GameConfig.chipPacks.enumerated()), id: \.element.id) { idx, pack in
                            packRow(pack, index: idx)
                            Divider().overlay(.white.opacity(0.25))
                        }
                    }
                    Text("Chips are virtual, for entertainment only, and have no cash value. They cannot be redeemed for money or prizes.")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 10)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            if let receipt = store.lastPurchase {
                PurchaseSuccess(receipt: receipt) { store.lastPurchase = nil }
            }
        }
        .onAppear {
            if focusPromo { DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { promoFocused = true } }
        }
        .alert("Store", isPresented: Binding(get: { store.errorMessage != nil },
                                             set: { if !$0 { store.errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(.black.opacity(0.35)))
                    .overlay(Circle().strokeBorder(.white.opacity(0.25)))
            }
            .foregroundStyle(.white)
            BalancePill(chips: player.chips)
            Spacer()
            Text("GET CHIPS")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(Theme.gold)
            Spacer()
            Button("Restore Purchases") { Task { await store.restore() } }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(hex: "4A2A00"))
                .padding(.horizontal, 18).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.gold))
        }
    }

    // MARK: Promo code

    private var promoBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "ticket.fill").foregroundStyle(Theme.gold)
            if let applied = store.appliedPromo {
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(applied.code.uppercased()) applied")
                        .font(.system(size: 15, weight: .heavy)).foregroundStyle(.green)
                    Text(applied.label ?? "+\(applied.bonusPercent)% bonus chips on your next purchase")
                        .font(.system(size: 12)).foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                Button("Remove") { store.appliedPromo = nil; codeText = "" }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
            } else {
                TextField("", text: $codeText, prompt: Text("Enter promo code").foregroundStyle(.white.opacity(0.45)))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .focused($promoFocused)
                    .submitLabel(.go)
                    .onSubmit(applyCode)
                    .foregroundStyle(.white)
                if let promoError {
                    Text(promoError).font(.system(size: 12, weight: .semibold)).foregroundStyle(Color(hex: "FF8A80"))
                }
                Button("APPLY", action: applyCode)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(Color(hex: "4A2A00"))
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.gold))
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 12).fill(.black.opacity(0.4)))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(store.appliedPromo != nil ? Color.green : Theme.gold.opacity(0.5)))
    }

    private func applyCode() {
        switch promos.validate(codeText, player: player) {
        case .success(let code):
            store.appliedPromo = code
            promoError = nil
            promoFocused = false
            Haptics.win(player.hapticsOn)
        case .failure(let error):
            promoError = error.errorDescription
        }
    }

    // MARK: Pack rows

    private func packRow(_ pack: ChipPack, index: Int) -> some View {
        let promoBonus = store.appliedPromo.map { promos.bonusChips(for: $0, pack: pack) } ?? 0
        let buying = store.purchasingID == pack.productID

        return HStack(spacing: 16) {
            ChipView(value: pack.totalChips, colorIndex: index, size: 46)
            VStack(alignment: .leading, spacing: 2) {
                if let badge = pack.badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .black))
                        .tracking(0.5)
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(Capsule().fill(badge == "BEST VALUE" ? Color(hex: "2E9E3E") : Color(hex: "FF1744")))
                        .foregroundStyle(.white)
                }
                Group {
                    if pack.bonusPercent > 0 {
                        Text("\(pack.baseChips.formatted()) + \(pack.bonusPercent)% = \(String(pack.totalChips.shortChipString.dropFirst())) Chips")
                    } else {
                        Text("\(pack.totalChips.formatted()) Chips")
                    }
                }
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(1).minimumScaleFactor(0.6)

                if promoBonus > 0 {
                    Text("+\(promoBonus.formatted()) promo bonus → \((pack.totalChips + promoBonus).formatted()) total")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.green)
                } else if store.appliedPromo != nil {
                    Text("Promo not valid on this pack")
                        .font(.system(size: 11)).foregroundStyle(.white.opacity(0.5))
                }
            }
            Spacer()
            Button {
                Task { await store.buy(pack) }
            } label: {
                ZStack {
                    Text(store.price(for: pack)).opacity(buying ? 0 : 1)
                    if buying { ProgressView().tint(Color(hex: "4A2A00")) }
                }
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(hex: "4A2A00"))
                .frame(width: 120, height: 42)
                .background(RoundedRectangle(cornerRadius: 6).fill(
                    LinearGradient(colors: [Theme.gold, Theme.goldDark], startPoint: .top, endPoint: .bottom)))
            }
            .disabled(store.purchasingID != nil)
        }
        .padding(.vertical, 10)
    }
}

private struct PurchaseSuccess: View {
    let receipt: StoreManager.PurchaseReceipt
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill").font(.system(size: 48)).foregroundStyle(.green)
                Text("+\(receipt.chips.chipString)")
                    .font(.system(size: 34, weight: .black, design: .rounded)).foregroundStyle(Theme.gold)
                if receipt.promoBonus > 0 {
                    Text("Includes \(receipt.promoBonus.chipString) promo bonus")
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(.green)
                }
                Button("AWESOME", action: onDone)
                    .buttonStyle(GlossyButtonStyle(colors: [Color(hex: "7CD62E"), Color(hex: "2E8B12")], height: 46))
                    .frame(width: 200)
            }
            .padding(28)
            .background(RoundedRectangle(cornerRadius: 20).fill(Theme.lobbyTop)
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.gold, lineWidth: 3)))
        }
    }
}
