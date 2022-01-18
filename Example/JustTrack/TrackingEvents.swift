//compile time generated file, DO NOT TOUCH

/*example

public class EventExample: Event {
    public let name: String = "example"

    public var payload: Payload {
        return [
            kTest1 : test1 == "" ? NSNull() : test1 as String,
            kTest2 : test2 == "" ? NSNull() : test2 as String,
            kTest3 : test3 == "" ? NSNull() : test3 as String
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
        self.test1 = test1
        self.test2 = test2
        self.test3 = test3
    }
}
*/

import Foundation
import JustTrack

public class EventViewScreen: Event {

    public let name: String = "view_screen"
    

    public var payload: Payload {
        return [
            kScreenName: screenName == "" ? NSNull() : screenName as String, 
            kScreenData: screenData == "" ? NSNull() : screenData as String, 
            kScreenDataVar: screenDataVar == "" ? NSNull() : screenDataVar as String, 
            kScreenDataVarSetting: screenDataVarSetting == "" ? NSNull() : screenDataVarSetting as String
        ]
    }

    public var registeredTrackers: [String] {
        return ["console", "Firebase"]
    }
    
    private let kScreenName = "screenName"
    private let kScreenData = "screenData"
    private let kScreenDataVar = "screenData_var"
    private let kScreenDataVarSetting = "screenData_varSetting"
    
    

    public var screenName = ""
    public var screenData = ""
    public var screenDataVar = ""
    public var screenDataVarSetting = ""
    

    public init(screenName: String,
                screenData: String,
                screenDataVar: String,
                screenDataVarSetting: String) {
        self.screenName = screenName
        self.screenData = screenData
        self.screenDataVar = screenDataVar
        self.screenDataVarSetting = screenDataVarSetting
    }
}
public class EventExample: Event {

    public let name: String = "example_name"
    
    public struct TestObject: Equatable, Codable {

        public var itemName = ""
        public var itemNumber = 0
        public var itemPrice = 0.0
        public var itemValue = false        
        
        public init(itemName: String,
                    itemNumber: Int,
                    itemPrice: Double,
                    itemValue: Bool) {
            self.itemName = itemName
            self.itemNumber = itemNumber
            self.itemPrice = itemPrice
            self.itemValue = itemValue
        }        
        
        var asDict: [String: Any] {
            [
             "item_name" : itemName,
             "item_number" : itemNumber,
             "item_price" : itemPrice,
             "item_value" : itemValue
            ]            
        }
        
    }

    public struct SecondTestObject: Equatable, Codable {

        public var itemName = ""
        public var itemNumberTest = ""        
        
        public init(itemName: String,
                    itemNumberTest: String) {
            self.itemName = itemName
            self.itemNumberTest = itemNumberTest
        }        
        
        var asDict: [String: Any] {
            [
             "item_name" : itemName,
             "item_number_test" : itemNumberTest
            ]            
        }
        
    }
      

    public var payload: Payload {
        return [
            kTest1: test1 == "" ? NSNull() : test1 as String, 
            kTest2: test2 == "" ? NSNull() : test2 as String, 
            kTest3: test3 == "" ? NSNull() : test3 as String,
        
            kTestObject: testObject == [] ? NSNull() : testObject.map { $0.asDict }, 
            kSecondTestObject: secondTestObject == [] ? NSNull() : secondTestObject.map { $0.asDict }
        ]
    }

    public var registeredTrackers: [String] {
        return ["console", "tracker2"]
    }
    
    private let kTest1 = "test_1"
    private let kTest2 = "test_2"
    private let kTest3 = "test_3"
    
    private let kTestObject = "testObject"
    private let kSecondTestObject = "secondTestObject"

    public var test1 = ""
    public var test2 = ""
    public var test3 = ""
    public var testObject: [TestObject]
    public var secondTestObject: [SecondTestObject]

    public init(test1: String,
                test2: String,
                test3: String,
                testObject: [TestObject],
                secondTestObject: [SecondTestObject]) {
        self.test1 = test1
        self.test2 = test2
        self.test3 = test3
        self.testObject = testObject
        self.secondTestObject = secondTestObject
    }
}
public class EventUser: Event {

    public let name: String = "User"
    

    public var payload: Payload {
        return [
            kAction: action == "" ? NSNull() : action as String, 
            kResponse: response == "" ? NSNull() : response as String, 
            kExtra: extra == "" ? NSNull() : extra as String
        ]
    }

    public var registeredTrackers: [String] {
        return ["console", "Firebase"]
    }
    
    private let kAction = "action"
    private let kResponse = "response"
    private let kExtra = "extra"
    
    

    public var action = ""
    public var response = ""
    public var extra = ""
    

    public init(action: String,
                response: String,
                extra: String) {
        self.action = action
        self.response = response
        self.extra = extra
    }
}
public class EventTap: Event {

    public let name: String = "Tap"
    

    public var payload: Payload {
        return [
            kElementName: elementName == "" ? NSNull() : elementName as String
        ]
    }

    public var registeredTrackers: [String] {
        return ["console", "Firebase"]
    }
    
    private let kElementName = "elementName"
    
    

    public var elementName = ""
    

    public init(elementName: String) {
        self.elementName = elementName
    }
}
public class EventNoPayload: Event {

    public let name: String = "NoPayload"
    

    public var payload: Payload {
        return [:]
    }

    public var registeredTrackers: [String] {
        return ["console", "Firebase"]
    }
    
    
    
    

    
    

    // MARK: Payload not configured
}