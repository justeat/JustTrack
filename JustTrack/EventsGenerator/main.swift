#!/usr/bin/env xcrun swift

//
//  JustTrack
//
//  Copyright © 2017 Just Eat Holding Ltd.
//

import Foundation

private enum EventTemplate: String {
    case eventList = "EventListTemplate.jet"
    case event = "EventTemplate.jet"
    case keyName = "EventKeyNameTemplate.jet"
    case keyVar = "EventKeyVarTemplate.jet"
    case eventInit = "EventInitTemplate.jet"
    case eventInitAssignsList = "EventInitAssignTemplate.jet"
    case eventObjectInit = "EventObjectInitTemplate.jet"
    case eventObjectInitAssignsList = "EventObjectInitAssignTemplate.jet"
    case eventInitParam = "EventInitParam.jet"
    case eventObjectInitParam = "EventObjectInitParam.jet"
    case eventObjectStruct = "EventObjectStructTemplate.jet"
    case objectKeyVar = "EventObjectKeyVarTemplate.jet"
}

private enum EventTemplatePlaceholder: String {
    case eventList = "events_list"
    case event = "event"
    case eventName = "name"
    case keyValueChain = "event_keyValueChain"
    case eventTrackers = "event_cs_trackers_str"
    case keysNames = "event_keysNames"

    case keysVars = "event_keysVars"
    case keyName = "key_name"
    case formattedObjectKeyName = "formatted_object_key_name"
    case keyNameOriginal = "key_name_original"
    case eventInit = "event_init"
    case eventInitParams = "event_init_params"
    case eventInitAssignsList = "event_init_assigns_list"

    case eventObjectInit = "event_object_init"
    case eventObjectInitParams = "event_object_init_params"
    case eventObjectInitAssignsList = "event_object_init_assigns_list"

    // Facilitates array of objects
    case objectKeyChain = "event_objectKeyChain"
    case objectName = "object_name"
    case objectKeyName = "object_key_name"
    case objectKeysVars = "object_keysVars"
    case objectKeyNames = "object_keyNames"
    case objectStruct = "event_ObjectStructs"
    case objectStructParams = "object_parameter_list"
    case objectDictionaryParameterList = "dictionary_parameter_list"
}

private enum EventPlistKey: String {
    case payload = "payloadKeys"
    case objectPayload = "objectPayloadKeys"
    case trackers = "registeredTrackers"
}

enum EventGeneratorError: Error {
    // Generic
    case invalidParameter(wrongParameterIndex: Int)
    // Templates
    case templateNotFound
    case templateMalformed
    // Event plist
    case plistNotFound
    case trackerMissing
    // Swift file
    case swiftFileNotFound
    // Events
    case eventMalformed
}

// MARK: - Utility

enum DataType: String, CaseIterable {
    case integer = "_int"
    case double = "_double"
    case bool = "_bool"
}

// Log string prepending the name of the project
func log(message: String) {
    print("TRACK: \(message)")
}

// Return the current script path
func scriptPath() -> String {

    let cwd = FileManager.default.currentDirectoryPath
    let script = CommandLine.arguments[0]
    var path: NSString?

    // Get script working dir
    if script.hasPrefix("/") {
        path = script as NSString?
    } else {
        let urlCwd = URL(fileURLWithPath: cwd)
        if let urlPath = URL(string: script, relativeTo: urlCwd) {
            path = urlPath.path as NSString?
        }
    }

    path = path!.deletingLastPathComponent as NSString?
    return path! as String
}

func url(forTemplate templateName: String) -> URL {
    let url: URL
    if let path = Bundle.main.url(forResource: templateName, withExtension: nil) { // Used by test target
        url = path
    } else {
        let dir = scriptPath()
        url = URL(fileURLWithPath: dir).appendingPathComponent(templateName) // Used in the build phase
    }
    return url
}

// Load the specific template

func string(fromTemplate templateName: String) throws -> String {
    let url = url(forTemplate: templateName)
    let result: String

    do {
        log(message: "Load template \(url)")
        result = try String(contentsOf: url)
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    } catch {
        log(message: "Error loading template \(templateName)")
        throw EventGeneratorError.templateMalformed
    }

    return result
}

