import StoreKit

enum IAPHandlerAlertType {
    case error
    case disabled
    case purchased_35GEMS
    case purchased_85GEMS
    case purchased_125GEMS
    
    func message() -> String{
        switch self {
            case .error:
                return "Something went wrong, try again"
            case .disabled:
                return "Purchases are disabled in your device"
            case .purchased_35GEMS:
                return "You've successfully bought 35 GEMS"
            case .purchased_85GEMS:
                return "You've successfully bought 85 GEMS"
            case .purchased_125GEMS:
                return "You've successfully bought 125 GEMS"
        }
    }
}

class IAPHandler: NSObject {
    static let sharedInstance = IAPHandler()
    
    let GEMS_35_ID = "Bezgodov.Strategist.35GEMS"
    let GEMS_85_ID = "Bezgodov.Strategist.85GEMS"
    let GEMS_125_ID = "Bezgodov.Strategist.125GEMS"
    
    fileprivate var productID = String()
    fileprivate var productsRequest = SKProductsRequest()
    fileprivate var iapProducts = [String: SKProduct]()
    
    var purchaseStatusBlock: ((IAPHandlerAlertType) -> Void)?
    
    func isAbleToPurchase () -> Bool { return SKPaymentQueue.canMakePayments() }
    
    func purchaseProduct(id: String) {
        if iapProducts.count == 0 { return }
        
        if isAbleToPurchase() {
            let product = iapProducts[id]!
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(self)
            SKPaymentQueue.default().add(payment)
            
            productID = product.productIdentifier
        }
        else {
            purchaseStatusBlock?(.disabled)
        }
    }
    
    func fetchAvailableProducts() {
        
        let productIdentifiers = NSSet(objects: GEMS_35_ID,GEMS_85_ID,GEMS_125_ID
        )
        
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers as! Set<String>)
        productsRequest.delegate = self
        productsRequest.start()
    }
}

extension IAPHandler: SKProductsRequestDelegate, SKPaymentTransactionObserver{
    func productsRequest (_ request:SKProductsRequest, didReceive response:SKProductsResponse) {
        if (response.products.count > 0) {
            for product in response.products {
                iapProducts[product.productIdentifier] = product
            }
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction:AnyObject in transactions {
            if let trans = transaction as? SKPaymentTransaction {
                switch trans.transactionState {
                    case .purchased:
                        SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                        if productID == GEMS_35_ID {
                            purchaseStatusBlock?(.purchased_35GEMS)
                        }
                        else {
                            if productID == GEMS_85_ID {
                                purchaseStatusBlock?(.purchased_85GEMS)
                            }
                            else {
                                if productID == GEMS_125_ID {
                                    purchaseStatusBlock?(.purchased_125GEMS)
                                }
                                else {
                                    purchaseStatusBlock?(.error)
                                }
                            }
                        }
                        break
                    case .failed:
                        SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                        break
                    default:
                        break
                }
            }
        }
    }
}
