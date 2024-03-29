//
//  ViewController.swift
//  JustTrack_Example
//
//  Copyright © 2017 JUST EAT. All rights reserved.
//

import UIKit
import JustTrack

final class ViewController: UIViewController {
    private let eventTracker: EventTracking = {
        let eventTracker = EventTracking(deliveryType: .batch(dispatchInterval: 3.0))
        eventTracker.logClosure = { (logString: String, logLevel: TrackingLogLevel) in
            print("[EventTracker] [\(logLevel)] \(logString)")
        }
        eventTracker.loadDefaultTracker(.consoleLogger)
        eventTracker.enable()
        return eventTracker
    }()

    @IBAction func fireEventsHandler(sender: UIButton?) {
        eventTracker.trackEvent(EventUser(action: "UserLogIn",
                                          response: "success",
                                          extra: "Additional info"))
        eventTracker.trackEvent(EventViewScreen(screenName: "MainView",
                                                screenData: "fake screendata",
                                                screenDataVar: "fake screendata",
                                                screenDataVarSetting: "fake screendata"))
        eventTracker.trackEvent(EventViewScreen(screenName: "RestaurantView",
                                                screenData: "fake screendata",
                                                screenDataVar: "fake screendata",
                                                screenDataVarSetting: "fake screendata"))
        eventTracker.trackEvent(EventViewScreen(screenName: "MenuView",
                                                screenData: "fake screendata",
                                                screenDataVar: "fake screendata",
                                                screenDataVarSetting: "fake screendata"))
        eventTracker.trackEvent(EventNoPayload())
    }
}