private func loadEvent(fromPlistPath plistPath: String) throws -> [String: AnyObject] {
    guard FileManager.default.fileExists(atPath: plistPath) else {
        throw EventGeneratorError.plistNotFound
    }
    guard let events = NSDictionary(contentsOfFile: plistPath)?.object(forKey: "events") as? [String: AnyObject] else {
        throw EventGeneratorError.eventMalformed
    }
    return events
}

private func sanitised(_ originalString: String) -> String {
    let componentsByUnderscore = originalString.components(separatedBy: .whitespacesAndNewlines)
        .joined(separator: "")
        .removeDataTypes()
        .components(separatedBy: CharacterSet.alphanumerics.inverted)

    return componentsByUnderscore.map { component in
        if component != componentsByUnderscore[0] {
            return component.capitalizingFirstLetter()
        } else {
            return component
        }
    }.joined()
}

// MARK: - Structs generator helpers

private func generateEvents(_ events: [String: AnyObject]) throws -> String {
    // Load templates
    let structListTemplateString = try string(fromTemplate: EventTemplate.eventList.rawValue)
    let structTemplate = try string(fromTemplate: EventTemplate.event.rawValue)

    var structsArray = [String]()

    for event in events.keys.sorted(by: >) {
        let eventDic = events[event] as? [String: AnyObject]

        guard let eventName = eventDic?[EventTemplatePlaceholder.eventName.rawValue] as? String else {
            continue
        }

        let sanitisedValue = sanitised(event)
        var structString = structTemplate
        structString = replacePlaceholder(structString,
                                          placeholder: "<*!\(EventTemplatePlaceholder.event.rawValue)*>",
                                          value: sanitisedValue,
                                          placeholderType: "routine") // <*!event*> = ExampleEvent
        structString = replacePlaceholder(structString,
                                          placeholder: "<*\(EventTemplatePlaceholder.eventName.rawValue)*>",
                                          value: eventName,
                                          placeholderType: "routine") // <*name*> = example_event

        let originalKeys = eventDic![EventPlistKey.payload.rawValue] as! [Any]

        var originalStringKeys = [String]()
        var cleanKeys = [String]()
        var objects = [NSDictionary]()

        for key in originalKeys { // Go through payload items
            switch key {
            case let setKey as String:
                cleanKeys.append(sanitised(setKey)) // Sanitise keys // let cleanKeys:[String] = originalKeys.map{ sanitised($0) }
                originalStringKeys.append(setKey)
            case let dictionary as NSDictionary:
                objects.append(dictionary)
            default:
                break
            }
        }

        let objectNames = objects.map { $0["name"] as! String }

        // <*event_keyValueChain*> = kKey1 : key1 == "" ? NSNull() : key1 as String
        let eventKeyValueChain = generateEventKeyValueChain(cleanKeys, eventHasObjects: !objects.isEmpty)

        structString = replacePlaceholder(structString,
                                          placeholder: "<*\(EventTemplatePlaceholder.keyValueChain.rawValue)*>",
                                          value: eventKeyValueChain,
                                          placeholderType: "routine")

        // Create array definition for each object item using name definition
        structString = replacePlaceholder(structString,
                                          placeholder: "<*\(EventTemplatePlaceholder.objectKeyChain.rawValue)*>",
                                          value: generateObjectKeyValue(objectNames),
                                          placeholderType: "routine")

        // <*event_cs_trackers_str*> = "console", "GA"
        let eventCsTrackers = try generateEventCsTrackers(eventDic![EventPlistKey.trackers.rawValue] as! [String])
        structString = replacePlaceholder(structString,
                                          placeholder: "<*\(EventTemplatePlaceholder.eventTrackers.rawValue)*>",
                                          value: eventCsTrackers,
                                          placeholderType: "routine")

        /*
         <*event_keysNames*> =
         private let kKey1 = "key1"
         private let kKey2 = "key2"
         */
        let eventKeyNames = try generateEventKeysNames(originalStringKeys)
        structString = replacePlaceholder(structString,
                                          placeholder: "<*\(EventTemplatePlaceholder.keysNames.rawValue)*>",
                                          value: eventKeyNames,
                                          placeholderType: "routine")

        let objectKeyNames = try generateEventKeysNames(objectNames)
        structString = replacePlaceholder(structString,
                                          placeholder: "<*\(EventTemplatePlaceholder.objectKeyNames.rawValue)*>",
                                          value: objectKeyNames,
                                          placeholderType: "routine")

        structString = replacePlaceholder(structString,
                                          placeholder: "<*\(EventTemplatePlaceholder.objectStruct.rawValue)*>",
                                          value: try generateObjectStructs(objects),
                                          placeholderType: "routine")

        /*
         <*event_keysVars*> =
         let key1 : String
         let key2 : String
         */

        let eventKeysVars = try generateKeyVariables(cleanKeys)
        let objectKeysVars = try generateObjectKeysVariables(objectNames)

        structString = replacePlaceholder(structString,
                                          placeholder: "<*\(EventTemplatePlaceholder.keysVars.rawValue)*>",
                                          value: eventKeysVars,
                                          placeholderType: "routine")
        structString = replacePlaceholder(structString,
                                          placeholder: "<*\(EventTemplatePlaceholder.objectKeysVars.rawValue)*>",
                                          value: objectKeysVars,
                                          placeholderType: "routine")

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

        let eventInit = try generateEventInit(cleanKeys, objectNames)
        structString = replacePlaceholder(structString,
                                          placeholder: "<*\(EventTemplatePlaceholder.eventInit.rawValue)*>",
                                          value: eventInit,
                                          placeholderType: "routine")

        structsArray.append(structString)
    }

    // Base list template
    return structListTemplateString.replacingOccurrences(of: "<*\(EventTemplatePlaceholder.eventList.rawValue)*>",
                                                         with: structsArray.joined(separator: "\n"),
                                                         options: .caseInsensitive)
}

