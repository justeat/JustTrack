//
//  JustTrack
//
//  Copyright © 27/12/2021 Just Eat Holding Ltd.
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
