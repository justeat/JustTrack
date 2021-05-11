//
//  JustTrack
//
//  Copyright © 2017 Just Eat Holding Ltd.
//

import Foundation

public typealias Payload = [String: Any]

public enum EventEncodingKey: String {
    case name
    case payload
    case trackers
}

public protocol Event {
    var name: String { get }
    var payload: Payload { get }
    var registeredTrackers: [String] { get }
}

extension Event {
    
    func encode() -> [String: Any] {
        var dictionary = Dictionary<String, Any>()
        dictionary[EventEncodingKey.payload.rawValue] = self.payload
        dictionary[EventEncodingKey.name.rawValue] = self.name
        dictionary[EventEncodingKey.trackers.rawValue] = self.registeredTrackers
        return dictionary
    }
}
