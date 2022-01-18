//
//  JustTrack
//
//  Copyright © 2017 Just Eat Holding Ltd.
//

import Foundation

struct EventInternal: Event {
    let name: String
    let payload: Payload
    let registeredTrackers: [String]

    init(name: String, payload: Payload, registeredTrackers: [String]) {
        self.name = name
        self.payload = payload
        self.registeredTrackers = registeredTrackers
    }

    init?(dictionary: [String: Any]) {
        guard let name = dictionary[EventEncodingKey.name.rawValue] as? String,
              let payload = dictionary[EventEncodingKey.payload.rawValue] as? Payload,
              let registeredTrackers = dictionary[EventEncodingKey.trackers.rawValue] as? [String] else {
            return nil
        }
        self.init(name: name,
                  payload: payload,
                  registeredTrackers: registeredTrackers)
    }
}
