//
//  JustTrack
//
//  Copyright © 2017 Just Eat Holding Ltd.
//

import Foundation

public protocol EventTracker {
    var name: String { get }
    
    @discardableResult
    func trackEvent(_ name: String, payload: Payload) -> Bool
}
