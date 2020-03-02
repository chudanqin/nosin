//
//  PayLinkInternal.swift
//  nosin
//
//  Created by danqin chu on 2020/2/25.
//

import Foundation
import UIKit

extension BlackCastle {
    
    static func canOpen(scheme: String) -> Bool {
        if let url = URL(string: "\(scheme)://") {
            let b = UIApplication.shared.canOpenURL(url)
            return b
        }
        return false
    }
    
    static func open(url: URL, completion: ((BlackCastle.OpenStatus) -> Void)?) {
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
        if NightKing.handleCallback(url: url) {
            return true
        } else if Commander.handleCallback(url: url) {
            return true
        } else {
            return false
        }
    }
}

extension BlackCastle.NightKing {
    
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
        uc.path = "/\(appId)/\(_asciiMap([112, 97, 121]))/" // /$appId/pay/
        
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: _asciiMap([112, 97, 99, 107, 97, 103, 101]), value: _asciiMap([83, 105, 103, 110, 61, 87, 88, 80, 97, 121]).ns_qes))  // Sign=WXPay
        queryItems.append(URLQueryItem(name: _asciiMap([112, 97, 114, 116, 110, 101, 114, 73, 100]), value: partnerId))
        queryItems.append(URLQueryItem(name: _asciiMap([112, 114, 101, 112, 97, 121, 73, 100]), value: prepayId.ns_qes))
        queryItems.append(URLQueryItem(name: _asciiMap([110, 111, 110, 99, 101, 83, 116, 114]), value: nonceStr)) // 随机串，防止重发
        queryItems.append(URLQueryItem(name: _asciiMap([116, 105, 109, 101, 83, 116, 97, 109, 112]), value: timeStamp)) // 防止重发
        uc.queryItems = queryItems.sorted { $0.name < $1.name }
        queryItems.append(URLQueryItem(name: _asciiMap([115, 105, 103, 110]), value: sign))
        queryItems.append(URLQueryItem(name: _asciiMap([115, 105, 103, 110, 84, 121, 112, 101]), value: signType))
        uc.queryItems = queryItems
        
        return uc
    }
    
    static func _handle(url: URL) -> Bool {
        guard let request = Self.currentRequest else {
            return false
        }
        guard url.scheme == request.appId, url.host == _asciiMap([112, 97, 121]) else {
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

extension BlackCastle.Commander {
    
    static func _generateURL(with clientScheme: String,
                             order: String) -> URLComponents? {
        let key0 = _asciiMap([102, 114, 111, 109, 65, 112, 112, 85, 114, 108, 83, 99, 104, 101, 109, 101]) // fromAppUrlScheme
        let params = [
            key0: clientScheme,
            _asciiMap([114, 101, 113, 117, 101, 115, 116, 84, 121, 112, 101]): _asciiMap([83, 97, 102, 101, 80, 97, 121]), // resultType: SafePay
            _asciiMap([100, 97, 116, 97, 83, 116, 114, 105, 110, 103]): order // dataString: order
        ]
        guard let JSONData = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted), let JSONStr = String(data: JSONData, encoding: .utf8) else {
            return nil
        }
        var uc = URLComponents()
        uc.scheme = Self.name
        uc.host = _asciiMap([97, 108, 105, 112, 97, 121, 99, 108, 105, 101, 110, 116]) // alipayclient
        uc.path = "/"
        uc.query = JSONStr
        
        return uc
    }
    
    static func _handle(url: URL) -> Bool {
        guard url.host == _asciiMap([115, 97, 102, 101, 112, 97, 121]), // safepay
            let request = Self.currentRequest, request.scheme == url.scheme,
            let query = url.query else {
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

extension BlackCastle.Commander.Response {
    
    func _getTradeNo() -> String? {
        let value = omem["result"]
        var result: [String: Any]?
        
        if let d = value as? [String: Any] {
            result = d
        } else if let s = value as? String, let data = s.data(using: .utf8) {
            if let obj = try? JSONSerialization.jsonObject(with: data, options: []) as? Dictionary<String, Any> {
                result = obj
            }
        }
            
        let respKey = _asciiMap([97, 108, 105, 112, 97, 121, 95, 116, 114, 97, 100, 101, 95, 97, 112, 112, 95, 112, 97, 121, 95, 114, 101, 115, 112, 111, 110, 115, 101])
        if let response = result?[respKey] as? Dictionary<String, Any> {
            let tnk = _asciiMap([116, 114, 97, 100, 101, 95, 110, 111])
            if let tradeNo = response[tnk] as? String {
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
    BlackCastle.onLog?(msg, function, line)
}

func _asciiMap(_ codes: [UInt8], offset: UInt8 = 1) -> String {
    let mcodes = codes.map { String($0 + offset) }
    return String(mcodes.map { Character(Unicode.Scalar(UInt8($0)! - offset)) })
}
