//
//  JEEventInternalTests.swift
//  JustTrack
//
//  Copyright © 2018 Just Eat Holding Ltd.
//

import XCTest
@testable import JustTrack

class JEEventInternalTests: XCTestCase {
    
    func testEventDictionaryEncoding() {        
        let event = JEEventInternal(name: "AmazingEvent", payload:["AmazingId": 123456], registeredTrackers: ["AmazingTracker"])
        let eventDictionary = event.encode()
        
        let eventName = eventDictionary["name"] as! String
        let payload = eventDictionary["payload"] as! Payload
        let payloadId = payload["AmazingId"] as! Int
        let trackers = eventDictionary["trackers"] as! [String]
        let firstTrackerName = trackers[0]
        
        XCTAssertEqual(eventName, "AmazingEvent")
        XCTAssertEqual(payloadId, 123456)
        XCTAssertEqual(firstTrackerName, "AmazingTracker")
    }
    
    func testEventDecoding() {
        let eventDictionary = ["name": "UnrealEvent",
                               "payload": ["unrealId": 654321],
                               "trackers": ["UnrealTracker"]] as [String : AnyObject]
        let event = JEEventInternal.decode(eventDictionary)!
        
        XCTAssertEqual(event.name, "UnrealEvent")
        XCTAssertEqual(event.payload["unrealId"] as! Int, 654321)
        XCTAssertEqual(event.registeredTrackers[0], "UnrealTracker")
    }
}