private func replacePlaceholder(_ original: String,
                                placeholder: String,
                                value: String,
                                placeholderType: String) -> String {
    if original.lengthOfBytes(using: String.Encoding.utf8) < 1 || placeholder.lengthOfBytes(using: String.Encoding.utf8) < 1 {
        return original
    }

    let valueToReplace: String
    if placeholder.contains("<*!") {
        valueToReplace = value.capitalizingFirstLetter() // Only first capitalised letter, maintain the rest immutated
    } else {
        valueToReplace = value
    }

    switch placeholderType {
    case "routine":
        return original.replacingOccurrences(of: placeholder, with: valueToReplace)
    case "eventStringParameter":
        return original.replacingOccurrences(of: placeholder, with: valueToReplace + " = " + "\"\"")
    case "eventIntParameter":
        return original.replacingOccurrences(of: placeholder, with: valueToReplace + " = 0")
    case "eventDoubleParameter":
        return original.replacingOccurrences(of: placeholder, with: valueToReplace + " = 0.0")
    case "eventBoolParameter":
        return original.replacingOccurrences(of: placeholder, with: valueToReplace + " = false")
    case "eventAssignedStringParameter":
        return original.replacingOccurrences(of: placeholder, with: valueToReplace + ": String")
    case "eventAssignedIntParameter":
        return original.replacingOccurrences(of: placeholder, with: valueToReplace + ": Int")
    case "eventAssignedDoubleParameter":
        return original.replacingOccurrences(of: placeholder, with: valueToReplace + ": Double")
    case "eventAssignedBoolParameter":
        return original.replacingOccurrences(of: placeholder, with: valueToReplace + ": Bool")
    case "objectPlaceholder":
        return original.replacingOccurrences(of: placeholder,
                                             with: valueToReplace + ": [\(sanitised(valueToReplace).capitalizingFirstLetter())]")
    default:
        return original.replacingOccurrences(of: placeholder, with: valueToReplace)
    }
}

// MARK: Components generator

func generateEventKeyValueChain(_ keys: [String], eventHasObjects: Bool) -> String {
    let resultArray = keys.map { keyString in
        "k\(keyString.capitalizingFirstLetter()): \(keyString) == \"\" ? NSNull() : \(keyString) as String"
    }

    if eventHasObjects {
        return "\n            " + resultArray.joined(separator: ", \n            ") + ",\n        "
    } else if !resultArray.isEmpty {
        return "\n            " + resultArray.joined(separator: ", \n            ") + "\n        "
    } else {
        return ":"
    }
}

func generateObjectKeyValue(_ keys: [String]) -> String {
    guard !keys.isEmpty else {
        return ""
    }
    let resultArray = keys.map { keyString in
        "k\(keyString.capitalizingFirstLetter()): \(keyString) == [] ? NSNull() : \(sanitised(keyString)).map { $0.asDict }"
    }

    return "\n            " + resultArray.joined(separator: ", \n            ") + "\n        "
}

