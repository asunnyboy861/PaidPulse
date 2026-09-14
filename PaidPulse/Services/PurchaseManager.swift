import Foundation
import StoreKit
import Combine

@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    static let lifetimeID = "com.zzoutuo.PaidPulse.pro.lifetime"
    static let monthlyID = "com.zzoutuo.PaidPulse.pro.monthly"
    static let yearlyID = "com.zzoutuo.PaidPulse.pro.yearly"
    static let packIDs = [
        "com.zzoutuo.PaidPulse.pack.design",
        "com.zzoutuo.PaidPulse.pack.dev",
        "com.zzoutuo.PaidPulse.pack.photo",
        "com.zzoutuo.PaidPulse.pack.construction"
    ]
    static let allIDs = [lifetimeID, monthlyID, yearlyID] + packIDs

    @Published var isPro: Bool = false
    @Published var ownedPacks: Set<String> = []
    @Published var products: [Product] = []
    @Published var isLoading: Bool = false
    @Published var loadError: String?

    private var updatesTask: Task<Void, Never>?

    private init() {
        updatesTask = listenForUpdates()
        Task { await refresh() }
    }

    deinit {
        updatesTask?.cancel()
    }

    var lifetimeProduct: Product? { products.first { $0.id == Self.lifetimeID } }
    var monthlyProduct: Product? { products.first { $0.id == Self.monthlyID } }
    var yearlyProduct: Product? { products.first { $0.id == Self.yearlyID } }
    var packProducts: [Product] { products.filter { Self.packIDs.contains($0.id) } }

    func refresh() async {
        isLoading = true
        do {
            products = try await Product.products(for: Self.allIDs)
            loadError = nil
        } catch {
            loadError = "Unable to load purchase options."
        }
        await checkEntitlements()
        isLoading = false
    }

    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await checkEntitlements()
                    return true
                }
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            loadError = "Purchase failed: \(error.localizedDescription)"
        }
        return false
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkEntitlements()
        } catch {
            loadError = "Restore failed: \(error.localizedDescription)"
        }
    }

    private func checkEntitlements() async {
        var pro = false
        for id in [Self.lifetimeID, Self.monthlyID, Self.yearlyID] {
            if let result = await Transaction.currentEntitlement(for: id),
               case .verified(let transaction) = result,
               transaction.revocationDate == nil {
                pro = true
            }
        }
        isPro = pro
        var packs: Set<String> = []
        for id in Self.packIDs {
            if let result = await Transaction.currentEntitlement(for: id),
               case .verified(let transaction) = result,
               transaction.revocationDate == nil {
                packs.insert(id)
            }
        }
        ownedPacks = packs
    }

    private func listenForUpdates() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    Task { @MainActor [weak self] in
                        await self?.checkEntitlements()
                    }
                }
            }
        }
    }
}
