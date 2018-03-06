import StoreKit
import Flurry_iOS_SDK

class IAPHandler: NSObject {
    
    override init() {
        super.init()
        
        SKPaymentQueue.default().add(self)
    }
    
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
//            SKPaymentQueue.default().add(self)
            SKPaymentQueue.default().add(payment)
            
            productID = product.productIdentifier
        }
        else {
            if Model.sharedInstance.menuViewController != nil {
                let alertController = UIAlertController(title: NSLocalizedString("FAIL", comment: ""), message: NSLocalizedString("Purchases are disabled in your device", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
                let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: UIAlertActionStyle.default)
                alertController.addAction(okAction)
                Model.sharedInstance.menuViewController.present(alertController, animated: true, completion: nil)
            }
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
                            
                            let eventParams = ["countGems": Model.sharedInstance.getCountGems()]
                            Flurry.logEvent("Buy_gems_50_success", withParameters: eventParams)
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
                                
                                let eventParams = ["countGems": Model.sharedInstance.getCountGems()]
                                Flurry.logEvent("Buy_gems_300_success", withParameters: eventParams)
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
                                    
                                    let eventParams = ["countGems": Model.sharedInstance.getCountGems()]
                                    Flurry.logEvent("Buy_gems_500_success", withParameters: eventParams)
                                }
                            }
                        }
                        break
                    case .failed:
                        if Model.sharedInstance.menuViewController != nil {
                            Model.sharedInstance.menuViewController.presentViewIAP(remove: true)
                            
                            var title = NSLocalizedString("FAIL", comment: "")
                            var message = NSLocalizedString("Something went wrong, try again", comment: "")
                            
                            // Если покупка была отменена, то выводим сообщение об этом
                            if trans.error?._code != SKError.paymentCancelled.rawValue {
                                title = NSLocalizedString("Cancel", comment: "")
                                message = NSLocalizedString("Purchasing cancelled", comment: "")
                                
                                let eventParams = ["countGems": Model.sharedInstance.getCountGems()]
                                Flurry.logEvent("Buy_gems_cancel", withParameters: eventParams)
                            }
                            else {
                                let eventParams = ["countGems": Model.sharedInstance.getCountGems()]
                                Flurry.logEvent("Buy_gems_error", withParameters: eventParams)
                            }
                            
                            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
                            let actionOk = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: UIAlertActionStyle.default)
                            alert.addAction(actionOk)
                            Model.sharedInstance.menuViewController.present(alert, animated: true, completion: nil)
                        }
                        
                        SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                        break
                    case .purchasing:
                        if Model.sharedInstance.menuViewController != nil {
                            Model.sharedInstance.menuViewController.presentViewIAP()
                        }
                        break
                    case .deferred:
                        if Model.sharedInstance.menuViewController != nil {
                            Model.sharedInstance.menuViewController.presentViewIAP(remove: true)
                        }
                        break
                case .restored:
                    break
                }
            }
        }
    }
    
    func addGems(amount: Int) {
        Model.sharedInstance.setCountGems(amountGems: amount)
    }
}
