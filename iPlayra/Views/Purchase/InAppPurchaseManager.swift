//
//  InAppPurchaseManager.swift
//  iPlay
//
//  Created by Shiv on 28/09/25.
//

import SwiftUI
import Combine
import StoreKit

@MainActor
class InAppPurchaseManager: ObservableObject {
    static let shared: InAppPurchaseManager = InAppPurchaseManager()
        
    @AppStorage("hasPurchased") var hasPurchased: Bool = false
    @AppStorage("hasRemoveAd") var hasRemoveAd: Bool = false
    
    @Published var availableProducts: [Product] = []
    @Published var adRemoveProduct: Product?
    
    private init() {
        Task {
            await fetchProducts()
            await updatePurchasedStatus()
            await observeTransactions()
        }
    }
    
    // Fetch products from App Store
    func fetchProducts() async {
        do {
            let storeProducts = try await Product.products(for: [
                "com.iplay.monthly", // Auto Renewable ProductID
                "com.iplay.yearly", // Auto Renewable ProductID
                "com.iplay.lifetime", // Non Consumable ProductID
                "com.iplay.remove.ad" // Non Consumable ProductID
            ])
            availableProducts = storeProducts.filter({ $0.id != "com.iplay.remove.ad" }).sorted(by: { $0.price < $1.price })
            adRemoveProduct = storeProducts.filter({ $0.id == "com.iplay.remove.ad" }).first
            print("Products fetched successfully: \(availableProducts.map({ $0.displayName }))")
        } catch {
            print("Failed to fetch products: \(error.localizedDescription)")
        }
    }
    
    // Purchase Product
    func purchase(_ product: Product) async -> (Bool) {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    print("Purchase Success: \(verification)")
                    await transaction.finish()
                    await updatePurchasedStatus()
                    return true
                }
            case .userCancelled:
                print("Purchase Cancelled")
            case .pending:
                print("Purchase pending...")
            default:
                print("Purchase Failed / pending...")
            }
        } catch {
            print("Purchase error: \(error.localizedDescription)")
        }
        return false
    }
    
    // Check already purchased items
    func updatePurchasedStatus() async {
        var premiumActive: Bool = false
        var removeAd: Bool = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                print("Already Purchased Transation: \(transaction)")
                if ["com.iplay.monthly", "com.iplay.yearly", "com.iplay.lifetime"].contains(transaction.productID) {
                    premiumActive = true
                    removeAd = true
                }
                if "com.iplay.remove.ad" == transaction.productID {
                    removeAd = true
                }
            }
        }
        hasPurchased = premiumActive
        hasRemoveAd = removeAd
        print("Premium Status: \(hasPurchased), Remove Ad Status: \(hasRemoveAd)")
    }
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            print("Restore purchases failed: \(error)")
        }
    }
    
    private func observeTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transation) = result {
                print("Transaction Update: \(transation)")
                await transation.finish()
                await updatePurchasedStatus()
            }
        }
    }
}
