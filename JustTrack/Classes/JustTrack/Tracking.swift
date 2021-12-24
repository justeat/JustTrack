//
//  JustTrack
//
//  Copyright © 2017 Just Eat Holding Ltd.
//

import Foundation

/// Log level, based on severity.
///
/// Used by `logClosure` to filter events based on user's needs.
///
/// ````
/// case verbose
/// case debug
/// case info
/// case error
/// ````
///
/// - seealso: `logClosure`
public enum TrackingLogLevel {
    case verbose
    case debug
    case info
    case error
}

/// Tracking delivery type.
///
/// ````
/// case batch
/// case immediate
/// ````
///
/// - seealso: `dispatchInterval`
public enum TrackingDeliveryType {
    /// Will wait before dispatching events to trackers based on `dispatchInterval`.
    case batch
    
    /// Will dispatch events to trackers immediately.
    case immediate
}

/// Tracker type. Used for trackers provided by JustTrack out of the box.
///
/// ````
/// case consoleLogger
/// ````
public enum TrackerType {
    case consoleLogger
}

/// Tracking manages the mapping and dispatching of events to trackers.
/// - TODO: More elaborate documentation for this with example usage.
public class EventTracking {

    // MARK: - Internal Properties
    
    static let kEventTrackerEventsPlistName = "kEventTrackerEventsPlistName"
    static let kPersistentStorageName = "com.justeat.TrackOperations"
    
    // MARK: - API
    
    /// How long we should wait before events get pushed to trackers.
    ///
    /// - Remark: Only applies to the `Batch` delivery type.
    ///           If you've set the delivery type to anything else, this property will be ignored.
    ///
    /// - Requires: `deliveryType` property to be set to `batch`.
    public let dispatchInterval: Double

    /// An optional closure that can be set for debugging purposes.
    /// JustTrack will call this closure when there is something worth mentioning / logging.
    ///
    /// For example, you could use:
    /// ````
    /// myTrackingService.logClosure = { (logString: String, logLevel: TrackingLogLevel) -> Void in
    ///        print("[TrackingService] [\(logLevel)] \(logString)")
    /// }
    /// ````
    /// to output the type of the message (log level) and associated string to the console.
    /// Or you could use the closure to log to your logging framework of choice etc.
    public var logClosure: ((_ logString: String, _ logLevel: TrackingLogLevel) -> Void)?

    /// The delivery type used for pushing events to trackers.
    ///
    /// Default value is `immediate`.
    ///
    /// - seealso: `TrackingDeliveryType`.
    public let deliveryType: TrackingDeliveryType

    public init(dispatchInterval: Double = 3.0,
                deliveryType: TrackingDeliveryType = .immediate) {
        self.dispatchInterval = dispatchInterval
        self.deliveryType = deliveryType
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
        
        // Transform generic event in an internal event
        let internalEvent = EventInternal(name: event.name,
                                          payload: event.payload,
                                          registeredTrackers: event.registeredTrackers)

        // TODO: validate event
        if eventIsValid(internalEvent) == false {
            
            JTLog("Invalid event \(event)", level: .error)
            return false
        }
                
        // Send the event to any registered tracker
        for trackerName in internalEvent.registeredTrackers {
            if let tracker = trackersInstances[trackerName.lowercased()] {
                // Enqueue
                let operation = TrackOperation(tracker: tracker, event: internalEvent)

                // TODO: This conditional is sketchy, if the app dies while the queue is paused, we're going to lose the events.
                // Need to rethink the policy here and / or cap the dispatch time to a sensible max value.
                if deliveryType == .batch, operationQueue.operationCount == 0 {
                    pauseQueue(Int64(dispatchInterval * Double(NSEC_PER_SEC)))
                }
                
                operationQueue.addOperation(operation)
            } else {
                JTLog("Trying to track an event (\"\(event.name)\") in an invalid Tracker (\"\(trackerName)\")", level: .error)
            }
        }
        
        return true
    }
    
    public func enable() {
        
        if trackersInstances.count < 1 {
            // TODO: propagate error
            return
        }
        
        JTLog("Enabling tracker...", level: .info)
        
        let restoredEventsCount = restoreUncompletedTracking()
        if restoredEventsCount > 0 {
            JTLog("\(restoredEventsCount) events restored", level: .info)
        }
    }
    
    public func completeAllOperations() {
        if deliveryType == .batch {
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
    
    fileprivate func eventIsValid(_ event: Event) -> Bool {
        
        return event.name.isEmpty == false && !event.registeredTrackers.isEmpty
    }
    
    fileprivate func JTLog(_ string: String, level: TrackingLogLevel) {
        logClosure?(string, level)
    }

    fileprivate lazy var trackersInstances: [String: EventTracker] = {
        var dictionary = [String: EventTracker]()
        return dictionary
    }()
    
    fileprivate lazy var operationQueue: OperationQueue = {
        
        var queue = OperationQueue()
        queue.name = "com.justtrack.trackDispatchQueue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = QualityOfService.background
        
        return queue
    }()
 
    fileprivate func restoreUncompletedTracking() -> Int {
        
        var operations: NSMutableDictionary
        guard let outData = UserDefaults.standard.data(forKey: EventTracking.kPersistentStorageName),
              let dataDictionary = NSKeyedUnarchiver.unarchiveObject(with: outData) as? [AnyHashable: Any] else {
            return 0
        }
        
        operations = NSMutableDictionary(dictionary: dataDictionary)
        if operations.count > 0 {
            
            // Remove all the events stored
            UserDefaults.standard.set(nil, forKey: EventTracking.kPersistentStorageName)
            
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
    
    fileprivate func pauseQueue(_ seconds: Int64) {
        operationQueue.isSuspended = true
        let delayTime = DispatchTime.now() + Double(seconds) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            self.operationQueue.isSuspended = false
        }
    }
    
    fileprivate func unpauseQueue() {
        operationQueue.isSuspended = false
    }
}
