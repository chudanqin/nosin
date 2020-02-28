// PayLink.swift Created by danqin chu on 2020/02/24

public struct PayLink {
    
    public enum OpenStatus: Int {
        case success
        case failure
        case badParameter
    }
    
    public struct WeChat {
        
        public static let name: String = "weixin"
        
        public static var appId: String?
        
        public struct Response {
            
            public enum Code: Int {
                case success = 0 // 0 OK
                case commonError = -1 // -1 Common error
                case userCancelled = -2 // -2 Cancelled by user
                case sentError = -3 // -3 Sent error
                case authDenied = -4 // -4 Auth denied
                case unsupported = -5 // -5 Unsupported
            }
            
            public let rawCode: Int
            
            public var code: Self.Code? {
                return Self.Code(rawValue: rawCode)
            }
            
            public var isSuccessful: Bool {
                return rawCode == 0
            }
            
        }
        
        struct Request {
            var appId: String
            var urlComponents: URLComponents
            var callback: (WeChat.Response) -> Void
        }
        
        static var currentRequest: WeChat.Request?
        
    }
    
    public struct Alipay {
        
        public static let name: String = "alipaymatrixbwf0cml3" // alipay is OK too
        public static var clientScheme: String?
        
        public struct Response {
            
            public enum Code: Int {
                case success = 9000
                case userCancelled = 6001
            }
            
            public let info: [String: Any]
            
            public var memo: [String: Any] {
                return info["memo"] as? [String: Any] ?? [:]
            }
            
            public var rawCode: Int? {
                guard let rs = memo["ResultStatus"] else {
                    return nil
                }
                if let strCode = rs as? String {
                    return Int(strCode)
                }
                return rs as? Int
            }
            
            public var code: Self.Code? {
                return rawCode.flatMap { Self.Code(rawValue: $0) }
            }
            
            public var isSuccessful: Bool {
                return code == .success
            }
            
            public var tradeNo: String? {
                return _getTradeNo()
            }
            
        }
        
        struct Request {
            var order: String
            var scheme: String
            var callback: (Response) -> Void
        }
        
        static var currentRequest: Alipay.Request?
        
    }
    
    public static var onLog: ((String, String, Int) -> Void)? = { (msg, function, line) in
        print("\(function)+\(line): \(msg)")
    }
    
}

// MARK: - WeChatPay Public API
public extension PayLink.WeChat {
    
    static var isAvailable: Bool {
        return PayLink.canOpen(scheme: name)
    }
    
    /**
     * default signType is SHA1
     */
    static func open(with appId: String?,
                     partnerId: String,
                     prepayId: String,
                     nonceStr: String,
                     timeStamp: String,
                     sign: String,
                     signType: String?,
                     onOpen: ((PayLink.OpenStatus) -> Void)?,
                     onCallback: @escaping (Self.Response) -> Void)
    {
        let aid: String = appId ?? Self.appId ?? ""
        assert(aid.count > 0, "app id not set")
        
        let uc = Self._generateURL(with: aid, partnerId: partnerId, prepayId: prepayId, nonceStr: nonceStr, timeStamp: timeStamp, sign: sign, signType: signType ?? "SHA1")
        
        guard let url = uc.url else {
            onOpen?(.badParameter)
            _log("bad URL format")
            return
        }
        
        Self.currentRequest = Self.Request(appId: aid, urlComponents: uc, callback: onCallback)
        PayLink.open(url: url, completion: onOpen)
    }
    
    static func handleCallback(url: URL) -> Bool {
        return _handle(url: url)
    }
    
}

// MARK: - Alipay Public API

public extension PayLink.Alipay {
    
    static var isAvailable: Bool {
        return PayLink.canOpen(scheme: Self.name)
    }
    
    static func open(from scheme: String?,
                     order: String,
                     onOpen: ((PayLink.OpenStatus) -> Void)?,
                     onCallback: @escaping (Self.Response) -> Void) {
        let clientScheme = scheme ?? Self.clientScheme ?? ""
        assert(clientScheme.count > 0, "app id not set")
        
        guard let uc = Self._generateURL(with: clientScheme, order: order) else {
            onOpen?(.badParameter)
            _log("bad JSON format")
            return
        }
        
        guard let url = uc.url else {
            onOpen?(.badParameter)
            _log("bad URL format")
            return
        }
        
        Self.currentRequest = Self.Request(order: order, scheme: clientScheme, callback: onCallback)
        PayLink.open(url: url, completion: onOpen)
    }
    
    static func handleCallback(url: URL) -> Bool {
        return _handle(url: url)
    }
    
}
