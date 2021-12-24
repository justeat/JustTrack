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
        
        let trackingService: EventTracking = configureJustTrack()
        
        trackingService.trackEvent(EventUser(action: "UserLogIn", response: "success", extra: "Additional info"))
        trackingService.trackEvent(EventViewScreen(screenName: "MainView", screenData: "fake screendata", screenDataVar: "fake screendata", screenDataVarSetting: "fake screendata"))
        trackingService.trackEvent(EventViewScreen(screenName: "RestaurantView", screenData: "fake screendata", screenDataVar: "fake screendata", screenDataVarSetting: "fake screendata"))
        trackingService.trackEvent(EventViewScreen(screenName: "MenuView", screenData: "fake screendata", screenDataVar: "fake screendata", screenDataVarSetting: "fake screendata"))
        trackingService.trackEvent(EventNoPayload())
    }
    
    func configureJustTrack() -> EventTracking {
        let eventTracker: EventTracking = EventTracking.sharedInstance
        eventTracker.deliveryType = .batch
        eventTracker.logClosure = { (logString: String, logLevel: TrackingLogLevel) -> Void in
            print("[EventTracker] [\(logLevel)] \(logString)")
        }
        eventTracker.loadDefaultTracker(.consoleLogger)
        eventTracker.enable()
        return eventTracker
    }
}
