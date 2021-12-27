//
//  JustTrack
//
//  Copyright © 27/12/2021 Just Eat Holding Ltd.
//

import Foundation

public protocol DataStorable {
    func value<T>(forKey key: String) -> T?
    func setValue(_ value: Any?, forKey key: String)
}

extension UserDefaults: DataStorable {
    public func value<T>(forKey key: String) -> T? {
        value(forKey: key) as? T
    }
}
