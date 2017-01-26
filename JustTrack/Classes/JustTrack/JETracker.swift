/// Todo: Docs and OS License(Joakim L.)

import Foundation

public typealias Configuration = [String : String]

@objc public protocol JETracker {
    var name: String { get }
    init(configuration: Configuration?)
    func trackEvent(_ name: String, payload: Payload, completion: (_ success: Bool) -> Void )
}
