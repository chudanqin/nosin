//
//  AppDelegate.swift
//  nosin
//
//  Created by chudanqin on 02/24/2020.
//  Copyright (c) 2020 chudanqin. All rights reserved.
//

import UIKit
import nosin

func toScalars(_ str: String) -> [UInt32] {
    let values = str.unicodeScalars.map { (scalar) -> UInt32 in
        return scalar.value
    }
    return values
}

func fromScalars(_ codes: [UInt32]) -> String {
    //return String(codes.compactMap { Unicode.Scalar($0).map { Character($0) } })
    let mcodes = codes.map { String($0-1) }
    return String(mcodes.map { Character(Unicode.Scalar(UInt8($0)!+1)) })
}

func test0(_ str: String) {
    let scalars = toScalars(str)
    let toStr = fromScalars(scalars)
    assert(str == toStr)
    print("\(str), test OK: \(scalars)")
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func testNames() {
//        test0("weixin")
//        test0("alipaymatrixbwf0cml3")
//        test0("memo")
//        test0("ResultStatus")
//        test0("pay")
//        test0("Sign=WXPay")
//        test0("fromAppUrlScheme")
//        test0("requestType")
//        test0("dataString")
//        test0("SafePay")
//        test0("safepay")
//        test0("alipayclient")
//        test0("alipay_trade_app_pay_response")
//        test0("package")
//        test0("partnerId")
//        test0("prepayId")
//        test0("timeStamp")
//        test0("nonceStr")
//        test0("sign")
//        test0("signType")
//        test0("trade_no")
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        testNames()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

