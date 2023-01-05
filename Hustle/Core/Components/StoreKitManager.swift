import Foundation
import StoreKit

public enum StoreError: Error {
    case failedVerification
}

class StoreKitManager: ObservableObject {
    private let userService = UserService()
    @Published var storeProducts: [Product] = []
    var updateListenerTask: Task<Void, Error>? = nil
    private var productDict: [String] = {
        var keys: [String] = []
        for i in stride(from: 20, through: 900, by: 20) {
            keys.append("\(i)ELO")
        }
        
        keys.append("1Day")
        keys.append("3Day")
        
        keys.append("OneDayBoost")
        keys.append("TwoDayBoost")
        keys.append("ThreeDayBoost")
        keys.append("OneDayBoostPlus")
        keys.append("TwoDayBoostPlus")
        
        return keys
    }()

    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await requestProducts()
        }
    }
    deinit { 
        updateListenerTask?.cancel()
    }
    func updateEmptyDic(){
        self.productDict = generateProductDict()
    }
    private func generateProductDict() -> [String] {
        var keys: [String] = []
        
        for i in stride(from: 20, through: 900, by: 20) {
            keys.append("\(i)ELO")
        }
        
        keys.append("1Day")
        keys.append("3Day")
        
        keys.append("OneDayBoost")
        keys.append("TwoDayBoost")
        keys.append("ThreeDayBoost")
        keys.append("OneDayBoostPlus")
        keys.append("TwoDayBoostPlus")
        
        return keys
    }
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    
                    self.updateDB(transaction: transaction)
                    
                    await transaction.finish()
                } catch {
                    print("Failed")
                }
            }
        }
    }
    @MainActor
    func requestProducts() async {
        do {
            storeProducts = try await Product.products(for: productDict)
        } catch {
            print("Failed")
        }
    }
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let signedType):
            return signedType
        }
    }
    func updateDB(transaction: Transaction) {
        if transaction.productID.contains("ELO") {
            if let amount = Int(transaction.productID.dropLast(3)){
                userService.editElo(withUid: nil, withAmount: amount) { }
            }
        }
    }
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()

        switch result {
        case .success(let verificationResult):
            let transaction = try checkVerified(verificationResult)
            
            updateDB(transaction: transaction)
            
            await transaction.finish()
            
            return true
        case .userCancelled, .pending:
            return false
        default:
            return false
        }
    }  
}
