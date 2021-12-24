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

// Log string prepending the name of the project
func log(msg: String) {
    print("TRACK: \(msg)")
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

func urlForTemplate(_ templateName: String) throws -> URL {

    var url: URL?
    
    let path: String? = Bundle.main.path(forResource: templateName, ofType: nil) // used by test target
    if path != nil {
        url = URL(fileURLWithPath: path!)
    } else {
        let dir = scriptPath()
        url = URL(fileURLWithPath: dir as String).appendingPathComponent(templateName) // used in the build phase
    }
    
    guard url != nil else {
        throw EventGeneratorError.templateNotFound
    }

    return url!
}

// Load the specific template

func stringFromTemplate(_ templateName: String) throws -> String {
    
    let url: URL = try urlForTemplate(templateName)
    var result: String?

    do {
        log(msg: "Load template \(url)")
        result = try String(contentsOf: url)
        result = result?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    } catch {
        log(msg: "Error loading template \(templateName)")
        throw EventGeneratorError.templateMalformed
    }
    
    return result!
}

private func loadEventPlist(_ plistPath: String) throws -> NSDictionary {
    
    let result = NSMutableDictionary()
    if FileManager.default.fileExists(atPath: plistPath) {
        var eventsDict: NSDictionary? = NSDictionary(contentsOfFile: plistPath)
        eventsDict = eventsDict?.object(forKey: "events") as? NSDictionary
        if eventsDict != nil {
            result.setDictionary(eventsDict as! [AnyHashable: Any])
        }
    } else {
        throw EventGeneratorError.plistNotFound
    }
    
    return result
}

private func sanitised(_ originalString: String) -> String {
    var result = originalString
    
    let components = result.components(separatedBy: .whitespacesAndNewlines)
    result = components.joined(separator: "")
    result = removeItemSuffixes(item: result)
    
    let componentsByUnderscore = result.components(separatedBy: CharacterSet.alphanumerics.inverted)

    if !componentsByUnderscore.isEmpty {
        result = ""
        for component in componentsByUnderscore {
            if component != componentsByUnderscore[0] {
                result.append(component.capitalizingFirstLetter())
            } else {
                result.append(component)
            }
        }
    }
    return result
}

func printHelp() {
    log(msg: "HELP: // TODO")
}

// MARK: - Structs generator helpers

private func generateEvents(_ events: [String: AnyObject]) throws -> String {
    // Load templates
    let structListTemplateString: String = try stringFromTemplate(EventTemplate.eventList.rawValue)
    let structTemplate: String = try stringFromTemplate(EventTemplate.event.rawValue)

    var resultString = structListTemplateString
    var structsArray: [String] = Array()
    
    for event: String in events.keys.sorted(by: >) {
        
        var objectNames: [String] = []

        let eventDic: [String: AnyObject]? = events[event] as? [String: AnyObject]

        guard let eventName: String = eventDic?[EventTemplatePlaceholder.eventName.rawValue] as? String else {
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

        let originalKeys: [Any] = eventDic![EventPlistKey.payload.rawValue] as! [Any]

        var originalStringKeys: [String] = []

        var cleanKeys: [String] = [] // Array of string items
        var objects: [Any] = [] // Array of object items?
        for key in originalKeys { // Go through payload items
            if key is String {
                let setKey = key as! String
                cleanKeys.append(sanitised(setKey)) // Sanitise keys // let cleanKeys:[String] = originalKeys.map{ sanitised($0) }
                originalStringKeys.append(setKey)
            } else if key is NSDictionary {
                objects.append(key)
            }
        }
        
        if !objects.isEmpty {
            for item in objects {
                let object = (item as! NSDictionary)
                let objectName = object["name"] as! String
                objectNames.append(objectName)
            }
        }
    
        // <*event_keyValueChain*> = kKey1 : key1 == "" ? NSNull() : key1 as String
        let eventKeyValueChain = generateEventKeyValueChain(cleanKeys, eventHasObjects: !objects.isEmpty)
        
        structString = replacePlaceholder(structString,
                                          placeholder: "<*\(EventTemplatePlaceholder.keyValueChain.rawValue)*>",
                                          value: eventKeyValueChain,
                                          placeholderType: "routine")

        if !objects.isEmpty { // Create array definition for each object item using name definiton
            let objectKeyValueKeyChain = generateObjectKeyValue(objectNames)
            structString = replacePlaceholder(structString,
                                              placeholder: "<*\(EventTemplatePlaceholder.objectKeyChain.rawValue)*>",
                                              value: objectKeyValueKeyChain,
                                              placeholderType: "routine")
        } else {
            structString = replacePlaceholder(structString,
                                              placeholder: "<*\(EventTemplatePlaceholder.objectKeyChain.rawValue)*>",
                                              value: "",
                                              placeholderType: "routine")
        }
        
        // <*event_cs_trackers_str*> = "console", "GA"
        let eventCsTrackers: String = try generateEventCsTrackers(eventDic![EventPlistKey.trackers.rawValue] as! [String])
        structString = replacePlaceholder(structString,
                                          placeholder: "<*\(EventTemplatePlaceholder.eventTrackers.rawValue)*>",
                                          value: eventCsTrackers,
                                          placeholderType: "routine")

        /*
         <*event_keysNames*> =
         private let kKey1 = "key1"
         private let kKey2 = "key2"
         */
        let eventKeyNames: String = try generateEventKeysNames(originalStringKeys)
        
        structString = replacePlaceholder(structString,
                                          placeholder: "<*\(EventTemplatePlaceholder.keysNames.rawValue)*>",
                                          value: eventKeyNames,
                                          placeholderType: "routine")

        let objectKeyNames: String = try generateEventKeysNames(objectNames)
        
        structString = replacePlaceholder(structString,
                                          placeholder: "<*\(EventTemplatePlaceholder.objectKeyNames.rawValue)*>",
                                          value: objectKeyNames,
                                          placeholderType: "routine")

        if !objects.isEmpty {
            let objectStructure = try generateObjectStructs(objects)
            structString = replacePlaceholder(structString,
                                              placeholder: "<*\(EventTemplatePlaceholder.objectStruct.rawValue)*>",
                                              value: objectStructure,
                                              placeholderType: "routine")
        } else {
            structString = replacePlaceholder(structString,
                                              placeholder: "<*\(EventTemplatePlaceholder.objectStruct.rawValue)*>",
                                              value: "",
                                              placeholderType: "routine")
        }
       
        /*
         <*event_keysVars*> =
         let key1 : String
         let key2 : String
         */
        
        let eventKeysVars: String = try generateKeyVariables(cleanKeys)
        let objectKeysVars: String = try generateObjectKeysVariables(objectNames)
        
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
        
        let eventInit: String = try generateEventInit(cleanKeys, objectNames)
        structString = replacePlaceholder(structString,
                                          placeholder: "<*\(EventTemplatePlaceholder.eventInit.rawValue)*>",
                                          value: eventInit,
                                          placeholderType: "routine")

        structsArray.append(structString)

    }
    
    // Base list template
    resultString = resultString.replacingOccurrences(of: "<*\(EventTemplatePlaceholder.eventList.rawValue)*>",
                                                     with: structsArray.joined(separator: "\n"),
                                                     options: .caseInsensitive)
    return resultString
}

private func replacePlaceholder(_ original: String, placeholder: String, value: String, placeholderType: String) -> String {
    
    if original.lengthOfBytes(using: String.Encoding.utf8) < 1 || placeholder.lengthOfBytes(using: String.Encoding.utf8) < 1 {
        return original
    }
    
    let valueToReplace: String
    var mutableValue = value
    if placeholder.contains("<*!") {
        mutableValue.replaceSubrange(mutableValue.startIndex...mutableValue.startIndex,
                                     with: String(mutableValue[value.startIndex])
                                         .capitalized) // Only first capitalised letter, maintain the rest immutated
        valueToReplace = mutableValue
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
    
    var resultArray: [String] = Array()
    for keyString in keys {
        var capKeyString = keyString
        capKeyString.replaceSubrange(capKeyString.startIndex...capKeyString.startIndex,
                                     with: String(capKeyString[capKeyString.startIndex]).capitalized)
        resultArray.append("k\(capKeyString): \(keyString) == \"\" ? NSNull() : \(keyString) as String")
    }
    
    if eventHasObjects {
        return "\n            " + resultArray.joined(separator: ", \n            ") + ",\n        "
    } else if !resultArray.isEmpty {
        return "\n            " + resultArray.joined(separator: ", \n            ") + "\n        "
    }
    
    return ":"
}

func generateObjectKeyValue(_ keys: [String]) -> String {
    
    var resultArray: [String] = Array()
    for keyString in keys {
        var capKeyString = keyString
        capKeyString.replaceSubrange(capKeyString.startIndex...capKeyString.startIndex,
                                     with: String(capKeyString[capKeyString.startIndex]).capitalized)
        resultArray.append("k\(capKeyString): \(keyString) == [] ? NSNull() : \(sanitised(keyString)).map { $0.asDict }")
    }
    
    if !resultArray.isEmpty {
        return "\n            " + resultArray.joined(separator: ", \n            ") + "\n        "
    }
    
    return ":"
}

func generateObjectStructs(_ objects: [Any]) throws -> String {
    
    var resultArray: [String] = Array()
    
    let structEventObjectTemplate: String = try stringFromTemplate(EventTemplate.eventObjectStruct.rawValue)
    
    for object in objects {
        let key = (object as! NSDictionary)
        let objectName = key["name"] as! String
        let objectParameters: [String] = key[EventPlistKey.objectPayload.rawValue] as! [String]
        var capItemName = objectName
        
        capItemName.replaceSubrange(capItemName.startIndex...capItemName.startIndex,
                                    with: String(capItemName[capItemName.startIndex]).capitalized)
        var structObjectKeyString = replacePlaceholder(structEventObjectTemplate,
                                                       placeholder: "<*\(EventTemplatePlaceholder.objectName.rawValue)*>",
                                                       value: sanitised(capItemName),
                                                       placeholderType: "routine")

        let objectKeysVars: String = try generateStructKeyVariables(objectParameters, keyType: "objectKey")
        
        structObjectKeyString = replacePlaceholder(structObjectKeyString,
                                                   placeholder: "<*\(EventTemplatePlaceholder.objectStructParams.rawValue)*>\n",
                                                   value: objectKeysVars,
                                                   placeholderType: "routine")

        let objectKeysInit: String = try generateEventObjectInit(objectParameters)
        
        structObjectKeyString = replacePlaceholder(structObjectKeyString,
                                                   placeholder: "<*\(EventTemplatePlaceholder.eventObjectInit.rawValue)*>\n",
                                                   value: objectKeysInit,
                                                   placeholderType: "routine")

        let structFunctionString = generateObjectDictionaryFunction(objectParameters: objectParameters)
        
        structObjectKeyString = replacePlaceholder(structObjectKeyString,
                                                   placeholder: "<*\(EventTemplatePlaceholder.objectDictionaryParameterList.rawValue)*>\n",
                                                   value: structFunctionString,
                                                   placeholderType: "routine")

        resultArray.append(structObjectKeyString)
    }
    
    if !resultArray.isEmpty {
        return "\n    " + resultArray.joined(separator: "\n\n    ") + "\n      "
    } else {
        return "\n" + resultArray.joined(separator: "\n") + "\n        "
    }
}

func removeItemSuffixes(item: String) -> String {
    item
        .replacingOccurrences(of: "_int", with: "")
        .replacingOccurrences(of: "_double", with: "")
        .replacingOccurrences(of: "_bool", with: "")
}

func generateObjectDictionaryFunction(objectParameters: [String]) -> String {
    var structureResult = ""
    var resultArray: [String] = Array()
    
    for item in objectParameters {
        let itemString = removeItemSuffixes(item: item).lowercasingFirstLetter()
        let paramString = "\"\(itemString)\""
        let assignString = paramString + " : " + sanitised(itemString).lowercasingFirstLetter()
        resultArray.append(assignString)
    }
    
    if !resultArray.isEmpty {
        structureResult = resultArray.joined(separator: ",\n             ")
    } else {
        structureResult = resultArray.joined(separator: "\n")
    }
    
    structureResult = "[\n             " + structureResult + "\n            ]"
    
    return structureResult
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
        var structKeyNameString = replacePlaceholder(structKeyNameTemplate,
                                                     placeholder: "<*\(EventTemplatePlaceholder.keyNameOriginal.rawValue)*>",
                                                     value: keyString,
                                                     placeholderType: "routine")
        structKeyNameString = replacePlaceholder(structKeyNameString,
                                                 placeholder: "<*!\(EventTemplatePlaceholder.keyName.rawValue)*>",
                                                 value: sanitised(keyString),
                                                 placeholderType: "routine")
        resultArray.append(structKeyNameString)
    }
    
    return !resultArray.isEmpty ? resultArray.joined(separator: "\n    ") : ""
}

private func generateKeyVariables(_ keys: [String]) throws -> String {
    
    let structVarTemplate: String = try stringFromTemplate(EventTemplate.keyVar.rawValue)
    var resultArray: [String] = Array()
    for keyString in keys {
        let structVarString = replacePlaceholder(structVarTemplate,
                                                 placeholder: "<*\(EventTemplatePlaceholder.keyName.rawValue)*>",
                                                 value: sanitised(keyString),
                                                 placeholderType: "eventStringParameter")
        resultArray.append(structVarString)
    }
    
    return !resultArray.isEmpty ? resultArray.joined(separator: "\n    ") : ""
}

private func generateStructKeyVariables(_ keys: [String], keyType: String) throws -> String {
    
    let structVarTemplate: String = try stringFromTemplate(EventTemplate.keyVar.rawValue)
    var resultArray: [String] = Array()
    
    for keyString in keys {
        if keyString.contains("_int") {
            let paramResultString = replacePlaceholder(structVarTemplate,
                                                       placeholder: "<*\(EventTemplatePlaceholder.keyName.rawValue)*>",
                                                       value: sanitised(keyString).lowercasingFirstLetter(),
                                                       placeholderType: "eventIntParameter")
            resultArray.append(paramResultString)
        } else if keyString.contains("_double") {
            let paramResultString = replacePlaceholder(structVarTemplate,
                                                       placeholder: "<*\(EventTemplatePlaceholder.keyName.rawValue)*>",
                                                       value: sanitised(keyString).lowercasingFirstLetter(),
                                                       placeholderType: "eventDoubleParameter")
            resultArray.append(paramResultString)
        } else if keyString.contains("_bool") {
            let paramResultString = replacePlaceholder(structVarTemplate,
                                                       placeholder: "<*\(EventTemplatePlaceholder.keyName.rawValue)*>",
                                                       value: sanitised(keyString).lowercasingFirstLetter(),
                                                       placeholderType: "eventBoolParameter")
            resultArray.append(paramResultString)
        } else {
            let paramResultString = replacePlaceholder(structVarTemplate,
                                                       placeholder: "<*\(EventTemplatePlaceholder.keyName.rawValue)*>",
                                                       value: sanitised(keyString).lowercasingFirstLetter(),
                                                       placeholderType: "eventStringParameter")
            resultArray.append(paramResultString)
        }
    }
    
    switch keyType {
    case "eventKey":
        return !resultArray.isEmpty ? resultArray.joined(separator: "\n    ") : ""
    case "objectKey":
        return !resultArray.isEmpty ? resultArray.joined(separator: "\n        ") : ""
    default:
        return !resultArray.isEmpty ? resultArray.joined(separator: "\n    ") : ""
    }
}

private func generateObjectKeysVariables(_ keys: [String]) throws -> String {
    
    let structVarTemplate: String = try stringFromTemplate(EventTemplate.objectKeyVar.rawValue)
    var resultArray: [String] = Array()
    for keyString in keys {
        var structVarString = replacePlaceholder(structVarTemplate,
                                                 placeholder: "<*\(EventTemplatePlaceholder.objectKeyName.rawValue)*>",
                                                 value: keyString,
                                                 placeholderType: "routine")
        structVarString = replacePlaceholder(structVarString,
                                             placeholder: "<*\(EventTemplatePlaceholder.formattedObjectKeyName.rawValue)*>",
                                             value: keyString.capitalizingFirstLetter(),
                                             placeholderType: "routine")
        resultArray.append(structVarString)
    }
    return !resultArray.isEmpty ? resultArray.joined(separator: "\n    ") : ""
}

private func generateEventInit(_ keys: [String], _ objectKeys: [String]) throws -> String {
    
    if keys.isEmpty {
        return "// MARK: Payload not configured"
    }
    
    var initTemplateString: String = try stringFromTemplate(EventTemplate.eventInit.rawValue)
    
    // Replace event_init_assigns_list
    let initAssignsTemplateString: String = try stringFromTemplate(EventTemplate.eventInitAssignsList.rawValue)
    
    // Replace event_init_params
    let initParamTemplateString: String = try stringFromTemplate(EventTemplate.eventInitParam.rawValue)
    
    var assignsResultArray: [String] = Array()
    var paramsResultArray: [String] = Array()
    
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
    if !objectKeys.isEmpty {
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
    }
    
    let eventInitAssignsString: String = assignsResultArray.joined(separator: "\n        ")
    
    initTemplateString = replacePlaceholder(initTemplateString,
                                            placeholder: "<*\(EventTemplatePlaceholder.eventInitAssignsList.rawValue)*>",
                                            value: eventInitAssignsString,
                                            placeholderType: "routine")

    let eventInitParamsAssignsString: String = paramsResultArray.joined(separator: ",\n                ")
    initTemplateString = replacePlaceholder(initTemplateString,
                                            placeholder: "<*\(EventTemplatePlaceholder.eventInitParams.rawValue)*>",
                                            value: eventInitParamsAssignsString,
                                            placeholderType: "routine")

    return initTemplateString
}

private func generateEventObjectInit(_ keys: [String]) throws -> String {
    
    if keys.isEmpty {
        return "// MARK: Payload not configured"
    }
    
    var initTemplateString: String = try stringFromTemplate(EventTemplate.eventObjectInit.rawValue)
    
    // Replace event_init_assigns_list
    let initAssignsTemplateString: String = try stringFromTemplate(EventTemplate.eventObjectInitAssignsList.rawValue)
    
    // Replace event_init_params
    let initParamTemplateString: String = try stringFromTemplate(EventTemplate.eventObjectInitParam.rawValue)
    
    var assignsResultArray: [String] = Array()
    var paramsResultArray: [String] = Array()
    
    for keyString in keys {
        let assignsResultString = replacePlaceholder(initAssignsTemplateString,
                                                     placeholder: "<*\(EventTemplatePlaceholder.objectKeyName.rawValue)*>",
                                                     value: sanitised(keyString).lowercasingFirstLetter(),
                                                     placeholderType: "routine")
        assignsResultArray.append(assignsResultString)
        
        if keyString.contains("_int") {
            let paramResultString = replacePlaceholder(initParamTemplateString,
                                                       placeholder: "<*\(EventTemplatePlaceholder.objectKeyName.rawValue)*>",
                                                       value: sanitised(keyString).lowercasingFirstLetter(),
                                                       placeholderType: "eventAssignedIntParameter")

            paramsResultArray.append(paramResultString)
        } else if keyString.contains("_double") {
            let paramResultString = replacePlaceholder(initParamTemplateString,
                                                       placeholder: "<*\(EventTemplatePlaceholder.objectKeyName.rawValue)*>",
                                                       value: sanitised(keyString).lowercasingFirstLetter(),
                                                       placeholderType: "eventAssignedDoubleParameter")

            paramsResultArray.append(paramResultString)
        } else if keyString.contains("_bool") {
            let paramResultString = replacePlaceholder(initParamTemplateString,
                                                       placeholder: "<*\(EventTemplatePlaceholder.objectKeyName.rawValue)*>",
                                                       value: sanitised(keyString).lowercasingFirstLetter(),
                                                       placeholderType: "eventAssignedBoolParameter")

            paramsResultArray.append(paramResultString)
        } else {
            let paramResultString = replacePlaceholder(initParamTemplateString,
                                                       placeholder: "<*\(EventTemplatePlaceholder.objectKeyName.rawValue)*>",
                                                       value: sanitised(keyString).lowercasingFirstLetter(),
                                                       placeholderType: "eventAssignedStringParameter")

            paramsResultArray.append(paramResultString)
        }
    }
    
    let eventInitAssignsString: String = assignsResultArray.joined(separator: "\n            ")
    initTemplateString = replacePlaceholder(initTemplateString,
                                            placeholder: "<*\(EventTemplatePlaceholder.eventObjectInitAssignsList.rawValue)*>",
                                            value: eventInitAssignsString,
                                            placeholderType: "routine")

    let eventInitParamsAssignsString: String = paramsResultArray.joined(separator: ",\n                    ")
    initTemplateString = replacePlaceholder(initTemplateString,
                                            placeholder: "<*\(EventTemplatePlaceholder.eventObjectInitParams.rawValue)*>",
                                            value: eventInitParamsAssignsString,
                                            placeholderType: "routine")

    return initTemplateString
}

private func exitWithError() {
//    printHelp()
    exit(1)
}

// ------------------------------------------------------------------------------------------------------------------------------

// MARK: - Main script

log(msg: "Generating Events Swift code...")

log(msg: "Script arguments:")
for argument in CommandLine.arguments {
    log(msg: "- \(argument)")
}

// Validate
if CommandLine.arguments.count < 3 {
    log(msg: "Wrong arguments")
    exitWithError()
}

do {
    // Load plist
    let plistPath = CommandLine.arguments[1]
    let structsDict = try loadEventPlist(plistPath)
    log(msg: "Events Plist loaded \(structsDict)")
    
    // Write struct file
    let structSwiftFilePath = CommandLine.arguments[2]
    if !FileManager.default.fileExists(atPath: structSwiftFilePath) {
        throw EventGeneratorError.swiftFileNotFound
    }
    
    // Generate struct string
    let structsString: String = try generateEvents(structsDict as! [String: AnyObject])
    log(msg: "Events code correctly generated")
    
    // Write struct string in file
    log(msg: "Generating swift code in: \(structSwiftFilePath)")
    try structsString.write(toFile: structSwiftFilePath, atomically: true, encoding: .utf8)
} catch EventGeneratorError.plistNotFound {
    log(msg: "Invalid plist path")
    exitWithError()
} catch EventGeneratorError.trackerMissing {
    log(msg: "Tracker(s) missing in one or more event(s)")
    exitWithError()
} catch EventGeneratorError.templateNotFound {
    log(msg: "Error generating events code")
    exitWithError()
} catch EventGeneratorError.templateMalformed {
    log(msg: "Error generating events code")
    exitWithError()
} catch EventGeneratorError.swiftFileNotFound {
    log(msg: "Swift file not found")
    exitWithError()
} catch {
    log(msg: "Generic error")
    exitWithError()
}

log(msg: "**Swift code generated successfully**")

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).uppercased() + dropFirst()
    }
    func lowercasingFirstLetter() -> String {
        return prefix(1).lowercased() + dropFirst()
    }
}
