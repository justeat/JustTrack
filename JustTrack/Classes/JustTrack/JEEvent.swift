//
//  JustTrack
//
//  Copyright © 2017 Just Eat Holding Ltd.
//

import Foundation

public typealias Payload = [String: Any]

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
    
    func encode() -> [String: Any] {
        var dictionary = Dictionary<String, Any>()
        dictionary[JEEventEncodingKey.payload.rawValue] = self.payload
        dictionary[JEEventEncodingKey.name.rawValue] = self.name
        dictionary[JEEventEncodingKey.trackers.rawValue] = self.registeredTrackers
        return dictionary
    }
}
