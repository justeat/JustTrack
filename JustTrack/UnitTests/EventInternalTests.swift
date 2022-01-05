//
//  EventInternalTests.swift
//  JustTrack
//
//  Copyright © 2018 Just Eat Holding Ltd.
//

import XCTest
@testable import JustTrack

class EventInternalTests: XCTestCase {
    
    func testEventDictionaryEncoding() {
        let event = EventInternal(name: "AmazingEvent", payload: ["AmazingId": 123456], registeredTrackers: ["AmazingTracker"])
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
    
    func testEventDictionaryEncodingWithArrayOfItems() {
        struct Items: Equatable {
            public var itemName = ""
            public var itemNumber = 0
            public var itemDouble = 0.0
            public var itemBool = false
            
            public init(itemName: String,
                        itemNumber: Int,
                        itemDouble: Double,
                        itemBool: Bool) {
                self.itemName = itemName
                self.itemNumber = itemNumber
                self.itemDouble = itemDouble
                self.itemBool = itemBool
            }
        }
        
        let event = EventInternal(name: "AmazingEvent",
                                  payload: ["AmazingId": 123456, "arrayOfItems": [Items]()],
                                  registeredTrackers: ["AmazingTracker"])
        let eventDictionary = event.encode()
        
        let eventName = eventDictionary["name"] as! String
        let payload = eventDictionary["payload"] as! Payload
        let payloadId = payload["AmazingId"] as! Int
        let arrayOfItems = payload["arrayOfItems"] as! [Items]
        let trackers = eventDictionary["trackers"] as! [String]
        let firstTrackerName = trackers[0]
        
        XCTAssertEqual(eventName, "AmazingEvent")
        XCTAssertEqual(payloadId, 123456)
        XCTAssertEqual(arrayOfItems, [Items]())
        XCTAssertEqual(firstTrackerName, "AmazingTracker")
    }
    
    func testEventDecoding() {
        let eventDictionary = ["name": "UnrealEvent",
                               "payload": ["unrealId": 654321],
                               "trackers": ["UnrealTracker"]] as [String: AnyObject]
        let event = EventInternal.decode(eventDictionary)!
        
        XCTAssertEqual(event.name, "UnrealEvent")
        XCTAssertEqual(event.payload["unrealId"] as! Int, 654321)
        XCTAssertEqual(event.registeredTrackers[0], "UnrealTracker")
    }
}
