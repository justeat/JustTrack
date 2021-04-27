//compile time generated file, DO NOT TOUCH

/*example

public class JEEventExample: NSObject, JEEvent {
    public let name: String = "example"

    public var payload: Payload {
        return [
            kTest1 : test1 == "" ? NSNull() : test1 as NSString,
            kTest2 : test2 == "" ? NSNull() : test2 as NSString,
            kTest3 : test3 == "" ? NSNull() : test3 as NSString
        ]
    }

    public var registeredTrackers: [String] {
        return ["console", "tracker2"]
    }

    //keys
    private let kTest1 = "test1"
    private let kTest2 = "test2"
    private let kTest3 = "test3"

    public var test1 : String = ""
    public var test2 : String = ""
    public var test3 : String = ""

    public init(test1: String,
                test2: String,
                test3: String) {
        super.init()
        self.test1 = test1
        self.test2 = test2
        self.test3 = test3
    }
}
*/

import Foundation
import JustTrack

public class JEEventNoPayload: NSObject, JEEvent {
    public let name: String = "NoPayload"

    public var payload: Payload {
        return [:]
    }

    public var registeredTrackers: [String] {
        return ["console", "Firebase"]
    }

    

    

    //MARK: Payload not configured
}

public class JEEventTap: NSObject, JEEvent {
    public let name: String = "Tap"

    public var payload: Payload {
        return [
            kElementName: elementName == "" ? NSNull() : elementName as NSString
        ]
    }

    public var registeredTrackers: [String] {
        return ["console", "Firebase"]
    }

    private let kElementName = "elementName"

    public var elementName: String = ""

    public init(elementName: String) {
        super.init()
        self.elementName = elementName
    }
}

public class JEEventViewScreen: NSObject, JEEvent {
    public let name: String = "ViewScreen"

    public var payload: Payload {
        return [
            kScreenName: screenName == "" ? NSNull() : screenName as NSString, 
            kScreenData: screenData == "" ? NSNull() : screenData as NSString, 
            kScreenDataVar: screenDataVar == "" ? NSNull() : screenDataVar as NSString, 
            kScreenDataVarSetting: screenDataVarSetting == "" ? NSNull() : screenDataVarSetting as NSString
        ]
    }

    public var registeredTrackers: [String] {
        return ["console", "Firebase"]
    }

    private let kScreenName = "screenName"
    private let kScreenData = "screenData"
    private let kScreenDataVar = "screenData_var"
    private let kScreenDataVarSetting = "screenData_varSetting"

    public var screenName: String = ""
    public var screenData: String = ""
    public var screenDataVar: String = ""
    public var screenDataVarSetting: String = ""

    public init(screenName: String,
                screenData: String,
                screenDataVar: String,
                screenDataVarSetting: String) {
        super.init()
        self.screenName = screenName
        self.screenData = screenData
        self.screenDataVar = screenDataVar
        self.screenDataVarSetting = screenDataVarSetting
    }
}

public class JEEventUser: NSObject, JEEvent {
    public let name: String = "User"

    public var payload: Payload {
        return [
            kAction: action == "" ? NSNull() : action as NSString, 
            kResponse: response == "" ? NSNull() : response as NSString, 
            kExtra: extra == "" ? NSNull() : extra as NSString
        ]
    }

    public var registeredTrackers: [String] {
        return ["console", "Firebase"]
    }

    private let kAction = "action"
    private let kResponse = "response"
    private let kExtra = "extra"

    public var action: String = ""
    public var response: String = ""
    public var extra: String = ""

    public init(action: String,
                response: String,
                extra: String) {
        super.init()
        self.action = action
        self.response = response
        self.extra = extra
    }
}

public class JEEventExample: NSObject, JEEvent {
    public let name: String = "example"

    public var payload: Payload {
        return [
            kTest1: test1 == "" ? NSNull() : test1 as NSString, 
            kTest2: test2 == "" ? NSNull() : test2 as NSString, 
            kTest3: test3 == "" ? NSNull() : test3 as NSString
        ]
    }

    public var registeredTrackers: [String] {
        return ["console", "tracker2"]
    }

    private let kTest1 = "test_1"
    private let kTest2 = "test_2"
    private let kTest3 = "test_3"

    public var test1: String = ""
    public var test2: String = ""
    public var test3: String = ""

    public init(test1: String,
                test2: String,
                test3: String) {
        super.init()
        self.test1 = test1
        self.test2 = test2
        self.test3 = test3
    }
}