func generateObjectStructs(_ objects: [NSDictionary]) throws -> String {
    guard !objects.isEmpty else {
        return ""
    }
    let structEventObjectTemplate = try string(fromTemplate: EventTemplate.eventObjectStruct.rawValue)

    let resultArray = try objects.map { key -> String in
        let objectName = key["name"] as! String
        let objectParameters = key[EventPlistKey.objectPayload.rawValue] as! [String]

        let capItemName = objectName.capitalizingFirstLetter()
        var structObjectKeyString = replacePlaceholder(structEventObjectTemplate,
                                                       placeholder: "<*\(EventTemplatePlaceholder.objectName.rawValue)*>",
                                                       value: sanitised(capItemName),
                                                       placeholderType: "routine")

        let objectKeysVars = try generateStructKeyVariables(objectParameters, keyType: "objectKey")
        structObjectKeyString = replacePlaceholder(structObjectKeyString,
                                                   placeholder: "<*\(EventTemplatePlaceholder.objectStructParams.rawValue)*>\n",
                                                   value: objectKeysVars,
                                                   placeholderType: "routine")

        let objectKeysInit = try generateEventObjectInit(objectParameters)
        structObjectKeyString = replacePlaceholder(structObjectKeyString,
                                                   placeholder: "<*\(EventTemplatePlaceholder.eventObjectInit.rawValue)*>\n",
                                                   value: objectKeysInit,
                                                   placeholderType: "routine")

        let structFunctionString = generateObjectDictionaryFunction(objectParameters: objectParameters)
        return replacePlaceholder(structObjectKeyString,
                                  placeholder: "<*\(EventTemplatePlaceholder.objectDictionaryParameterList.rawValue)*>\n",
                                  value: structFunctionString,
                                  placeholderType: "routine")
    }

    return "\n    " + resultArray.joined(separator: "\n\n    ") + "\n      "
}

extension String {
    func removeDataTypes() -> String {
        let rawDataTypes = DataType.allCases.map { $0.rawValue }
        return replacingOccurrences(of: rawDataTypes, with: "")
    }
}

func generateObjectDictionaryFunction(objectParameters: [String]) -> String {
    let resultArray = objectParameters.map { item -> String in
        let itemString = item.removeDataTypes().lowercasingFirstLetter()
        let paramString = "\"\(itemString)\""
        return paramString + " : " + sanitised(itemString).lowercasingFirstLetter()
    }

    let structureResult: String
    if !resultArray.isEmpty {
        structureResult = resultArray.joined(separator: ",\n             ")
    } else {
        structureResult = resultArray.joined(separator: "\n")
    }

    return "[\n             " + structureResult + "\n            ]"
}

private func generateEventCsTrackers(_ trackers: [String]) throws -> String {
    guard !trackers.isEmpty else {
        throw EventGeneratorError.trackerMissing
    }
    return trackers
        .map { "\"\($0)\"" }
        .joined(separator: ", ")
}

private func generateEventKeysNames(_ keys: [String]) throws -> String {
    let structKeyNameTemplate = try string(fromTemplate: EventTemplate.keyName.rawValue)
    return keys.map { keyString -> String in
        let structKeyNameString = replacePlaceholder(structKeyNameTemplate,
                                                     placeholder: "<*\(EventTemplatePlaceholder.keyNameOriginal.rawValue)*>",
                                                     value: keyString,
                                                     placeholderType: "routine")
        return replacePlaceholder(structKeyNameString,
                                  placeholder: "<*!\(EventTemplatePlaceholder.keyName.rawValue)*>",
                                  value: sanitised(keyString),
                                  placeholderType: "routine")
    }.joined(separator: "\n    ")
}

private func generateKeyVariables(_ keys: [String]) throws -> String {
    let structVarTemplate = try string(fromTemplate: EventTemplate.keyVar.rawValue)
    return keys.map { keyString in
        replacePlaceholder(structVarTemplate,
                           placeholder: "<*\(EventTemplatePlaceholder.keyName.rawValue)*>",
                           value: sanitised(keyString),
                           placeholderType: "eventStringParameter")
    }.joined(separator: "\n    ")
}

