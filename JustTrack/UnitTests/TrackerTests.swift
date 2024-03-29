//
//  JustTrack
//
//  Copyright © 2017 Just Eat Holding Ltd.
//

import XCTest
import JustTrack

final class TrackerTests: XCTestCase {

    // MARK: - Stubs / Mocks

    private var trackerService: EventTracking!
    private var tracker1: MockTracker!
    private var tracker2: MockTracker!
    
    // MARK: - Setup

    override func setUp() {
        super.setUp()
        trackerService = EventTracking(deliveryType: .immediate)
        tracker1 = MockTracker(name: "MockTracker")
        tracker2 = MockTracker(name: "SomeOtherMockTracker")
    }
    
    // MARK: - Teardown

    override func tearDown() {
        trackerService.unloadTrackers()
        trackerService = nil
        tracker1 = nil
        tracker2 = nil
        super.tearDown()
    }
    
    // MARK: - Immediate Mode
    
    func testExpectedTrackersAreCalledInImmediateMode() {
        let tracker1EventExpectation = expectation(description: "Event is tracked in IMMEDIATE dispatch mode for tracker1")
        let tracker2EventExpectation = expectation(description: "Event is tracked in IMMEDIATE dispatch mode for tracker2")
        
        // GIVEN an event targeted to two trackers
        let event = ExampleEvent(trackers: tracker1.name, tracker2.name)
        
        // AND a tracker service using these two trackers in "immediate" mode
        trackerService = EventTracking(deliveryType: .immediate)
        trackerService.loadCustomTracker(tracker1)
        trackerService.loadCustomTracker(tracker2)
        
        // WHEN we ask JustTrack to track the event
        tracker1.didTrackExpectation = tracker1EventExpectation
        tracker2.didTrackExpectation = tracker2EventExpectation
        trackerService.trackEvent(event)
                
        // THEN the expected trackers have been asked to "track / post" that event
        wait(for: [tracker1EventExpectation, tracker2EventExpectation], timeout: 4)
    }
    
    // MARK: - BATCH Mode
    
    func testExpectedTrackersAreCalledInBatchMode() {
        let tracker1EventExpectation = expectation(description: "Event is tracked in BATCH dispatch mode for tracker1")
        let tracker2EventExpectation = expectation(description: "Event is tracked in BATCH dispatch mode for tracker2")

        // GIVEN an event targeted to two trackers
        let event = ExampleEvent(trackers: tracker1.name, tracker2.name)
        
        // AND a tracker service using these two trackers that processes events in 2 second "batches"
        trackerService = EventTracking(deliveryType: .batch(dispatchInterval: 2.0))
        trackerService.loadCustomTracker(tracker1)
        trackerService.loadCustomTracker(tracker2)
                
        // WHEN we ask JustTrack to track the event
        tracker1.didTrackExpectation = tracker1EventExpectation
        tracker2.didTrackExpectation = tracker2EventExpectation
        trackerService.trackEvent(event)
        
        // THEN the expected trackers have been asked to "track / post" that event
        wait(for: [tracker1EventExpectation, tracker2EventExpectation], timeout: 5)
    }
    
    func testExpectedTrackersHaveNotBeenCalledBeforeBatchInterval() {
        let eventNotTrackedExpectation = expectation(description: "Event tracking should respect BATCH mode dispatch times.")
        let tracker1EventExpectation = expectation(description: "Event tracking should respect BATCH mode dispatch times for tracker1")
        let tracker2EventExpectation = expectation(description: "Event tracking should respect BATCH mode dispatch times for tracker2")

        // GIVEN an event targeted to two trackers
        let event = ExampleEvent(trackers: tracker1.name, tracker2.name)
        
        // AND a tracker service using these two trackers that processes events in 3 second "batches"
        trackerService = EventTracking(deliveryType: .batch(dispatchInterval: 3.0))
        trackerService.loadCustomTracker(tracker1)
        trackerService.loadCustomTracker(tracker2)
        
        // WHEN we ask JustTrack to track the event
        tracker1?.didTrackExpectation = tracker1EventExpectation
        tracker2?.didTrackExpectation = tracker2EventExpectation
        trackerService.trackEvent(event)
        
        // AND wait for LESS seconds than the batch size for the events to be processed
        // THEN the expected trackers have NOT been asked to "track / post" that event yet
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            XCTAssertEqual(self.tracker1.trackEventInvocationCount, 0)
            XCTAssertEqual(self.tracker2.trackEventInvocationCount, 0)
            eventNotTrackedExpectation.fulfill()
        }
                
