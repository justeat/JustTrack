//
//  JustTrack
//
//  Copyright © 2017 Just Eat Holding Ltd.
//

import Foundation

class EventInternal: NSObject, Event {
    var name: String = ""
    var payload: Payload = [:]
    var registeredTrackers: [String] = []
    
    static func decode(_ dictionary: [String : Any]) -> EventInternal? {
        return EventInternal(name: dictionary[EventEncodingKey.name.rawValue] as! String,
                               payload: dictionary[EventEncodingKey.payload.rawValue] as! Payload,
                               registeredTrackers: dictionary[EventEncodingKey.trackers.rawValue] as! [String])
    }
    
    init(name:String, payload:Payload, registeredTrackers:[String]) {
        super.init()
        self.name = name
        self.payload = payload
        self.registeredTrackers = registeredTrackers
    }
}
