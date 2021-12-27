//
//  JustTrack
//
//  Copyright © 2017 Just Eat Holding Ltd.
//

import Foundation

final class TrackOperation: Operation {

    // MARK: - Variables

    private let event: Event
    private let tracker: EventTracker
    private let eventKey: String
    private let dataStorage: DataStorable

    // MARK: - Initialization

    init(tracker: EventTracker,
         event: Event,
         dataStorage: DataStorable) {
        self.event = event
        self.tracker = tracker
        self.dataStorage = dataStorage
        eventKey = "\(event.name)_ON_\(tracker.name)_\(Date().timeIntervalSince1970)"
        super.init()
    }

    // MARK: - Operation lifecycle

    override func main() {
        guard !isCancelled else {
            return
        }

        // Persist the event.
        // Delete it before posting if the operation was cancelled while persisting the event.
        save(event, forKey: eventKey)
        guard !isCancelled else {
            deleteEvent(forKey: eventKey)
            return
        }

        if tracker.trackEvent(event.name, payload: event.payload) {
            deleteEvent(forKey: eventKey) // Event was posted, it's safe to remove.
        }
    }
}

// MARK: - Persistence

extension TrackOperation {
    private func save(_ event: Event, forKey key: String) {
        let serializedEvent = event.encode()
        save(serializedEvent, forKey: key)
    }

    private func save(_ eventDictionary: [String: Any], forKey key: String) {
        let operations: NSMutableDictionary
        if let outData: Data = dataStorage.value(forKey: EventTracking.kPersistentStorageName),
           let dataDictionary = NSKeyedUnarchiver.unarchiveObject(with: outData) as? [AnyHashable: Any] {
            operations = NSMutableDictionary(dictionary: dataDictionary)
        } else {
            operations = NSMutableDictionary()
        }

        operations.setObject(eventDictionary, forKey: key as NSCopying)
        let data = NSKeyedArchiver.archivedData(withRootObject: operations)
        dataStorage.setValue(data, forKey: EventTracking.kPersistentStorageName)
    }

    private func deleteEvent(forKey key: String) {
        if let outData: Data = dataStorage.value(forKey: EventTracking.kPersistentStorageName) {
            guard let dataDictionary = NSKeyedUnarchiver.unarchiveObject(with: outData) as? [AnyHashable: Any] else {
                return
            }
            let operations = NSMutableDictionary(dictionary: dataDictionary)
            operations.removeObject(forKey: key)
            let data = NSKeyedArchiver.archivedData(withRootObject: operations)
            dataStorage.setValue(data, forKey: EventTracking.kPersistentStorageName)
        }
    }
}
