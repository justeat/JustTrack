//
//  JustTrack
//
//  Copyright © 2017 Just Eat Holding Ltd.
//

import Foundation

class TrackerConsole: NSObject, EventTracker {
    
    // MARK: - Tracker protocol implementation
    
    let name = "console"
    
    func trackEvent(_ name: String, payload: Payload, completion: (_ success: Bool) -> Void) {
        print("[\(self.name)] ☞ Event: \(name) \(payload)")
        completion(true)
    }
}
