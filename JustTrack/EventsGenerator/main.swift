#!/usr/bin/env xcrun swift

//
//  JustTrack
//
//  Copyright © 2017 Just Eat Holding Ltd.
//

import Foundation

private enum EventTemplate : String {
    case eventList = "EventListTemplate.jet"
    case event = "EventTemplate.jet"
    case keyName = "EventKeyNameTemplate.jet"
    case keyVar = "EventKeyVarTemplate.jet"
    case eventInit = "EventInitTemplate.jet"
    case eventInitAssignsList = "EventInitAssignTemplate.jet"
    case eventInitParam = "EventInitParam.jet"
}

private enum EventTemplatePlaceholder : String {
    case eventList = "events_list"
    case eventName = "event_name"
    case keyValueChain = "event_keyValueChain"
    case eventTrackers = "event_cs_trackers_str"
    case keysNames = "event_keysNames"
    case keysVars = "event_keysVars"
    case keyName = "key_name"
    case keyNameOriginal = "key_name_original"
    case eventInit = "event_init"
    case eventInitParams = "event_init_params"
    case eventInitAssignsList = "event_init_assigns_list"
}

private enum EventPlistKey : String {
    case payload = "payloadKeys"
    case trackrs = "registeredTrackers"
}

enum EventGeneratorError: Error {
    //generic
    case invalidParameter(wrongParameterIndex: Int)
    //templates
    case templateNotFound
    case templateMalformed
    //event plist
    case plistNotFound
    case trackerMissing
    //swift file
    case swiftFileNotFound
    //events
    case eventMalformed
}

//MARK - Utility

// Log string prepending the nameof the project
func log(msg: String) {
    print("TRACK: \(msg)")
}

//return the current script path
func scriptPath() -> NSString {
    
    let cwd = FileManager.default.currentDirectoryPath
    let script = CommandLine.arguments[0];
    var path: NSString?
    
    //get script working dir
    if script.hasPrefix("/") {
        path = script as NSString?
    }
    else {
        let urlCwd = URL(fileURLWithPath: cwd)
        if let urlPath = URL(string: script, relativeTo: urlCwd) {
            path = urlPath.path as NSString?
        }
    }
    
    path = path!.deletingLastPathComponent as NSString?
    return path!
}

func urlForTemplate(_ templateName: String) throws -> URL {

    var url: URL?
    
    let path: String? = Bundle.main.path(forResource: templateName, ofType: nil) //uses]d by test target
    if path != nil {
        url = URL(fileURLWithPath: path!)
    }
    else {
        let dir = scriptPath()
        url = URL(fileURLWithPath: dir as String).appendingPathComponent(templateName) //used in the build phase
    }
    
    guard url != nil else {
        throw EventGeneratorError.templateNotFound
    }

    return url!
}

//Load the specific template

