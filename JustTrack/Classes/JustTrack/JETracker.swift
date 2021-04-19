//
//  JustTrack
//
//  Copyright © 2017 Just Eat Holding Ltd.
//

import Foundation

public protocol JETracker {
    var name: String { get }
    func trackEvent(_ name: String, payload: Payload, completion: (_ success: Bool) -> Void )
}
