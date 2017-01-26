/// Todo: Docs and OS License(Joakim L.)

import Foundation

@objc
class JETrackerConsole: NSObject, JETracker {
    
    var name: String
    
    required init(configuration: Configuration?) {
        self.name = "console"
    }
    
    func trackEvent(_ name: String, payload: Payload, completion: (_ success: Bool) -> Void) {
         print("[\(self.name)] ☞ Event: \(name) \(payload)")
        completion(true)
    }
}
