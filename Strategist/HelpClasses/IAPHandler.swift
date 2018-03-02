import StoreKit

class IAPHandler: NSObject {
    static let sharedInstance = IAPHandler()
    
    let GEMS_50_ID = "Bezgodov.Strategist.50GEMS_new"
    let GEMS_300_ID = "Bezgodov.Strategist.300GEMS_new"
    let GEMS_500_ID = "Bezgodov.Strategist.500GEMS_new"
    
    fileprivate var productID = String()
    fileprivate var productsRequest = SKProductsRequest()
    fileprivate var iapProducts = [String: SKProduct]()
    
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
            let alertController = UIAlertController(title: NSLocalizedString("FAIL", comment: ""), message: NSLocalizedString("Purchases are disabled in your device", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: UIAlertActionStyle.default)
            alertController.addAction(okAction)
            UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
        }
    }
    
    func fetchAvailableProducts() {
        
        let productIdentifiers = NSSet(objects: GEMS_50_ID,GEMS_300_ID,GEMS_500_ID
        )
        
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers as! Set<String>)
        productsRequest.delegate = self
        productsRequest.start()
    }
}

extension IAPHandler: SKProductsRequestDelegate, SKPaymentTransactionObserver {
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
                        if trans.payment.productIdentifier == GEMS_50_ID {
                            
                            if Model.sharedInstance.menuViewController != nil {
                                Model.sharedInstance.menuViewController.addGems(amount: 50)
                            }
                            else {
                                addGems(amount: 50)
                            }
                            
                            Model.sharedInstance.menuViewController.presentViewIAP(remove: true)
                            SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                        }
                        else {
                            if trans.payment.productIdentifier == GEMS_300_ID {
                                
                                if Model.sharedInstance.menuViewController != nil {
                                    Model.sharedInstance.menuViewController.addGems(amount: 300)
                                }
                                else {
                                    addGems(amount: 300)
                                }
                                
                                Model.sharedInstance.menuViewController.presentViewIAP(remove: true)
                                SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                            }
                            else {
                                if trans.payment.productIdentifier == GEMS_500_ID {
                                    
                                    if Model.sharedInstance.menuViewController != nil {
                                        Model.sharedInstance.menuViewController.addGems(amount: 500)
                                    }
                                    else {
                                        addGems(amount: 500)
                                    }
                                    
                                    Model.sharedInstance.menuViewController.presentViewIAP(remove: true)
                                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                                }
                            }
                        }
                        break
                    case .failed:
                        Model.sharedInstance.menuViewController.presentViewIAP(remove: true)
                        
                        let alertController = UIAlertController(title: NSLocalizedString("FAIL", comment: ""), message: NSLocalizedString("Something went wrong, try again", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
                        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: UIAlertActionStyle.default)
                        alertController.addAction(okAction)
                        UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
                        
                        SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                        break
                    case .purchasing:
                        Model.sharedInstance.menuViewController.presentViewIAP()
                        break
                    case .deferred:
                        Model.sharedInstance.menuViewController.presentViewIAP(remove: true)
                        break
                    default:
                        break
                }
            }
        }
    }
    
    func addGems(amount: Int) {
        Model.sharedInstance.setCountGems(amountGems: amount)
    }
}
