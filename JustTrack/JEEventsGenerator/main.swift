#!/usr/bin/env xcrun swift

//
//  JustTracking
//
//  Copyright © 2017 Just Eat Holding Ltd.
//

import Foundation

private enum JETemplate : String {
    case eventList = "JEEventListTemplate.jet"
    case event = "JEEventTemplate.jet"
    case keyName = "JEEventKeyNameTemplate.jet"
    case keyVar = "JEEventKeyVarTemplate.jet"
    case eventInit = "JEEventInitTemplate.jet"
    case eventInitAssignsList = "JEEventInitAssignTemplate.jet"
    case eventInitParam = "JEEventInitParam.jet"
}

private enum JETemplatePlaceholder : String {
    case eventList = "events_list"
    case eventName = "event_name"
    case keyValueChain = "event_keyValueChain"
    case eventTrackers = "event_cs_trackers_str"
    case keysNames = "event_keysNames"
    case keysVars = "event_keysVars"
    case keyName = "key_name"
    case eventInit = "event_init"
    case eventInitParams = "event_init_params"
    case eventInitAssignsList = "event_init_assigns_list"
}

private enum JEPlistKey : String {
    case payload = "payloadKeys"
    case trackrs = "registeredTrackers"
}

enum JEStructsGeneratorError: Error {
    //generic
    case invalidParameter(wrongParameterIndex: Int)
    //templates
    case templateNotFound
    case templateMalformed
    //event plist
    case plistNotFound
    //swift file
    case swiftFileNotFound
    //events
    case eventsArrayNotFound
    case eventsArrayEmpty
    //event
    case eventMalformed
    case eventTrackersNotFound
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
        throw JEStructsGeneratorError.templateNotFound
    }

    return url!
}

//load the specific template
func stringFromTemplate(_ templateName: String) throws -> String {

    let url: URL = try urlForTemplate(templateName)

    var result: String?

    //reading
    do {
        log(msg: "Load template \(url)")
        result = try NSString(contentsOf: url, encoding: String.Encoding.utf8.rawValue) as String
    }
    catch {
        log(msg: "Error loading template \(templateName)")
        throw JEStructsGeneratorError.templateMalformed
    }

    return result!
}

func loadEventPlist(_ plistPath: String) throws -> NSDictionary {

    let result: NSMutableDictionary = NSMutableDictionary()

    if FileManager.default.fileExists(atPath: plistPath) {

        let structsDict: NSDictionary? = NSDictionary(contentsOfFile: plistPath)

        if structsDict != nil {
            result.setDictionary(structsDict as! [String: AnyObject])
        }
    }
    else {
        throw JEStructsGeneratorError.plistNotFound
    }

    return result
}

func printHelp() {
    log(msg: "HELP: //TODO")
}

//MARK - Structs generator helpers

