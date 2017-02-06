//
//  JustTrack
//
//  Copyright © 2017 Just Eat Holding Ltd.
//

import Foundation

class JEEventInternal:NSObject,JEEvent {
    var name: String = ""
    var payload: Payload = [:]
    var registeredTrackers: [String] = []
    
    static func decode(_ dictionary: [String : AnyObject]) -> JEEventInternal? {
        return JEEventInternal(name: dictionary[JEEventEncodingKey.name.rawValue] as! String,
                               payload: dictionary[JEEventEncodingKey.payload.rawValue] as! Payload,
                               registeredTrackers: dictionary[JEEventEncodingKey.trackers.rawValue] as! [String])
    }
    
    init(name:String, payload:Payload, registeredTrackers:[String]) {
        super.init()
        self.name = name
        self.payload = payload
        self.registeredTrackers = registeredTrackers
    }
}
