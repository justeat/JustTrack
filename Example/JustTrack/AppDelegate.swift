//
//  AppDelegate.swift
//  JustTrack
//
//  Copyright © 2017 Just Eat Holding Ltd.
//

import UIKit
import JustTrack

@UIApplicationMain class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let trackingService: JETracking = configureJustTrack()
        trackingService.trackEvent(JEEventUser(action: "UseLogiIn", response: "success", extra: "Additional info"))
        trackingService.trackEvent(JEEventViewScreen(screenName: "MainView", screenData: "fake screendata"))
        trackingService.trackEvent(JEEventViewScreen(screenName: "RestaurantView", screenData: "fake screendata"))
        trackingService.trackEvent(JEEventViewScreen(screenName: "MenuView", screenData: "fake screendata"))
        trackingService.trackEvent(JEEventNoPayload())
        return true
    }

    func  configureJustTrack() -> JETracking {
        let jeTracker: JETracking = JETracking.sharedInstance
        jeTracker.deliveryType = .batch
        jeTracker.logClosure = { (logString: String, logLevel: JETrackingLogLevel) -> Void in
            print("[JEEventTracker] [\(logLevel.rawValue)] \(logString)")
        }
        jeTracker.loadDefaultTracker(.consoleLogger)
        jeTracker.enable()
        return jeTracker
    }
}

