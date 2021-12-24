//
//  JustTrack
//
//  Copyright © 2017 Just Eat Holding Ltd.
//

import Foundation

class TrackerConsole: EventTracker {
    
    // MARK: - Tracker protocol implementation
    
    let name = "console"
    
    func trackEvent(_ name: String, payload: Payload) -> Bool {
        print("[\(self.name)] ☞ Event: \(name) \(payload)")
        return true
    }
}
