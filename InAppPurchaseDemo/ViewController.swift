//
//  ViewController.swift
//  InAppPurchaseDemo
//
//  Created by Tristen陈涛 on 2017/7/19.
//  Copyright © 2017年 Tristen陈涛. All rights reserved.
//

import UIKit
import StoreKit

class ViewController: UIViewController, SKPaymentTransactionObserver, SKProductsRequestDelegate{
    
    private let saveReceiptKey = "SaveReceiptKey"
    
    private let appStoreUrl = "https://sandbox.itunes.apple.com/verifyReceipt"// 测试环境(沙盒账号付款)
    //    private let appStoreUrl = "https://buy.itunes.apple.com/verifyReceipt" //正式环境
    
    private let appleID = "1153224146"
    
    private let productID = "1153224146" //购买商品的 ID
    
    private var allproducts : [SKProduct] = []
    
    @IBAction func buy(_ sender: Any) {
        
        var prod: SKProduct?
        for pro in self.allproducts {
            if pro.productIdentifier == productID {
                prod = pro
            }
        }
        
        //发送购买请求
        if let produ = prod {
            purchaseProduct(produ)
        }
        
    }
    
    deinit {
        //移除监听
        SKPaymentQueue.default().remove(self)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //1、开启内购检测
        SKPaymentQueue.default().add(self)
        
        //2、获取所有可购买商品信息
        reuqestPurchaseData()
        
        //如果有本地持久的验证信息，说明之前还有凭证未验证，需要重新验证
        if let receiptString = self.loadReceiptString() {
            self.validateReceipt(receiptString)
        }
    }
    
    //获取所有购买信息
    private func reuqestPurchaseData() {
        
        if SKPaymentQueue.canMakePayments() {
            let request = SKProductsRequest(productIdentifiers: [appleID])
            request.delegate = self
            request.start()
            
        }else{
            print("您已设置不允许程序内购买")
        }
        
    }
    
    //3、返回所有购买信息
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if response.products.count == 0 {
            print("没有商品")
        }
        
        self.allproducts = response.products
        
        var prod: SKProduct?
        for pro in response.products {
            print("------------------")
            print(pro.localizedDescription)
            print(pro.localizedTitle)
            print(pro.price)
            print(pro.productIdentifier)
            print("------------------")
        }
    }
    
    //4、购买商品
    private func purchaseProduct(_ product:SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    //5、获取购买结果
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        for transaction in transactions {
            print(transaction.error?.localizedDescription)
            
            switch transaction.transactionState {
            case .purchased:
                print("购买成功")
                commitSeversSucceeWithTransaction(transation: transaction)
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case .purchasing:
                print("用户正在购买")
                
            case .restored:
                print("已经购买过商品")
                
            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
                print("失败")
                
            default:
                break
            }
        }
    }
    
    
    //6、验证购买是否成功
    private func commitSeversSucceeWithTransaction(transation: SKPaymentTransaction) {
        
        //获取 receipt 信息
        let receiptUrl = Bundle.main.appStoreReceiptURL
        let receiveData = NSData.init(contentsOf: receiptUrl!)
        let receiptString = receiveData!.base64EncodedString(options: .endLineWithLineFeed)
        
        //先保存凭证，如果发现异常情况导致验证失败可以重新从UserDefaults取出数据后重新进行验证
        self.saveReceiptString(receiptString)
        
        self.validateReceipt(receiptString)
    }
    
    private func validateReceipt(_ receiptString:String) {
        
        //向苹果服务器验证付款信息
        //        let url = URL.init(string: appStoreUrl)
        //        let bodyString = "{\"receipt-data\" : \"\(receiptString)\"}"
        
        
        //向自家服务端验证付款信息
//        let url = URL.init(string: "http://192.168.1.26:8080/account/VerifyiReceipt?userID=10011&token=35a67fe5-b35d-440a-bfa6-8f1b80fa2d0d")
        let url = URL.init(string: "http://test.wolf.esgame.com/account/VerifyiReceipt?userID=10011&token=35a67fe5-b35d-440a-bfa6-8f1b80fa2d0d")
        
        
        let urlEncodeReceiptString = urlEncode(receiptString)
        let bodyString = "receiptData=\(urlEncodeReceiptString)"
        
        let reuqest = NSMutableURLRequest.init(url: url!)
        let bodyData = bodyString.data(using: String.Encoding.utf8)
        reuqest.httpBody = bodyData
        reuqest.httpMethod = "POST"
        
        if let responseData = try? NSURLConnection.sendSynchronousRequest(reuqest as URLRequest, returning: nil) {
            let dic: NSDictionary = try! JSONSerialization.jsonObject(with: responseData, options: .allowFragments) as! NSDictionary
            print("验证结果：\(dic)")
            
            //请求成功则删除本地凭证
            self.deleteReceiptString()
        }
    }
    
    private func urlEncode(_ string:String) -> String {
        
        let generalDelimiters = ":#[]@ "
        let subDelimiters = "!$&'()*+,;="
        let allowedCharacters = generalDelimiters + subDelimiters
        let customAllowedSet =  NSCharacterSet.init(charactersIn: allowedCharacters).inverted
        return string.addingPercentEncoding(withAllowedCharacters: customAllowedSet)!
    }
    
    private func saveReceiptString(_ string:String) {
        UserDefaults.standard.set(string, forKey: saveReceiptKey)
        UserDefaults.standard.synchronize()
    }
    
    private func loadReceiptString() -> String? {
        return UserDefaults.standard.value(forKey: saveReceiptKey) as? String
    }
    
    private func deleteReceiptString() {
        UserDefaults.standard.removeObject(forKey: saveReceiptKey)
        UserDefaults.standard.synchronize()
    }
}
