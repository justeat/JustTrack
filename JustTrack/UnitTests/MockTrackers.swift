//
//  MockTrackers.swift
//  JustTrack
//
//  Copyright © 2017 Just Eat Holding Ltd.
//

import Foundation
import JustTrack
import XCTest

final class MockTracker: NSObject, JETracker {
    let name =  "MockTracker"
    var didTrackExpectation: XCTestExpectation?
    var trackEventInvocationCount = 0
    
    public func trackEvent(_ name: String, payload: Payload, completion: (_ success: Bool) -> Void) {
        didTrackExpectation?.fulfill()
        trackEventInvocationCount += 1
        completion(true)
    }
}

final class SomeOtherMockTracker: NSObject, JETracker {
    let name = "SomeOtherMockTracker"
    var didTrackExpectation: XCTestExpectation?
    var trackEventInvocationCount = 0
    
    public func trackEvent(_ name: String, payload: Payload, completion: (_ success: Bool) -> Void) {
        didTrackExpectation?.fulfill()
        trackEventInvocationCount += 1
        completion(true)
    }
}