        // BUT if we wait for MORE seconds than the batch size for the events to be processed
        // THEN the expected trackers have been asked to "track / post" that event
        wait(for: [tracker1EventExpectation, tracker2EventExpectation], timeout: 5)
        waitForExpectations(timeout: 6, handler: nil)
    }
    
    // MARK: - Event-Tracker Mapping
    
    func testEventsTrackedByTracker() {
        let eventExpectation = expectation(description: "Event should be tracked by the registered tracker.")
        
        // GIVEN an event targeted to one tracker
        let event = ExampleEvent(trackers: tracker1.name)
        event.test1 = "value1"
        event.test2 = "value2"
        event.test3 = "value3"

        trackerService = EventTracking(deliveryType: .immediate)
        trackerService.loadCustomTracker(tracker1)
        trackerService.enable()
        
        // WHEN we ask JustTrack to track the event
        trackerService.trackEvent(event)
        
        // AND wait for the events to be processed
        // THEN ONLY tracker1 has been asked to track the event
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            XCTAssertEqual(self.tracker1.trackEventInvocationCount, 1, "Registered Tracker1 has not been called")
            XCTAssertEqual(self.tracker2.trackEventInvocationCount, 0, "Unregistered Tracker2 has been called, but it should not be called")
            eventExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testEventsAreNotTrackedByNonWantedTrackers() {
        let eventExpectation = expectation(description: "Event should only be tracked by the expected trackers.")
        
        // GIVEN an event targeted to one tracker
        let event = ExampleEvent(trackers: tracker1.name)
        event.test1 = "value1"
        event.test2 = "value2"
        event.test3 = "value3"
        
        // AND a tracker service using two trackers
        trackerService = EventTracking(deliveryType: .immediate)
        trackerService.loadCustomTracker(tracker1)
        trackerService.loadCustomTracker(tracker2)
        trackerService.enable()
        
        // WHEN we ask JustTrack to track the event
        trackerService.trackEvent(event)
        
        // AND wait for the events to be processed
        // THEN ONLY tracker1 has been asked to track the event
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            XCTAssertEqual(self.tracker1.trackEventInvocationCount, 1, "Tracker1 has not been called")
            XCTAssertEqual(self.tracker2.trackEventInvocationCount, 0, "Tracker2 has been called, but it should not be called")
            eventExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testTrackersCaseSensitiveNames() {
        let eventExpectation = expectation(description: "Event should not be tracked regardless if the tracker name is capitalised or not")
        
        // GIVEN an event targeted to one tracker
        let event = ExampleEvent(trackers: tracker1.name)
        
        // AND a tracker service using two trackers
        trackerService = EventTracking(deliveryType: .immediate)
        trackerService.loadCustomTracker(tracker1)
        trackerService.loadCustomTracker(tracker2)
        
        // WHEN we ask JustTrack to track the event
        trackerService.trackEvent(event)
        
        // AND wait for a few seconds for the events to be processed
        let intervalToFireExpectationFulfill = 1.0
        // THEN ONLY tracker1 has been asked to track the event
        DispatchQueue.main.asyncAfter(deadline: .now() + intervalToFireExpectationFulfill) {
            XCTAssertEqual(self.tracker1.trackEventInvocationCount, 1)
            XCTAssertEqual(self.tracker2.trackEventInvocationCount, 0)
            eventExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    // MARK: - Invalid Event Handling
    
    func testInvalidEventIsDiscarded() {
        let eventExpectation = expectation(description: "Service should not attempt to track invalid event.")
        
        // GIVEN an INVALID event (event without name and / or trackers)
        let event = InvalidEventExample()
        
        // AND a tracker service using some tracker
        trackerService = EventTracking(deliveryType: .immediate)
        trackerService.loadCustomTracker(tracker1)
        
        // WHEN we ask JustTrack to track the event
        let didAttemptToTrack = trackerService.trackEvent(event)
        
        // AND wait for a few seconds for the events to be processed
        let intervalToFireExpectationFulfill = 1.0
        // THEN we should not have attempted to track the event
        DispatchQueue.main.asyncAfter(deadline: .now() + intervalToFireExpectationFulfill) {
            XCTAssertFalse(didAttemptToTrack)
            XCTAssertEqual(self.tracker2.trackEventInvocationCount, 0)
            eventExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
}
