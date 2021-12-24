//
//  TestEvents.swift
//  JustTrack
//
//  Copyright © 2017 Just Eat Holding Ltd.
//

import Foundation
import JustTrack

final class ExampleEvent: Event {
    
    // Event protocol
    public let name = "example"
    public var payload: Payload {
        return [kTest1: test1,
                kTest2: test2,
                kTest3: test3]
    }
    
    public private(set) var registeredTrackers: [String]
    
    // Keys
    private let kTest1 = "test1"
    private let kTest2 = "test2"
    private let kTest3 = "test3"
    
    
    var test1 = ""
    var test2 = ""
    var test3 = ""
    public init(test1: String, test2: String, test3: String) {
        self.test1 = test1
        self.test2 = test2
        self.test3 = test3
        registeredTrackers = []
    }
    
    public init(trackers: String...) {
        registeredTrackers = trackers
    }
}

final class InvalidEventExample: Event {

    // Event protocol
    public let name = ""

    public var payload: Payload {
        return [:]
    }
    
    public var registeredTrackers: [String] = []
    
    // Keys
    private let kTest1 = "test1"
    private let kTest2 = "test2"
    private let kTest3 = "test3"

    var test1 = ""
    var test2 = ""
    var test3 = ""
}
