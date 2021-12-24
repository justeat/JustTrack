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
        [EventEncodingKey.payload.rawValue: payload,
         EventEncodingKey.name.rawValue: name,
         EventEncodingKey.trackers.rawValue: registeredTrackers]
    }
}
