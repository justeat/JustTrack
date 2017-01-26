import XCTest
import JustTrack

class TrackerTests: XCTestCase {
    
    // MARK: - SUT
    var trackerService: JETracking!
    
    // MARK: - Stubs / Mocks
    
    let tracker1 = MockTracker(configuration: nil)
    let tracker2 = SomeOtherMockTracker(configuration: nil)
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        trackerService = JETracking.sharedInstance
    }
    
    // MARK: - Teardown
    override func tearDown() {
        trackerService = nil
        super.tearDown()
    }
    
    // MARK: - Immediate Mode
    
    func testExpectedTrackersAreCalledInImmediateMode() {
        
        let eventExpectation = expectation(description: "Event is tracked in IMMEDIATE dispatch mode.")
        
        // GIVEN an event targeted to "Mock Tracker" and "Some Other Mock Tracker"
        let event = JEEventExample(trackers: "MockTracker", "SomeOtherMockTracker")
        
        // AND a tracker service using these two trackers in "immediate" mode
        trackerService.loadCustomTracker(tracker1)
        trackerService.loadCustomTracker(tracker2)
        trackerService.deliveryType = .immediate
        
        // WHEN we ask JustTrack to track the event
        trackerService.trackEvent(event)
        
        // AND wait for a few seconds for the events to be processed
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            eventExpectation.fulfill()
        }
        
        // THEN the expected trackers have been asked to "track / post" that event
        waitForExpectations(timeout: 1) { error in
            XCTAssertTrue(self.tracker1.didTrackEvent)
            XCTAssertTrue(self.tracker2.didTrackEvent)
        }
    }
    
    // MARK: - BATCH Mode
    
    func testExpectedTrackersAreCalledInBatchMode() {
        
        let eventExpectation = expectation(description: "Event is tracked in BATCH dispatch mode.")
        
        // GIVEN an event targeted to "Mock Tracker" and "Some Other Mock Tracker"
        let event = JEEventExample(trackers: "MockTracker", "SomeOtherMockTracker")
        
        // AND a tracker service using these two trackers that processes events in 2 second "batches"
        trackerService.loadCustomTracker(tracker1)
        trackerService.loadCustomTracker(tracker2)
        trackerService.deliveryType = .batch
        trackerService.dispatchInterval = 2.0
        
        // WHEN we ask JustTrack to track the event
        trackerService.trackEvent(event)
        
        // AND wait for MORE seconds than the batch size for the events to be processed
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            eventExpectation.fulfill()
        }
        
        // THEN the expected trackers have been asked to "track / post" that event
        waitForExpectations(timeout: 3) { error in
            XCTAssertTrue(self.tracker1.didTrackEvent)
            XCTAssertTrue(self.tracker2.didTrackEvent)
        }
    }
    
    func testExpectedTrackersHaveNotBeenCalledBeforeBatchInterval() {
        
        let eventNotTrackedExpectation = expectation(description: "Event tracking should respect BATCH mode dispatch times.")
        
        // GIVEN an event targeted to "Mock Tracker" and "Some Other Mock Tracker"
        let event = JEEventExample(trackers: "MockTracker", "SomeOtherMockTracker")
        
        // AND a tracker service using these two trackers that processes events in 2 second "batches"
        trackerService.loadCustomTracker(tracker1)
        trackerService.loadCustomTracker(tracker2)
        trackerService.deliveryType = .batch
        trackerService.dispatchInterval = 2.0
        
        // WHEN we ask JustTrack to track the event
        trackerService.trackEvent(event)
        
        // AND wait for LESS seconds than the batch size for the events to be processed
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            eventNotTrackedExpectation.fulfill()
        }
        
        // THEN the expected trackers have NOT been asked to "track / post" that event yet
        waitForExpectations(timeout: 1) { error in
            XCTAssertFalse(self.tracker1.didTrackEvent)
            XCTAssertFalse(self.tracker2.didTrackEvent)
        }
        
        // BUT if we wait for MORE seconds than the batch size for the events to be processed
        let eventTrackedExpectation = expectation(description: "Event expectation, BATCH mode.")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            eventTrackedExpectation.fulfill()
        }
        
        // THEN the expected trackers have been asked to "track / post" that event
        waitForExpectations(timeout: 3) { error in
            XCTAssertTrue(self.tracker1.didTrackEvent)
            XCTAssertTrue(self.tracker2.didTrackEvent)
        }
    }
    
    // MARK: - Event-Tracker Mapping
    
    func testEventsAreNotTrackedByNonWantedTrackers() {
    
        let eventExpectation = expectation(description: "Event should only be tracked by the expected trackers.")
        
        // GIVEN an event targeted to "Mock Tracker" only
        let event = JEEventExample(trackers: "MockTracker")
        event.test1 = "value1"
        event.test2 = "value2"
        event.test3 = "value3"
        
        // AND a tracker service using "MockTracker" and "SomeOtherMockTracker"
        trackerService.loadCustomTracker(tracker1)
        trackerService.loadCustomTracker(tracker2)
        trackerService.deliveryType = .immediate
        
        // WHEN we ask JustTrack to track the event
        trackerService.trackEvent(event)
        
        // AND wait for a few seconds for the events to be processed
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            eventExpectation.fulfill()
        }
        
        // THEN ONLY tracker1 ("MockTracker") has been asked to track the event
        waitForExpectations(timeout: 3) { error in
            XCTAssertTrue(self.tracker1.didTrackEvent)
            XCTAssertFalse(self.tracker2.didTrackEvent)
        }
    }
    
    func testTrackersCaseSensitiveNames() {
        
        let eventExpectation = expectation(description: "Event should not be tracked regardless if the tracker name is capitalised or not")
        
        // GIVEN an event targeted to "Mock Tracker" only
        let event = JEEventExample(trackers: "mockTracker")
        
        // AND a tracker service using "MockTracker" and "SomeOtherMockTracker"
        trackerService.loadCustomTracker(tracker1)
        trackerService.loadCustomTracker(tracker2)
        trackerService.deliveryType = .immediate
        
        // WHEN we ask JustTrack to track the event
        trackerService.trackEvent(event)
        
        // AND wait for a few seconds for the events to be processed
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            eventExpectation.fulfill()
        }
        
        // THEN ONLY tracker1 ("MockTracker") has been asked to track the event
        waitForExpectations(timeout: 1) { error in
            XCTAssertTrue(self.tracker1.didTrackEvent)
            XCTAssertFalse(self.tracker2.didTrackEvent)
        }
    }
    
    // MARK: - Invalid Event Handling
    
    func testInvalidEventIsDiscarded() {
     
        let eventExpectation = expectation(description: "Service should not attempt to track invalid event.")
        
        // GIVEN an INVALID event (event without name and / or trackers)
        let event = JEEventInvalid()
        
        // AND a tracker service using some tracker
        trackerService.loadCustomTracker(tracker1)
        trackerService.deliveryType = .immediate
        
        // WHEN we ask JustTrack to track the event
        let didAttemptToTrack = trackerService.trackEvent(event)
        
        // AND wait for a few seconds for the events to be processed
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            eventExpectation.fulfill()
        }
        
        // THEN we should not have attempted to track the event
        waitForExpectations(timeout: 1) { error in
            XCTAssertFalse(didAttemptToTrack)
            XCTAssertFalse(self.tracker1.didTrackEvent)
        }
    }
}
