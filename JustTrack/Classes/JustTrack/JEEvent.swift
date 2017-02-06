//
//  JustTrack
//
//  Copyright © 2017 Just Eat Holding Ltd.
//

import Foundation

public typealias Payload = [String: NSObject]

public enum JEEventEncodingKey: String {
    case name
    case payload
    case trackers
}

@objc public protocol JEEvent {
    var name: String { get }
    var payload: Payload { get }
    var registeredTrackers: [String] { get }
}

extension JEEvent {
    
    func encode() -> [String: AnyObject] {
        var dictionary = Dictionary<String, AnyObject>()
        dictionary[JEEventEncodingKey.payload.rawValue] = self.payload as AnyObject?
        dictionary[JEEventEncodingKey.name.rawValue] = self.name as AnyObject?
        dictionary[JEEventEncodingKey.trackers.rawValue] = self.registeredTrackers as AnyObject?
        return dictionary
    }
}