func stringFromTemplate(_ templateName: String) throws -> String {
    
    let url: URL = try urlForTemplate(templateName)
    var result: String?
    //reading
    do {
        log(msg: "Load template \(url)")
        result = try String(contentsOf: url)
        result = result?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    catch {
        log(msg: "Error loading template \(templateName)")
        throw EventGeneratorError.templateMalformed
    }
    
    return result!
}

private func loadEventPlist(_ plistPath: String) throws -> NSDictionary {
    
    let result: NSMutableDictionary = NSMutableDictionary()
    
    if FileManager.default.fileExists(atPath: plistPath) {
        var eventsDict: NSDictionary? = NSDictionary(contentsOfFile: plistPath)
        eventsDict = eventsDict?.object(forKey: "events") as? NSDictionary
        if eventsDict != nil {
            result.setDictionary(eventsDict as! [AnyHashable : Any])
        }
    }
    else {
        throw EventGeneratorError.plistNotFound
    }
    
    return result
}

private func sanitised(_ originalString: String) -> String {
    var result = originalString
    
    let components = result.components(separatedBy: .whitespacesAndNewlines)
    result = components.joined(separator: "")
    
    let componantsByUnderscore = result.components(separatedBy: CharacterSet.alphanumerics.inverted)

    if !componantsByUnderscore.isEmpty
    {
        result = ""
        for component in componantsByUnderscore {
            if component != componantsByUnderscore[0] {
                result.append(component.capitalizingFirstLetter())
            }
            else {
                result.append(component)
            }
        }
    }
    return result
}

func printHelp() {
    log(msg: "HELP: //TODO")
}

//MARK - Structs generator helpers

private func generateEvents(_ events: [String : AnyObject]) throws -> NSString {
    
    //load templates
    let structListTemplateString: String = try stringFromTemplate(EventTemplate.eventList.rawValue)
    let structTemplate: String = try stringFromTemplate(EventTemplate.event.rawValue)
    
    let resultString: NSMutableString = NSMutableString(string: structListTemplateString)
    var structsArray: [String] = Array()
    
    for eventName: String in events.keys.sorted(by: >) {
        
        let eventDic: [String : AnyObject]? = events[eventName] as? [String : AnyObject]
        
        let sanitisedValue = sanitised(eventName)
        var structString = structTemplate
        structString = replacePlaceholder(structString, placeholder: "<*!\(EventTemplatePlaceholder.eventName.rawValue)*>", value: sanitisedValue ) //<*!event_name*> = Example
        structString = replacePlaceholder(structString, placeholder: "<*\(EventTemplatePlaceholder.eventName.rawValue)*>", value: sanitisedValue) //<*event_name*> = example
        
        let originalKeys:[String] = eventDic![EventPlistKey.payload.rawValue] as! [String]
        
        //sanitise keys
        let cleanKeys:[String] = originalKeys.map{ sanitised($0) }
        
        //<*event_keyValueChain*> = kKey1 : key1 == "" ? NSNull() : key1 as NSString
        let eventKeyValueChain: String = generateEventKeyValueChain(cleanKeys)
        structString = replacePlaceholder(structString, placeholder: "<*\(EventTemplatePlaceholder.keyValueChain.rawValue)*>", value: eventKeyValueChain)
        
        //<*event_cs_trackers_str*> = "console", "GA"
        let eventCsTrackers: String = try generateEventCsTrackers(eventDic![EventPlistKey.trackrs.rawValue] as! [String])
        structString = replacePlaceholder(structString, placeholder: "<*\(EventTemplatePlaceholder.eventTrackers.rawValue)*>", value: eventCsTrackers)
        
        /*
         <*event_keysNames*> =
         private let kKey1 = "key1"
         private let kKey2 = "key2"
         */
        let eventKeysNames: String = try generateEventKeysNames(originalKeys)
        structString = replacePlaceholder(structString, placeholder: "<*\(EventTemplatePlaceholder.keysNames.rawValue)*>", value: eventKeysNames)
        
        /*
         <*event_keysVars*> =
         let key1 : String
         let key2 : String
         */
        let eventKeysVars: String = try generateEventKeysVariables(cleanKeys)
        structString = replacePlaceholder(structString, placeholder: "<*\(EventTemplatePlaceholder.keysVars.rawValue)*>", value: eventKeysVars)
        
        /*
         <*event_init*> =
         init(<*event_init_params*>) {
             super.init()
             <*event_init_assigns_list*>
         }
         
         <*event_init_params*> = test1: String, test2: String, test3: String
         <*event_init_assigns_list*> =
         self.test1 = test1
         self.test2 = test2
         self.test3 = test3
         */
        let eventInit: String = try generateEventInit(cleanKeys)
        structString = replacePlaceholder(structString, placeholder: "<*\(EventTemplatePlaceholder.eventInit.rawValue)*>", value: eventInit)

        structsArray.append(structString)
    }
    
    //base list template
    resultString.replaceOccurrences(of: "<*\(EventTemplatePlaceholder.eventList.rawValue)*>",
                                            with: structsArray.joined(separator: "\n\n"),
                                            options: NSString.CompareOptions.caseInsensitive,
                                            range: NSRange(location: 0, length: resultString.length) )
    return resultString
}

private func replacePlaceholder(_ original: String, placeholder: String, value: String) -> String {
    
    if original.lengthOfBytes(using: String.Encoding.utf8) < 1 || placeholder.lengthOfBytes(using: String.Encoding.utf8) < 1 {
        return original
    }
    
    let valueToReplace: String
    var mutableValue = value
    if placeholder.contains("<*!") {
        mutableValue.replaceSubrange(mutableValue.startIndex...mutableValue.startIndex, with: String(mutableValue[value.startIndex]).capitalized) //only first capitalised letter, maintain the rest immutated
        valueToReplace = mutableValue
    }
    else {
        valueToReplace = value
    }
    
    return original.replacingOccurrences(of: placeholder, with: valueToReplace)
}

//MARK Components generator

func generateEventKeyValueChain(_ keys: [String]) -> String {
    
    var resultArray: [String] = Array()
    for keyString in keys {
        var capKeyString = keyString
        capKeyString.replaceSubrange(capKeyString.startIndex...capKeyString.startIndex, with: String(capKeyString[capKeyString.startIndex]).capitalized)
        resultArray.append("k\(capKeyString): \(keyString) == \"\" ? NSNull() : \(keyString) as NSString")
    }
    
    if (resultArray.count > 0) {
        return "\n            " + resultArray.joined(separator: ", \n            ") + "\n        "
    }
    
    return ":"
}

private func generateEventCsTrackers(_ trackers: [String]) throws -> String {
    
    var resultArray: [String] = Array()
    for keyString in trackers {
        resultArray.append("\"\(keyString)\"")
    }
    
    if resultArray.count < 1 {
        throw EventGeneratorError.trackerMissing
    }
    
    return resultArray.joined(separator: ", ")
}

private func generateEventKeysNames(_ keys: [String]) throws -> String {
    
    let structKeyNameTemplate: String = try stringFromTemplate(EventTemplate.keyName.rawValue)
    var resultArray: [String] = Array()
    for keyString in keys {
        var structKeyNameString = replacePlaceholder(structKeyNameTemplate, placeholder: "<*\(EventTemplatePlaceholder.keyNameOriginal.rawValue)*>", value: keyString)
        structKeyNameString = replacePlaceholder(structKeyNameString, placeholder: "<*!\(EventTemplatePlaceholder.keyName.rawValue)*>", value: sanitised(keyString))
        resultArray.append(structKeyNameString)
    }
    
    return resultArray.count > 0 ? resultArray.joined(separator: "\n    ") : ""
}

private func generateEventKeysVariables(_ keys: [String]) throws -> String {
    
    let structVarTemplate: String = try stringFromTemplate(EventTemplate.keyVar.rawValue)
    var resultArray: [String] = Array()
    for keyString in keys {
        let structVarString = replacePlaceholder(structVarTemplate, placeholder: "<*\(EventTemplatePlaceholder.keyName.rawValue)*>", value: keyString)
        resultArray.append(structVarString)
    }
    return resultArray.count > 0 ? resultArray.joined(separator: "\n    ") : ""
}

private func generateEventInit(_ keys: [String]) throws -> String {
    
    if keys.count == 0 {
        return "//MARK: Payload not configured"
    }
    
    var initTemplateString: String = try stringFromTemplate(EventTemplate.eventInit.rawValue)
    
    //replace event_init_assigns_list
    let initAssignsTemplateString: String = try stringFromTemplate(EventTemplate.eventInitAssignsList.rawValue)
    
    //replace event_init_params
    let initParamTemplateString: String = try stringFromTemplate(EventTemplate.eventInitParam.rawValue)
    
    var assignsResultArray: [String] = Array()
    var paramsResultArray: [String] = Array()
    for keyString in keys {
        let assignsResultString = replacePlaceholder(initAssignsTemplateString, placeholder: "<*\(EventTemplatePlaceholder.keyName.rawValue)*>", value: keyString)
        assignsResultArray.append(assignsResultString)
        
        let paramResultString = replacePlaceholder(initParamTemplateString, placeholder: "<*\(EventTemplatePlaceholder.keyName.rawValue)*>", value: keyString)
        paramsResultArray.append(paramResultString)
    }
    
    let eventInitAssignsString: String = assignsResultArray.joined(separator: "\n        ")
    initTemplateString = replacePlaceholder(initTemplateString, placeholder: "<*\(EventTemplatePlaceholder.eventInitAssignsList.rawValue)*>", value: eventInitAssignsString)
    
    let eventInitParamsAssignsString: String = paramsResultArray.joined(separator: ",\n                ")
    initTemplateString = replacePlaceholder(initTemplateString, placeholder: "<*\(EventTemplatePlaceholder.eventInitParams.rawValue)*>", value: eventInitParamsAssignsString)
    
    return initTemplateString
}

private func exitWithError() {
//    printHelp()
    exit(1)
}

//------------------------------------------------------------------------------------------------------------------------------

//MARK - Main script

log(msg: "Generating Events Swift code...")

log(msg: "Script arguments:")
for argument in CommandLine.arguments {
    log(msg: "- \(argument)")
}

//validate
if CommandLine.arguments.count < 3 {
    log(msg: "Wrong arguments")
    exitWithError()
}

do {
    //load plist
    let plistPath = CommandLine.arguments[1]
    let structsDict = try loadEventPlist(plistPath)
    log(msg: "Events Plist loaded \(structsDict)")
    
    //write struct file
    let structSwiftFilePath = CommandLine.arguments[2]
    if !FileManager.default.fileExists(atPath: structSwiftFilePath) {
        throw EventGeneratorError.swiftFileNotFound
    }
    
    //generate struct string
    let structsString: NSString = try generateEvents(structsDict as! [String : AnyObject])
    log(msg: "Events code correctly generated")
    
    //write struct string in file
    log(msg: "Generating swift code in: \(structSwiftFilePath)")
    try structsString.write(toFile: structSwiftFilePath, atomically: true, encoding: String.Encoding.utf8.rawValue)
}
catch EventGeneratorError.plistNotFound {
    log(msg: "Invalid plist path")
    exitWithError()
}
catch EventGeneratorError.trackerMissing {
    log(msg: "Tracker(s) missing in one or more event(s)")
    exitWithError()
}
catch EventGeneratorError.templateNotFound {
    log(msg: "Error generating events code")
    exitWithError()
}
catch EventGeneratorError.templateMalformed {
    log(msg: "Error generating events code")
    exitWithError()
}
catch EventGeneratorError.swiftFileNotFound {
    log(msg: "Swift file not found")
    exitWithError()
}
catch {
    log(msg: "Generic error")
    exitWithError()
}

log(msg: "**Swift code generated successfully**")

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).uppercased() + self.dropFirst()
    }
}