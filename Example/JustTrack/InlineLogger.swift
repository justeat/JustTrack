//
//  JustTrack
//
//  Copyright © 27/12/2021 Just Eat Holding Ltd.
//

import JustTrack

struct InlineLogger: Logger {
    let log: (_ level: LogLevel, _ message: String) -> Void

    func log(level: LogLevel, message: String) {
        log(level, message)
    }
}
