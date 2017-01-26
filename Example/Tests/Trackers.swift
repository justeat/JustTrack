//
//  Trackers.swift
//  JustTrack
//
//  Copyright © 2017 Just Eat Holding Ltd.
//

import Foundation
import JustTrack

final class MockTracker: NSObject, JETracker {
    let name: String
    var didTrackEvent = false
    
    public init(configuration: Configuration?) {
        self.name = "MockTracker"
    }
    open func trackEvent(_ name: String, payload: Payload, completion: (_ success: Bool) -> Void) {
        didTrackEvent = true
        completion(true)
    }
}

final class SomeOtherMockTracker: NSObject, JETracker {
    let name: String
    var didTrackEvent = false
    
    public init(configuration: Configuration?) {
        self.name = "SomeOtherMockTracker"
    }
    open func trackEvent(_ name: String, payload: Payload, completion: (_ success: Bool) -> Void) {
        didTrackEvent = true
        completion(true)
    }
}

