//
//  JustTrack
//
//  Copyright © 2017 Just Eat Holding Ltd.
//

import Foundation

class JETrackOperation: Operation {
    
    // MARK: - Variables
    
    let event: JEEvent
    let tracker: JETracker
    fileprivate var eventKey: String
    
    // MARK: - Initialization
    
    init(tracker: JETracker, event: JEEvent) {
        self.event = event
        self.tracker = tracker
        self.eventKey = "\(event.name)_ON_\(tracker.name)_\(Date().timeIntervalSince1970)"
        super.init()
    }
    
    // MARK: - Operation lifecycle
    
    override func main() {
        guard !isCancelled else { return }
        
        // Persist the event.
        // Delete it before posting if the operation was cancelled while persisting the event.
        saveEvent(event, key: eventKey)
        guard !isCancelled else {
            deleteEvent(eventKey)
            return
        }
        
        let eventName = event.name
        let eventPayload = event.payload
        tracker.trackEvent(eventName,
                           payload: eventPayload,
                           completion: { (success) in
            if success {
                self.deleteEvent(self.eventKey) // Event was posted, it's safe to remove.
            }
        })
    }
}

// MARK: - Persistence

private extension JETrackOperation {

    func saveEvent(_ event: JEEvent, key: String) {
        guard let serializedEvent = event.encode() as? [String: AnyObject] else { return }
        saveEventDictionary(serializedEvent , key: key)
    }
    
    func saveEventDictionary(_ eventDictionary: [String: AnyObject], key: String) {
        
        var operations: NSMutableDictionary
        if let outData = UserDefaults.standard.data(forKey: JETracking.kPersistentStorageName) {
            if let dataDictionary = NSKeyedUnarchiver.unarchiveObject(with: outData) as? [AnyHashable: Any] {
                operations = NSMutableDictionary(dictionary: dataDictionary)
            }
            else {
                operations = NSMutableDictionary()
            }
        }
        else {
            operations = NSMutableDictionary()
        }
        
        operations.setObject(eventDictionary, forKey: key as NSCopying)
        let data = NSKeyedArchiver.archivedData(withRootObject: operations)
        UserDefaults.standard.set(data, forKey: JETracking.kPersistentStorageName)
        UserDefaults.standard.synchronize()
    }
    
    func deleteEvent(_ key: String) {
        
        var operations: NSMutableDictionary
        if let outData = UserDefaults.standard.data(forKey: JETracking.kPersistentStorageName) {
            guard let dataDictionary = NSKeyedUnarchiver.unarchiveObject(with: outData) as? [AnyHashable: Any] else {
                return
            }
            
            operations = NSMutableDictionary(dictionary: dataDictionary)
            operations.removeObject(forKey: key)
            let data = NSKeyedArchiver.archivedData(withRootObject: operations)
            UserDefaults.standard.set(data, forKey: JETracking.kPersistentStorageName)
            UserDefaults.standard.synchronize()
        }
    }
}