private func generateStructKeyVariables(_ keys: [String], keyType: String) throws -> String {
    let structVarTemplate = try string(fromTemplate: EventTemplate.keyVar.rawValue)
    let resultArray = keys.map { keyString -> String in
        let placeholderType: String
        if keyString.contains(DataType.integer.rawValue) {
            placeholderType = "eventIntParameter"
        } else if keyString.contains(DataType.double.rawValue) {
            placeholderType = "eventDoubleParameter"
        } else if keyString.contains(DataType.bool.rawValue) {
            placeholderType = "eventBoolParameter"
        } else {
            placeholderType = "eventStringParameter"
        }
        return replacePlaceholder(structVarTemplate,
                                  placeholder: "<*\(EventTemplatePlaceholder.keyName.rawValue)*>",
                                  value: sanitised(keyString).lowercasingFirstLetter(),
                                  placeholderType: placeholderType)
    }

    switch keyType {
    case "eventKey":
        return resultArray.joined(separator: "\n    ")
    case "objectKey":
        return resultArray.joined(separator: "\n        ")
    default:
        return resultArray.joined(separator: "\n    ")
    }
}

private func generateObjectKeysVariables(_ keys: [String]) throws -> String {
    let structVarTemplate = try string(fromTemplate: EventTemplate.objectKeyVar.rawValue)
    return keys.map { keyString in
        let structVarString = replacePlaceholder(structVarTemplate,
                                                 placeholder: "<*\(EventTemplatePlaceholder.objectKeyName.rawValue)*>",
                                                 value: keyString,
                                                 placeholderType: "routine")
        return replacePlaceholder(structVarString,
                                  placeholder: "<*\(EventTemplatePlaceholder.formattedObjectKeyName.rawValue)*>",
                                  value: keyString.capitalizingFirstLetter(),
                                  placeholderType: "routine")
    }.joined(separator: "\n    ")
}

private func generateEventInit(_ keys: [String], _ objectKeys: [String]) throws -> String {
    guard !keys.isEmpty else {
        return "// MARK: Payload not configured"
    }

    var initTemplateString = try string(fromTemplate: EventTemplate.eventInit.rawValue)

    // Replace event_init_assigns_list
    let initAssignsTemplateString = try string(fromTemplate: EventTemplate.eventInitAssignsList.rawValue)

    // Replace event_init_params
    let initParamTemplateString = try string(fromTemplate: EventTemplate.eventInitParam.rawValue)

    var assignsResultArray = [String]()
    var paramsResultArray = [String]()

    for keyString in keys {
        let assignsResultString = replacePlaceholder(initAssignsTemplateString,
                                                     placeholder: "<*\(EventTemplatePlaceholder.keyName.rawValue)*>",
                                                     value: keyString,
                                                     placeholderType: "routine")
        assignsResultArray.append(assignsResultString)

        let paramResultString = replacePlaceholder(initParamTemplateString,
                                                   placeholder: "<*\(EventTemplatePlaceholder.keyName.rawValue)*>",
                                                   value: keyString,
                                                   placeholderType: "eventAssignedStringParameter")
        paramsResultArray.append(paramResultString)
    }

    // Object Keys
    for key in objectKeys {
        let assignsResultString = replacePlaceholder(initAssignsTemplateString,
                                                     placeholder: "<*\(EventTemplatePlaceholder.keyName.rawValue)*>",
                                                     value: key,
                                                     placeholderType: "routine")
        assignsResultArray.append(assignsResultString)

        let paramResultString = replacePlaceholder(initParamTemplateString,
                                                   placeholder: "<*\(EventTemplatePlaceholder.keyName.rawValue)*>",
                                                   value: key,
                                                   placeholderType: "objectPlaceholder")
        paramsResultArray.append(paramResultString)
    }

    let eventInitAssignsString = assignsResultArray.joined(separator: "\n        ")
    initTemplateString = replacePlaceholder(initTemplateString,
                                            placeholder: "<*\(EventTemplatePlaceholder.eventInitAssignsList.rawValue)*>",
                                            value: eventInitAssignsString,
                                            placeholderType: "routine")

    let eventInitParamsAssignsString = paramsResultArray.joined(separator: ",\n                ")
    return replacePlaceholder(initTemplateString,
                              placeholder: "<*\(EventTemplatePlaceholder.eventInitParams.rawValue)*>",
                              value: eventInitParamsAssignsString,
                              placeholderType: "routine")
}

