// PayLink.swift Created by danqin chu on 2020/02/24

public protocol PayLinkable {
    func asURL() -> URL?
}

public struct PayLink {
    
    public enum OpenResult: Int {
        public typealias RawValue = Int
        case successful
        case badURLFormat
        case failed
    }
    
    public struct WeChat {
        public static let name: String = "weixin"
        public static var appId: String = ""
        public static var partnerId: String = ""
        public var prepayId: String
        public var package: String
        public var nonceStr: String
        public var timeStamp: String
        public var sign: String
        public var signType: String = "SHA1" // default SHA1
        
        static func config(appId: String, partnerId: String) {
            self.appId = appId
            self.partnerId = partnerId
        }
    }
    
    public struct Alipay {
        public static let name: String = "alipay"
    }
    
}

// MARK: - Open
public extension PayLink {
    
    private static func canOpen(scheme: String) -> Bool {
        if let url = URL(string: "\(scheme)://") {
            let b = UIApplication.shared.canOpenURL(url)
            return b
        }
        return false
    }
    
    static var isWeChatPayAvailable: Bool {
        return canOpen(scheme: WeChat.name)
    }
    
    static var isAlipayAvailable: Bool {
        return canOpen(scheme: Alipay.name)
    }
    
    static func open(pay: PayLinkable, completion: ((OpenResult) -> Void)?) {
        guard let url = pay.asURL() else {
            completion?(.badURLFormat)
            return
        }
        if #available(iOS 10.0, *) {
            let block: ((Bool) -> Void)? = completion == nil ? nil : { (ok) in
                completion!(ok ? .successful : .failed)
            }
            UIApplication.shared.open(url, options: [:], completionHandler: block)
        } else {
            completion?(UIApplication.shared.openURL(url) ? .successful : .failed)
        }
    }
    
}

private extension String {
    var ns_qes: String? {
        return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
}

extension PayLink.WeChat: PayLinkable {
    
    /**
     weixin://app/wxe2b79b555bcfebcd/pay/?nonceStr=1578645444206&package=Sign%3DWXPay&partnerId=12345&prepayId=wx54321&timeStamp=1578645444&sign=ABCDE&signType=SHA1
     */
    
    public func asURL() -> URL? {
        var uc = URLComponents()
        uc.scheme = Self.name
        uc.host = "app"
        uc.path = "/\(Self.appId)/pay/"
        
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "package", value: "Sign=WXPay".ns_qes))
        queryItems.append(URLQueryItem(name: "partnerId", value: Self.partnerId))
        queryItems.append(URLQueryItem(name: "prepayId", value: prepayId.ns_qes))
        queryItems.append(URLQueryItem(name: "nonceStr", value: nonceStr)) // 随机串，防止重发
        queryItems.append(URLQueryItem(name: "timeStamp", value: timeStamp)) // 防止重发
        uc.queryItems = queryItems.sorted { $0.name < $1.name }
        queryItems.append(URLQueryItem(name: "sign", value: sign))
        queryItems.append(URLQueryItem(name: "signType", value: signType))
        
        return uc.url
    }
    
}

