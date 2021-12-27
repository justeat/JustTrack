//
//  JustTrack
//
//  Copyright © 27/12/2021 Just Eat Holding Ltd.
//

import Foundation

extension OperationQueue {
    convenience init(name: String,
                     maxConcurrentOperationCount: Int,
                     qualityOfService: QualityOfService) {
        self.init()
        self.name = name
        self.maxConcurrentOperationCount = maxConcurrentOperationCount
        self.qualityOfService = qualityOfService
    }
}