func generateStructs(_ events: [String : AnyObject]) throws -> NSString {

    //load templates
    let structListTemplateString: String = try stringFromTemplate(JETemplate.eventList.rawValue)
    let structTemplate: String = try stringFromTemplate(JETemplate.event.rawValue)

    let resultString: NSMutableString = NSMutableString(string: structListTemplateString)
    var structsArray: [String] = Array()

    guard events.keys.count > 0 else {
        throw JEStructsGeneratorError.eventsArrayEmpty
    }

    for eventName in events.keys {
        guard let eventDic = events[eventName] as? [String : AnyObject], eventDic.keys.count > 0 else {
            throw JEStructsGeneratorError.eventMalformed
        }

        var structString = structTemplate
        structString = replacePlaceholder(structString, placeholder: "<*!\(JETemplatePlaceholder.eventName.rawValue)*>", value: swiftyClassName(for: eventName)) //<*!event_name*> = Example
        structString = replacePlaceholder(structString, placeholder: "<*\(JETemplatePlaceholder.eventName.rawValue)*>", value: eventName) //<*event_name*> = example

        let keys: [String] = (eventDic[JEPlistKey.payload.rawValue] as? [String]) ?? []

        /*
         <*event_keyValueChain*> = kKey1 : key1, kKey2 : key2
         */
        let eventKeyValueChain: String = generateEventKeyValueChain(keys)
        structString = replacePlaceholder(structString, placeholder: "<*\(JETemplatePlaceholder.keyValueChain.rawValue)*>", value: eventKeyValueChain)

        /*
         <*event_cs_trackers_str*> = "console", "GA"
         */
        guard let trackers = eventDic[JEPlistKey.trackrs.rawValue] as? [String] else {
            throw JEStructsGeneratorError.eventTrackersNotFound
        }
        let eventCsTrackers: String = generateEventCsTrackers(trackers)
        structString = replacePlaceholder(structString, placeholder: "<*\(JETemplatePlaceholder.eventTrackers.rawValue)*>", value: eventCsTrackers)

        /*
         <*event_keysNames*> =
         private let kKey1 = "key1"
         private let kKey2 = "key2"
         */
        let eventKeysNames: String = try generateEventKeysNames(keys)
        structString = replacePlaceholder(structString, placeholder: "<*\(JETemplatePlaceholder.keysNames.rawValue)*>", value: eventKeysNames)

        /*
         <*event_keysVars*> =
         let key1 : String
         let key2 : String
         */
        let eventKeysVars: String = try generateEventKeysVars(keys)
        structString = replacePlaceholder(structString, placeholder: "<*\(JETemplatePlaceholder.keysVars.rawValue)*>", value: eventKeysVars)

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
        var eventInit: String = try generateEventInit(keys)
        if keys.count == 0 {
            eventInit = ""
        }
        structString = replacePlaceholder(structString, placeholder: "<*\(JETemplatePlaceholder.eventInit.rawValue)*>", value: eventInit)

        structsArray.append(structString)
    }

    //base list template
    resultString.replaceOccurrences(of: "<*\(JETemplatePlaceholder.eventList.rawValue)*>",
        with: structsArray.joined(separator: "\n\n"),
        options: NSString.CompareOptions.caseInsensitive,
        range: NSRange(location: 0, length: resultString.length) )
    return resultString
}

