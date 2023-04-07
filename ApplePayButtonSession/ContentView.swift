//
//  ContentView.swift
//  ApplePayButtonSession
//
//  Created by MubarakAlsaif on 06/04/2023.
//

import SwiftUI
import PassKit

struct Product: Identifiable {
    var id = UUID()
    var name : String
    var price : Double
}
struct ContentView: View {
    
    let products = [Product(name: "T-shirt", price: 20.0), Product(name: "Watch", price: 80.0)]
    
    var body: some View {
        PaymentButton(products: products)
            .frame(minWidth: 100,maxWidth: .infinity,maxHeight: 45)
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


struct PaymentButton: UIViewRepresentable {
    
    var products: [Product]
    
    func makeCoordinator() -> PaymentManager {
        PaymentManager(products: products)
    }
    func makeUIView(context: Context) -> some UIView {
        context.coordinator.button
    }
    func updateUIView(_ uiView: UIViewType, context: Context) {
        context.coordinator.products = products
    }
    
}
class PaymentManager: NSObject,PKPaymentAuthorizationControllerDelegate {

    
    
    var products : [Product]
    
    var button = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .automatic)
    
    init(products: [Product]) {
        self.products = products
        super.init()
        button.addTarget(self, action: #selector(callBack(_:)), for: .touchUpInside)
    }
    
    @objc func callBack(_ sender: Any) {
        startPayment(products: products )
    }
    func startPayment(products: [Product]) {
        var paymentController: PKPaymentAuthorizationController?
        
        var paymentSummaryItems = [PKPaymentSummaryItem]()
        
        var totalPrice: Double = 0
        products.forEach { product in
            let item = PKPaymentSummaryItem(label: product.name, amount: NSDecimalNumber(string: "\(product.price.rounded())"),type: .final)
            totalPrice += product.price.rounded()
            paymentSummaryItems.append(item)
        }
        
        let total = PKPaymentSummaryItem(label: "Total", amount: NSDecimalNumber(string: "\(totalPrice)"),type: .final)
        paymentSummaryItems.append(total)
        
        
        let paymentRequest = PKPaymentRequest()
        
        paymentRequest.paymentSummaryItems = paymentSummaryItems
        paymentRequest.countryCode = "SA"
        paymentRequest.currencyCode = "SAR"
        paymentRequest.supportedNetworks = [.visa,.mada,.masterCard]
        paymentRequest.shippingType = .delivery
        paymentRequest.merchantIdentifier = "merchant.ApplePayButtonSession"
        paymentRequest.merchantCapabilities = .capability3DS
        paymentRequest.shippingMethods = shippingMethodCalculator()
        paymentRequest.requiredShippingContactFields = [.name,.phoneNumber]
        
        paymentController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        
        paymentController?.delegate = self
        paymentController?.present()
        
        
        
    }
    func shippingMethodCalculator() -> [PKShippingMethod] {
        
        let today = Date()
        let calendar = Calendar.current
        
        let shippingStart = calendar.date(byAdding: .day, value: 5, to: today)
        let shippingEnd = calendar.date(byAdding: .day, value: 10, to: today)
        
        if let shippingEnd = shippingEnd, let shippingStart = shippingStart {
            
            let startComponents = calendar.dateComponents([.calendar,.year,.month,.day], from: shippingStart)
            
            let endComponents = calendar.dateComponents([.calendar,.year,.month,.day], from: shippingEnd)
            
            let shippingDelivery = PKShippingMethod(label: "Delivery", amount: NSDecimalNumber(string: "0.00"))
            
            shippingDelivery.dateComponentsRange = PKDateComponentsRange(start: startComponents, end: endComponents)
            shippingDelivery.detail = "Arrives by 5pm on July 29."
            shippingDelivery.identifier = "DELIVERY"
            
            return [shippingDelivery]
        }
        
        return []
        
    }
    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didAuthorizePayment payment: PKPayment) async -> PKPaymentAuthorizationResult {
        .init(status: .success, errors: nil)
    }
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss()
    }
}
