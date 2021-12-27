//
//  JustTrack
//
//  Copyright © 2017 Just Eat Holding Ltd.
//

import Foundation

/// Tracking manages the mapping and dispatching of events to trackers.
/// - TODO: More elaborate documentation for this with example usage.
public final class EventTracking {

    // MARK: - Internal Properties
    
    static let kPersistentStorageName = "com.justeat.TrackOperations"
    
    // MARK: - API

    /// An optional closure that can be set for debugging purposes.
    /// JustTrack will call this closure when there is something worth mentioning / logging.
    ///
    /// For example, you could use:
    /// ````
    /// myTrackingService.logger = { (level: TrackingLogLevel, message: String) -> Void in
    ///        print("[TrackingService] [\(level)] \(message)")
    /// }
    /// ````
    /// to output the type of the message (log level) and associated string to the console.
    /// Or you could use the closure to log to your logging framework of choice etc.
    public var logger: ((_ level: TrackingLogLevel, _ message: String) -> Void)?

    /// The delivery type used for pushing events to trackers.
    ///
    /// Default value is `immediate`.
    ///
    /// - seealso: `TrackingDeliveryType`.
    public let deliveryType: TrackingDeliveryType
    private let dataStorage: DataStorable

    public init(dataStorage: DataStorable,
                deliveryType: TrackingDeliveryType = .immediate) {
        self.deliveryType = deliveryType
        self.dataStorage = dataStorage
    }

    /// Registers a `TrackerConsole` for event tracking.
    /// Helpful for debugging purposes, as it will cause all events to be logged on the console.
    ///
    /// - seealso: `TrackerConsole`.
    @discardableResult
    public func loadDefaultTracker(_ type: TrackerType) -> Bool {
        
        var tracker: EventTracker?
        
        switch type {
        case .consoleLogger:
            tracker = TrackerConsole()
        }

        guard let tracker = tracker else {
            return false
        }
        loadCustomTracker(tracker)
        return true
    }
    
    /// Validates the passed event and schedules it for posting
    /// with its associated `registeredTrackers`.
    ///
    /// - parameter event: The event to be tracked.
    ///
    /// - Remark: For an event to be considered valid it **MUST**:
    ///     1. have a non-empty name
    ///     2. have at least one registered tracker (otherwise there's noone there to track it)
    ///
    /// - seealso: `Event`
    @discardableResult
    public func trackEvent(_ event: Event) -> Bool {
        // TODO: validate event
        guard event.isValid else {
            log(level: .error, message: "Invalid event \(event)")
            return false
        }
                
        // Send the event to any registered tracker
        for trackerName in event.registeredTrackers {
            if let tracker = trackersInstances[trackerName.lowercased()] {
                // Enqueue
                let operation = TrackOperation(tracker: tracker,
                                               event: event,
                                               dataStorage: dataStorage)

                // TODO: This conditional is sketchy, if the app dies while the queue is paused, we're going to lose the events.
                // Need to rethink the policy here and / or cap the dispatch time to a sensible max value.
                if case let .batch(dispatchInterval) = deliveryType, operationQueue.operationCount == 0 {
                    pauseQueue(Int64(dispatchInterval * Double(NSEC_PER_SEC)))
                }
                
                operationQueue.addOperation(operation)
            } else {
                log(level: .error,
                    message: "Trying to track an event (\"\(event.name)\") in an invalid Tracker (\"\(trackerName)\")")
            }
        }
        
        return true
    }
    
    public func enable() {
        
        if trackersInstances.count < 1 {
            // TODO: propagate error
            return
        }

        log(level: .info, message: "Enabling tracker...")

        let restoredEventsCount = restoreUncompletedTracking()
        if restoredEventsCount > 0 {
            log(level: .info, message: "\(restoredEventsCount) events restored")
        }
    }
    
    public func completeAllOperations() {
        if case .batch = deliveryType {
            unpauseQueue()
        }
    }
    
    /// Registers the passed tracker instance for tracking events.
    ///
    /// - parameter tracker: The tracker instance to start tracking events.
    public func loadCustomTracker(_ tracker: EventTracker) {
        trackersInstances[tracker.name.lowercased()] = tracker // Register trackers
    }
    
    // MARK: - Private

    private func log(level: TrackingLogLevel, message: String) {
        logger?(level, message)
    }

    private lazy var trackersInstances: [String: EventTracker] = {
        var dictionary = [String: EventTracker]()
        return dictionary
    }()

    private lazy var operationQueue: OperationQueue = {

        var queue = OperationQueue()
        queue.name = "com.justtrack.trackDispatchQueue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = QualityOfService.background
        
        return queue
    }()

    private func restoreUncompletedTracking() -> Int {
        guard let outData: Data = dataStorage.value(forKey: EventTracking.kPersistentStorageName),
              let dataDictionary = NSKeyedUnarchiver.unarchiveObject(with: outData) as? [AnyHashable: Any] else {
            return 0
        }
        if operations.count > 0 {
            

        let operations = NSMutableDictionary(dictionary: dataDictionary)
            // Remove all the events stored
            dataStorage.setValue(nil, forKey: EventTracking.kPersistentStorageName)
            
            for eventKey: String in operations.allKeys as! [String] {
                    
                // Get uncompleted event tracking
                if let eventDictionary = operations[eventKey] as? [String: AnyObject] {
                    if let internalEvent = EventInternal(dictionary: eventDictionary) {
                        // Enqueue event
                        trackEvent(internalEvent)
                    } else {
                        // TODO: manage error
                    }
                }
            }
        }
        return operations.count
    }

    private func pauseQueue(_ seconds: Int64) {
        operationQueue.isSuspended = true
        let delayTime = DispatchTime.now() + Double(seconds) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            self.operationQueue.isSuspended = false
        }
    }

    private func unpauseQueue() {
        operationQueue.isSuspended = false
    }
}
