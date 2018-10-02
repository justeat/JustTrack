//
//  MockTrackers.swift
//  JustTrack
//
//  Copyright © 2017 Just Eat Holding Ltd.
//

import Foundation
import JustTrack

final class MockTracker: NSObject, JETracker {
    let name =  "MockTracker"
    var didTrackEvent = false
    
    open func trackEvent(_ name: String, payload: Payload, completion: (_ success: Bool) -> Void) {
        didTrackEvent = true
        completion(true)
    }
}

final class SomeOtherMockTracker: NSObject, JETracker {
    let name = "SomeOtherMockTracker"
    var didTrackEvent = false
    
    open func trackEvent(_ name: String, payload: Payload, completion: (_ success: Bool) -> Void) {
        didTrackEvent = true
        completion(true)
    }
}

