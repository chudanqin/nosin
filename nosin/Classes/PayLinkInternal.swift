//
//  PayLinkInternal.swift
//  nosin
//
//  Created by danqin chu on 2020/2/25.
//

import Foundation

extension PayLink {
    
    static func canOpen(scheme: String) -> Bool {
        if let url = URL(string: "\(scheme)://") {
            let b = UIApplication.shared.canOpenURL(url)
            return b
        }
        return false
    }
    
    static func open(url: URL, completion: ((PayLink.OpenStatus) -> Void)?) {
        if #available(iOS 10.0, *) {
            let block: ((Bool) -> Void)? = completion == nil ? nil : { (ok) in
                completion!(ok ? .success : .failure)
            }
            UIApplication.shared.open(url, options: [:], completionHandler: block)
        } else {
            completion?(UIApplication.shared.openURL(url) ? .success : .failure)
        }
    }
    
    public static func handleCallback(url: URL) -> Bool {
        if WeChat.handleCallback(url: url) {
            return true
        } else if Alipay.handleCallback(url: url) {
            return true
        } else {
            return false
        }
    }
}

extension PayLink.WeChat {
    
    static func _generateURL(with appId: String,
                             partnerId: String,
                             prepayId: String,
                             nonceStr: String,
                             timeStamp: String,
                             sign: String,
                             signType: String) -> URLComponents {
        var uc = URLComponents()
        uc.scheme = Self.name
        uc.host = "app"
        uc.path = "/\(appId)/pay/"
        
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "package", value: "Sign=WXPay".ns_qes))
        queryItems.append(URLQueryItem(name: "partnerId", value: partnerId))
        queryItems.append(URLQueryItem(name: "prepayId", value: prepayId.ns_qes))
        queryItems.append(URLQueryItem(name: "nonceStr", value: nonceStr)) // 随机串，防止重发
        queryItems.append(URLQueryItem(name: "timeStamp", value: timeStamp)) // 防止重发
        uc.queryItems = queryItems.sorted { $0.name < $1.name }
        queryItems.append(URLQueryItem(name: "sign", value: sign))
        queryItems.append(URLQueryItem(name: "signType", value: signType))
        uc.queryItems = queryItems
        
        return uc
    }
    
    static func _handle(url: URL) -> Bool {
        guard let request = Self.currentRequest else {
            return false
        }
        guard url.scheme == request.appId, url.host == "pay" else {
            return false
        }
        Self.currentRequest = nil
        guard let uc = URLComponents(url: url, resolvingAgainstBaseURL: false), let queryItems = uc.queryItems else {
            return true
        }
        for qi in queryItems {
            if qi.name == "ret", let val = qi.value, let code = Int(val)  {
                request.callback(Self.Response(rawCode: code))
                break
            }
        }
        return true
    }
    
}

extension PayLink.Alipay {
    
    static func _generateURL(with clientScheme: String,
                             order: String) -> URLComponents? {
        let params = [
            "fromAppUrlScheme": clientScheme,
            "requestType": "SafePay",
            "dataString": order
        ]
        guard let JSONData = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted), let JSONStr = String(data: JSONData, encoding: .utf8) else {
            return nil
        }
        var uc = URLComponents()
        uc.scheme = Self.name
        uc.host = "alipayclient"
        uc.path = "/"
        uc.query = JSONStr
        
        return uc
    }
    
    static func _handle(url: URL) -> Bool {
        guard url.host == "safepay", let request = Self.currentRequest, request.scheme == url.scheme, let query = url.query else {
            return false
        }
        guard let data = query.removingPercentEncoding?.data(using: .utf8), let JSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return false
        }
        self.currentRequest = nil
        request.callback(Self.Response(info: JSON ?? [:]))
        return true
    }
    
}

extension PayLink.Alipay.Response {
    
    func _getTradeNo() -> String? {
        let value = memo["result"]
        var result: [String: Any]?
        
        if let d = value as? [String: Any] {
            result = d
        } else if let s = value as? String, let data = s.data(using: .utf8) {
            if let obj = try? JSONSerialization.jsonObject(with: data, options: []) as? Dictionary<String, Any> {
                result = obj
            }
        }
            
        if let response = result?["alipay_trade_app_pay_response"] as? Dictionary<String, Any> {
            if let tradeNo = response["trade_no"] as? String {
                return tradeNo
            }
        }
        return nil
    }
    
}

extension String {
    var ns_qes: String? {
        return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
}

func _log(_ msg: String, function: String = #function, line: Int = #line) {
    PayLink.onLog?(msg, function, line)
}
