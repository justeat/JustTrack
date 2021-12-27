//
//  JustTrack
//
//  Copyright © 27/12/2021 Just Eat Holding Ltd.
//

import Foundation

public protocol Logger {
    func log(level: LogLevel, message: String)
}

extension Logger {
    func error(_ message: String) {
        log(level: .error, message: message)
    }

    func info(_ message: String) {
        log(level: .info, message: message)
    }
}
