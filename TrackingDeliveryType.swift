//
//  JustTrack
//
//  Copyright © 27/12/2021 Just Eat Holding Ltd.
//

import Foundation

/// Tracking delivery type.
///
/// ````
/// case batch
/// case immediate
/// ````
///
/// - seealso: `dispatchInterval`
public enum TrackingDeliveryType {
    /// How long we should wait before events get pushed to trackers.
    case batch(dispatchInterval: TimeInterval)

    /// Will dispatch events to trackers immediately.
    case immediate
}
