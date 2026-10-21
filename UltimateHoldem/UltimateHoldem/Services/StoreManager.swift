import Foundation
import StoreKit

/// StoreKit 2 chip store. Chip packs are consumable in-app purchases.
@MainActor
final class StoreManager: ObservableObject {
    @Published private(set) var products: [String: Product] = [:]
    @Published private(set) var purchasingID: String?
    @Published var lastPurchase: PurchaseReceipt?
    @Published var errorMessage: String?

    /// Promo code applied in the store; consumed by the next successful purchase.
    @Published var appliedPromo: PromoCode?

    struct PurchaseReceipt: Identifiable, Equatable {
        let id = UUID()
        let chips: Int
        let promoBonus: Int
    }

    private weak var player: PlayerStore?
    private weak var promos: PromoCodeService?
    private var updatesTask: Task<Void, Never>?

    func attach(player: PlayerStore, promos: PromoCodeService) {
        self.player = player
        self.promos = promos
        guard updatesTask == nil else { return }
        // Purchases completed outside the app flow (Ask to Buy, interrupted, other device).
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
        Task {
            await loadProducts()
            await processUnfinished()
        }
    }

    func loadProducts() async {
        do {
            let ids = GameConfig.chipPacks.map(\.productID)
            let loaded = try await Product.products(for: ids)
            products = Dictionary(uniqueKeysWithValues: loaded.map { ($0.id, $0) })
        } catch {
            errorMessage = "Couldn't load the store. Check your connection."
        }
    }

    /// Regular price, e.g. "$4.99".
    func price(for pack: ChipPack) -> String {
        products[pack.productID]?.displayPrice ?? pack.fallbackPrice
    }

    func buy(_ pack: ChipPack) async {
        guard let product = products[pack.productID] else {
            errorMessage = "This item isn't available right now."
            await loadProducts()
            return
        }
        purchasingID = pack.productID
        defer { purchasingID = nil }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                await handle(verification)
            case .pending:
                errorMessage = "Purchase pending approval."
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Consumables aren't restorable, but this re-syncs with the App Store and delivers anything unfinished.
    func restore() async {
        do {
            try await AppStore.sync()
            await processUnfinished()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Delivery

    private func processUnfinished() async {
        for await result in Transaction.unfinished {
            await handle(result)
        }
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }   // ignore unverified
        guard let player,
              let pack = GameConfig.chipPacks.first(where: { $0.productID == transaction.productID }) else {
            await transaction.finish()
            return
        }

        if transaction.revocationDate == nil && !player.hasProcessed(transactionID: transaction.id) {
            var bonus = 0
            if let promo = appliedPromo, let promos {
                bonus = promos.bonusChips(for: promo, pack: pack)
                if bonus > 0 {
                    player.markRedeemed(code: promo.code)
                    appliedPromo = nil
                }
            }
            let chips = pack.totalChips + bonus
            player.recordPurchase(transactionID: transaction.id, chips: chips)
            lastPurchase = PurchaseReceipt(chips: chips, promoBonus: bonus)
        }
        await transaction.finish()
    }
}
