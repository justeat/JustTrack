//
//  ViewController.swift
//  JustTrack_Example
//
//  Created by Federico Cappelli on 13/11/2017.
//  Copyright © 2017 JUST EAT. All rights reserved.
//

import UIKit
import JustTrack

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func fireEventsHandler(sender: UIButton?) {
        
        let trackingService: JETracking = configureJustTrack()
        
        trackingService.trackEvent(JEEventUser(action: "UserLogIn", response: "success", extra: "Additional info"))
        trackingService.trackEvent(JEEventViewScreen(screenName: "MainView", screenData: "fake screendata"))
        trackingService.trackEvent(JEEventViewScreen(screenName: "RestaurantView", screenData: "fake screendata"))
        trackingService.trackEvent(JEEventViewScreen(screenName: "MenuView", screenData: "fake screendata"))
        trackingService.trackEvent(JEEventNoPayload())
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
