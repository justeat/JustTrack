//
//  TestEvents.swift
//  JustTrack
//
//  Copyright © 2017 Just Eat Holding Ltd.
//

import Foundation
import JustTrack

final class JEEventExample: NSObject, JEEvent {
    
    //JEEvent protocol
    public let name: String = "example"
    
    public var payload: Payload {
        return [kTest1 : test1 as NSObject, kTest2 : test2 as NSObject, kTest3 : test3 as NSObject]
    }
    
    public private(set) var registeredTrackers: [String]
    
    //keys
    private let kTest1 = "test1"
    private let kTest2 = "test2"
    private let kTest3 = "test3"
    
    var test1: String = ""
    var test2: String = ""
    var test3: String = ""
    
    public init(test1: String, test2: String, test3: String) {
        self.test1 = test1
        self.test2 = test2
        self.test3 = test3
        self.registeredTrackers = []
        super.init()
    }
    
    public init(trackers: String...) {
        self.registeredTrackers = trackers
        super.init()
    }
}

final class JEEventInvalidExample: NSObject, JEEvent {
    
    //JEEvent protocol
    public let name: String = ""
    
    public var payload: Payload {
        return [:]
    }
    
    public var registeredTrackers: [String] = []
    
    //keys
    private let kTest1 = "test1"
    private let kTest2 = "test2"
    private let kTest3 = "test3"
    
    var test1: String = ""
    var test2: String = ""
    var test3: String = ""
    
    public override init() {
        super.init()
    }
}

