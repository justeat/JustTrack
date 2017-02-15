//compile time generated file, DO NOT TOUCH

/*example

@objc public class JEEventExample:NSObject,JEEvent {

    //JEEvent protocol
    public let name: String = "example"

    public var payload: Payload {
        return [kTest1 : test1, kTest2 : test2, kTest3 : test3]
    }

    public var registeredTrackers: [String] {
        return ["console", "tracker2"]
    }

    //keys
    private let kTest1 = "test1"
    private let kTest2 = "test2"
    private let kTest3 = "test3"

    var test1 : String = ""
    var test2 : String = ""
    var test3 : String = ""

    public init(test1: String, test2: String, test3: String) {
        super.init()
        self.test1 = test1
        self.test2 = test2
        self.test3 = test3
    }
}
*/

import Foundation
import JustTrack

@objc public class JEEventExample:NSObject,JEEvent {

    public let name: String = "example"

    public var payload: Payload {
        return [kTest1 : test1 == "" ? NSNull() : test1 as NSString, kTest2 : test2 == "" ? NSNull() : test2 as NSString, kTest3 : test3 == "" ? NSNull() : test3 as NSString]
    }

    public var registeredTrackers: [String] {
        return ["console", "tracker2"]
    }

    private let kTest1 = "test1"
    private let kTest2 = "test2"
    private let kTest3 = "test3"

    var test1: String = ""
    var test2: String = ""
    var test3: String = ""

    public init(test1: String, test2: String, test3: String) {
        super.init()
        self.test1 = test1
        self.test2 = test2
        self.test3 = test3
    }
}


@objc public class JEEventViewScreen:NSObject,JEEvent {

    public let name: String = "ViewScreen"

    public var payload: Payload {
        return [kScreenName : screenName == "" ? NSNull() : screenName as NSString, kScreenData : screenData == "" ? NSNull() : screenData as NSString]
    }

    public var registeredTrackers: [String] {
        return ["console", "Firebase"]
    }

    private let kScreenName = "screenName"
    private let kScreenData = "screenData"

    var screenName: String = ""
    var screenData: String = ""

    public init(screenName: String, screenData: String) {
        super.init()
        self.screenName = screenName
        self.screenData = screenData
    }
}


@objc public class JEEventNoPayload:NSObject,JEEvent {

    public let name: String = "NoPayload"

    public var payload: Payload {
        return [:]
    }

    public var registeredTrackers: [String] {
        return ["console", "Firebase"]
    }

    

    

    //MARK: Payload not configured
}


@objc public class JEEventTap:NSObject,JEEvent {

    public let name: String = "Tap"

    public var payload: Payload {
        return [kElementName : elementName == "" ? NSNull() : elementName as NSString]
    }

    public var registeredTrackers: [String] {
        return ["console", "Firebase"]
    }

    private let kElementName = "elementName"

    var elementName: String = ""

    public init(elementName: String) {
        super.init()
        self.elementName = elementName
    }
}


@objc public class JEEventUser:NSObject,JEEvent {

    public let name: String = "User"

    public var payload: Payload {
        return [kAction : action == "" ? NSNull() : action as NSString, kResponse : response == "" ? NSNull() : response as NSString, kExtra : extra == "" ? NSNull() : extra as NSString]
    }

    public var registeredTrackers: [String] {
        return ["console", "Firebase"]
    }

    private let kAction = "action"
    private let kResponse = "response"
    private let kExtra = "extra"

    var action: String = ""
    var response: String = ""
    var extra: String = ""

    public init(action: String, response: String, extra: String) {
        super.init()
        self.action = action
        self.response = response
        self.extra = extra
    }
}

