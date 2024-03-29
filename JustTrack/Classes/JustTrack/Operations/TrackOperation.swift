//
//  JustTrack
//
//  Copyright © 2017 Just Eat Holding Ltd.
//

import Foundation

final class TrackOperation: Operation {

    // MARK: - Variables
    
    let event: Event
    let tracker: EventTracker
    private var eventKey: String

    // MARK: - Initialization
    
    init(tracker: EventTracker, event: Event) {
        self.event = event
        self.tracker = tracker
        eventKey = "\(event.name)_ON_\(tracker.name)_\(Date().timeIntervalSince1970)"
        super.init()
        
        // Persist the event.
        saveEvent(event, key: eventKey)
    }
    
    // MARK: - Operation lifecycle
    
    override func main() {
        // Delete it before posting if the operation was cancelled while persisting the event.
        guard !isCancelled else {
            deleteEvent(eventKey)
            return
        }
        
        let eventName = event.name
        let eventPayload = event.payload
        if tracker.trackEvent(eventName, payload: eventPayload) {
            deleteEvent(eventKey) // Event was posted, it's safe to remove.
        }
    }
}

// MARK: - Persistence

extension TrackOperation {

    private func saveEvent(_ event: Event, key: String) {
        let serializedEvent = event.encode()
        saveEventDictionary(serializedEvent, key: key)
    }

    private func saveEventDictionary(_ eventDictionary: [String: Any], key: String) {

        var operations: NSMutableDictionary
        if let outData = UserDefaults.standard.data(forKey: EventTracking.kPersistentStorageName) {
            if let dataDictionary = NSKeyedUnarchiver.unarchiveObject(with: outData) as? [AnyHashable: Any] {
                operations = NSMutableDictionary(dictionary: dataDictionary)
            } else {
                operations = NSMutableDictionary()
            }
        } else {
            operations = NSMutableDictionary()
        }
        
        operations.setObject(eventDictionary, forKey: key as NSCopying)
        let data = NSKeyedArchiver.archivedData(withRootObject: operations)
        UserDefaults.standard.set(data, forKey: EventTracking.kPersistentStorageName)
    }

    private func deleteEvent(_ key: String) {

        if let outData = UserDefaults.standard.data(forKey: EventTracking.kPersistentStorageName) {
            guard let dataDictionary = NSKeyedUnarchiver.unarchiveObject(with: outData) as? [AnyHashable: Any] else {
                return
            }
            let operations = NSMutableDictionary(dictionary: dataDictionary)
            operations.removeObject(forKey: key)
            let data = NSKeyedArchiver.archivedData(withRootObject: operations)
            UserDefaults.standard.set(data, forKey: EventTracking.kPersistentStorageName)
        }
    }
}