func replacePlaceholder(_ original: String, placeholder: String, value: String) -> String {

    if original.lengthOfBytes(using: String.Encoding.utf8) < 1 || placeholder.lengthOfBytes(using: String.Encoding.utf8) < 1 {
        return ""
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

private func swiftyPropertyName(for string: String) -> String {
    return string.components(separatedBy: " ").enumerated().reduce("", { result, current in
        var element = current.element

        if element.characters.count > 0 {
            if current.offset == 0 {
                element.replaceSubrange(element.startIndex...element.startIndex, with: String(element[element.startIndex]).lowercased())
            } else {
                element.replaceSubrange(element.startIndex...element.startIndex, with: String(element[element.startIndex]).capitalized)
            }
        }

        return result + element
    })
}

private func swiftyClassName(for string: String) -> String {
    var swiftyName = swiftyPropertyName(for: string)
    if swiftyName.characters.count > 0 {
        swiftyName.replaceSubrange(swiftyName.startIndex...swiftyName.startIndex, with: String(swiftyName[swiftyName.startIndex]).capitalized)
    }
    return swiftyName
}

private func generateEventKeyValueChain(_ keys: [String]) -> String {
    if keys.count < 1 {
        return ":"
    } else {
        return keys.flatMap { key in
            return "k\(swiftyClassName(for: key)): \(swiftyPropertyName(for: key)) as NSObject"
            }.joined(separator: ", ")
    }
}

private func generateEventCsTrackers(_ trackers: [String]) -> String {
    return trackers.flatMap { tracker in
        return "\"\(tracker)\""
        }.joined(separator: ", ")
}

private func generateEventKeysNames(_ keys: [String]) throws -> String {
    let structKeyNameTemplate: String = try stringFromTemplate(JETemplate.keyName.rawValue)

    return keys.flatMap { key in
        var structKeyNameValue = structKeyNameTemplate
        structKeyNameValue = replacePlaceholder(structKeyNameValue, placeholder: "<*\(JETemplatePlaceholder.keyName.rawValue)*>", value: key)
        structKeyNameValue = replacePlaceholder(structKeyNameValue, placeholder: "<*!\(JETemplatePlaceholder.keyName.rawValue)*>", value: swiftyClassName(for: key))

        return structKeyNameValue
        }.joined(separator: "\n    ")
}

private func generateEventKeysVars(_ keys: [String]) throws -> String {
    let structVarTemplate: String = try stringFromTemplate(JETemplate.keyVar.rawValue)

    return keys.flatMap { key in
        return replacePlaceholder(structVarTemplate, placeholder: "<*\(JETemplatePlaceholder.keyName.rawValue)*>", value: swiftyPropertyName(for: key))
        }.joined(separator: "\n    ")
}

func generateEventInit(_ keys: [String]) throws -> String {

    //replace event_init_assigns_list
    let initAssignsTemplateString: String = try stringFromTemplate(JETemplate.eventInitAssignsList.rawValue)

    //replace event_init_params
    let initParamTemplateString: String = try stringFromTemplate(JETemplate.eventInitParam.rawValue)

    var initTemplateString: String = try stringFromTemplate(JETemplate.eventInit.rawValue)

    let eventInitAssignsString = keys.flatMap { key in
        return replacePlaceholder(initAssignsTemplateString, placeholder: "<*\(JETemplatePlaceholder.keyName.rawValue)*>", value: swiftyPropertyName(for: key))
        }.joined(separator: "\n        ")

    let eventInitParamsAssignsString = keys.flatMap { key in
        return replacePlaceholder(initParamTemplateString, placeholder: "<*\(JETemplatePlaceholder.keyName.rawValue)*>", value: swiftyPropertyName(for: key))
        }.joined(separator: ", ")

    initTemplateString = replacePlaceholder(initTemplateString, placeholder: "<*\(JETemplatePlaceholder.eventInitAssignsList.rawValue)*>", value: eventInitAssignsString)

    initTemplateString = replacePlaceholder(initTemplateString, placeholder: "<*\(JETemplatePlaceholder.eventInitParams.rawValue)*>", value: eventInitParamsAssignsString)

    return initTemplateString
}

func exitWithError() {
    printHelp()
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
    var structsDict = try loadEventPlist(plistPath)
    log(msg: "Events Plist loaded \(structsDict)")

    //write struct file
    let structSwiftFilePath = CommandLine.arguments[2]
    if !FileManager.default.fileExists(atPath: structSwiftFilePath) {
        throw JEStructsGeneratorError.swiftFileNotFound
    }

    //generate struct string
    guard let events = structsDict["events"] as? [String : AnyObject] else {
        throw JEStructsGeneratorError.eventsArrayNotFound
    }
    let structsString: NSString = try generateStructs(events)
    log(msg: "Events code correctly generated")

    //write struct string in file
    log(msg: "Generating swift code in: \(structSwiftFilePath)")
    try structsString.write(toFile: structSwiftFilePath, atomically: true, encoding: String.Encoding.utf8.rawValue)
}
catch JEStructsGeneratorError.plistNotFound {
    log(msg: "Invalid plist path")
    exitWithError()
}
catch JEStructsGeneratorError.templateNotFound {
    log(msg: "Error generating events code")
    exitWithError()
}
catch JEStructsGeneratorError.templateMalformed {
    log(msg: "Error generating events code")
    exitWithError()
}
catch JEStructsGeneratorError.swiftFileNotFound {
    log(msg: "Swift file not found")
    exitWithError()
}
catch {
    log(msg: "Generic error")
    exitWithError()
}

log(msg: "**Swift code generated successfully**")