private func generateEventObjectInit(_ keys: [String]) throws -> String {
    guard !keys.isEmpty else {
        return "// MARK: Payload not configured"
    }

    var initTemplateString = try string(fromTemplate: EventTemplate.eventObjectInit.rawValue)

    // Replace event_init_assigns_list
    let initAssignsTemplateString = try string(fromTemplate: EventTemplate.eventObjectInitAssignsList.rawValue)

    // Replace event_init_params
    let initParamTemplateString = try string(fromTemplate: EventTemplate.eventObjectInitParam.rawValue)

    let assignsResultArray = keys.map { keyString in
        replacePlaceholder(initAssignsTemplateString,
                           placeholder: "<*\(EventTemplatePlaceholder.objectKeyName.rawValue)*>",
                           value: sanitised(keyString).lowercasingFirstLetter(),
                           placeholderType: "routine")
    }
    let paramsResultArray = keys.map { keyString -> String in
        let placeholderType: String
        if keyString.contains(DataType.integer.rawValue) {
            placeholderType = "eventAssignedIntParameter"
        } else if keyString.contains(DataType.double.rawValue) {
            placeholderType = "eventAssignedDoubleParameter"
        } else if keyString.contains(DataType.bool.rawValue) {
            placeholderType = "eventAssignedBoolParameter"
        } else {
            placeholderType = "eventAssignedStringParameter"
        }

        return replacePlaceholder(initParamTemplateString,
                                  placeholder: "<*\(EventTemplatePlaceholder.objectKeyName.rawValue)*>",
                                  value: sanitised(keyString).lowercasingFirstLetter(),
                                  placeholderType: placeholderType)
    }

    let eventInitAssignsString = assignsResultArray.joined(separator: "\n            ")
    initTemplateString = replacePlaceholder(initTemplateString,
                                            placeholder: "<*\(EventTemplatePlaceholder.eventObjectInitAssignsList.rawValue)*>",
                                            value: eventInitAssignsString,
                                            placeholderType: "routine")

    let eventInitParamsAssignsString = paramsResultArray.joined(separator: ",\n                    ")
    return replacePlaceholder(initTemplateString,
                              placeholder: "<*\(EventTemplatePlaceholder.eventObjectInitParams.rawValue)*>",
                              value: eventInitParamsAssignsString,
                              placeholderType: "routine")
}

private func exitWithError() {
    exit(1)
}

extension String {
    func replacingOccurrences<Target, Replacement>(of targets: [Target],
                                                   with replacement: Replacement) -> String
    where Target: StringProtocol, Replacement: StringProtocol {
        targets.reduce(self) { return $0.replacingOccurrences(of: $1, with: replacement) }
    }

    func capitalizingFirstLetter() -> String {
        return prefix(1).uppercased() + dropFirst()
    }

    func lowercasingFirstLetter() -> String {
        return prefix(1).lowercased() + dropFirst()
    }
}

// ------------------------------------------------------------------------------------------------------------------------------

// MARK: - Main script

log(message: "Generating Events Swift code...")

log(message: "Script arguments:")
for argument in CommandLine.arguments {
    log(message: "- \(argument)")
}

// Validate
if CommandLine.arguments.count < 3 {
    log(message: "Wrong arguments")
    exitWithError()
}

do {
    // Load plist
    let plistPath = CommandLine.arguments[1]
    let structsDict = try loadEvent(fromPlistPath: plistPath)
    log(message: "Events Plist loaded \(structsDict)")

    // Write struct file
    let structSwiftFilePath = CommandLine.arguments[2]
    guard FileManager.default.fileExists(atPath: structSwiftFilePath) else {
        throw EventGeneratorError.swiftFileNotFound
    }

    // Generate struct string
    let structsString = try generateEvents(structsDict)
    log(message: "Events code correctly generated")

    // Write struct string in file
    log(message: "Generating swift code in: \(structSwiftFilePath)")
    try structsString.write(toFile: structSwiftFilePath, atomically: true, encoding: .utf8)
} catch {
    switch error {
    case EventGeneratorError.plistNotFound:
        log(message: "Invalid plist path")
    case EventGeneratorError.trackerMissing:
        log(message: "Tracker(s) missing in one or more event(s)")
    case EventGeneratorError.templateNotFound:
        log(message: "Error generating events code")
    case EventGeneratorError.templateMalformed:
        log(message: "Error generating events code")
    case EventGeneratorError.swiftFileNotFound:
        log(message: "Swift file not found")
    default:
        log(message: "Generic error")
    }
    exitWithError()
}

log(message: "**Swift code generated successfully**")
