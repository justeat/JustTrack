<p align="center"><img src ="images/just-track.png?raw=true" /></p>

# JustTrack

[![Build Status](https://travis-ci.org/justeat/JustTrack.svg?branch=master)](https://travis-ci.org/justeat/JustTrack)
[![Version](https://img.shields.io/cocoapods/v/JustTrack.svg?style=flat)](http://cocoapods.org/pods/JustTrack)
[![License](https://img.shields.io/cocoapods/l/JustTrack.svg?style=flat)](http://cocoapods.org/pods/JustTrack)
[![Platform](https://img.shields.io/cocoapods/p/JustTrack.svg?style=flat)](http://cocoapods.org/pods/JustTrack)

The Just Eat solution to better manage the analytics tracking on iOS and improve the relationship with your BI team.

- [Just Eat Tech blog](https://tech.just-eat.com/2017/02/01/ios-event-tracking-with-justtrack/)

## Overview

At **Just Eat**, tracking events is a fundamental part of our business analysis and the information we collect informs our technical and strategic decisions. To collect the information required we needed a flexible, future-proof and easy to use tracking system that enables us to add, remove and swap the underlying integrations with analytical systems and services with minimal impact on our applications' code. We also wanted to solve the problem of keeping the required event metadata up-to-date whenever the requirements change.

**JustTrack** is the event tracking solution we built for that.

For any feature request, bug report or question please use the [Issues](https://github.com/justeat/JustTrack/issues) page and the appropriate [label](https://github.com/justeat/JustTrack/labels).

### Features:

* **Events** are declared in a `.plist` file and Swift code is **automatically** generated at build time from it.
* Events can be sent to multiple destinations (called *Trackers*) at the same time.
* Custom *Trackers* are easy to create and use.

## Installation

JustTrack is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```Ruby
pod "JustTrack"
```

Import it into your files like so:

```Swift
// swift
import JustTrack
```

```Objective-C (Pre 4.0)
// Objective-C
@import JustTrack;
```

#### In your target *Build Phases* add this script

```
xcrun --sdk macosx swift "${PODS_ROOT}/../../JustTrack/EventsGenerator/main.swift" "${SRCROOT}/JustTrack/Events.plist" "${SRCROOT}/JustTrack/TrackingEvents.swift"
```

Objective C (Versions before 4.0)

```
xcrun --sdk macosx swift "${PODS_ROOT}/../../JustTrack/JEEventsGenerator/main.swift" "${SRCROOT}/JustTrack/Events.plist" "${SRCROOT}/JustTrack/TrackingEvents.swift"
```

Where:

* ```${SRCROOT}/JustTrack/Events.plist``` is the path to your events declaration plist which can be anywhere in the project.
* ```"${SRCROOT}/JustTrack/TrackingEvents.swift"``` Is the destination file for the automatically generated Swift code.

_**NOTE:** Consider giving this script a meaningful name (e.g. "Name: JustTrack Events Generation")_


## Usage

Let's see how we use JustTrack:

### JustTrack Configuration

```
Swift

func configureJustTrack() -> EventTracking {
    // configure the tracking Singleton with settings and trackers
    
    let eventTracker: EventTracking = EventTracking.sharedInstance
    eventTracker.deliveryType = .batch
    
    eventTracker.logClosure = { (logString: String, logLevel: TrackingLogLevel) -> Void in
        print("[EventTracker] [\(logLevel)] \(logString)")
    }
    
    // load the default tracker, in this case the console tracker
    
    eventTracker.loadDefaultTracker(.consoleLogger)
    
    //enable JustTrack
    eventTracker.enable()
    
    return eventTracker
}

```

### Events Definition

One of the problems we found with existing solutions is that the events are declared in code and therefore can only be maintained by developers. Similarly, existing solutions offer very generic tracking facilities for developers. Because of that, whenever the required metadata associated with an event changes for any reason, the developer has to search the code base and update all instances of the event with the correct implementation. This of course is a very fragile process and is prone to errors.

JustTrack tries to solve these problems by declaring events in a `plist` file that is used to automatically generate equivalent definitions of the events in Swift that can be used in the app. This provides several benefits:

* Each event is uniquely identified
* The metadata associated with each event is type checked
* When the requirements for an event change, the developers can see it through build errors and warnings that will naturally occur
* Plists can be edited as XML, which means anybody in the business can edit them
* It's easy to search for events that are no longer used and deleted events won't compile

#### The Anatomy of an Event

An Event is made of:

* **Name**: the unique identifier
* **Registered Trackers**: List of event destinations (e.g. Google Analytics)
* **Payload**: The metadata associated with the event (at this time only String key-value pairs are supported)

##### The Plist format

<img src ="images/eventdec.png?raw=true" />

```xml
<key>User</key>
<dict>
    <key>registeredTrackers</key>
    <array>
        <string>console</string>
        <string>Firebase</string>
    </array>
    <key>payloadKeys</key>
    <array>
        <string>action</string>
        <string>response</string>
        <string>extra</string>
    </array>
</dict>
```

##### Generated Swift Class

```Swift
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
```

#### Using Events

```Swift
//Swift
let trackingService: EventTracking = configureJustTrack()
trackingService.trackEvent(EventUser(action: "UserLogIn", response: "success", extra: "Additional info"))
```

```Objective-C (Prior to 4.0)
//Objective-C
JETracking *trackingService =  [self configureJustTrack];
[trackingService trackEvent:[[JEEventUser alloc] initWithAction:@"UserLogIn" response:@"success" extra:@"Additional info"] ];
```

##### Hardcoded events

You can also create "hardcoded" events by implementing the Event protocol. However we do recommend that you use a `plist` file exclusively.

### Trackers

A Tracker is an object implementing the **Tracker** protocol and is loaded using: ```tracker.loadCustomTracker( ... )``` function. You can implement any tracker you want and **JustTrack** provides a few default trackers:

* [x] TrackerConsole - print events to the system's console
* [ ] FacebookTraker (not yet implemented)
* [ ] ~~GoogleAnalyticsTraker~~ (not yet implemented, Google's pods can't be used as a dependency in a pod)
* [ ] ~~TrakerFirebase~~ (not yet implemented, Google's pods can't be used as a dependency in a pod)

## Upgrading to v4.0

In version 4.0 **JustTrack** has been refactored to bring it up to date with current Swift standards. As such, **JustTrack** no longer supports Objective-C implementations. Please consider updating any applications that consume this feature.  As a result, the way events are named and must be called has been adjusted substatially. Please consider the following points when upgrading.

### Adopting Swift 

This update to **JustTrack** removes Objective-C attributes and prefixes, modernising the implementation in line with Swift standards whilst also removing the Objective-C interoperability. 

For example, a generated event class previously defined as:

```
JEEventUser
```

will now adopt the naming scheme:

```
EventUser
```
The effects of this change on your pre-defined events can be determined within the generated TrackingEvents.swift file. 

Please note that any programs that adopt this version will need to adopt this new naming scheme. 

### Updated Naming 

The naming of the events and associated payload has also been adjusted in order to ensure the camelCase naming convention is adopted throughout. 

### Preserving order across runs

Another change made within version 4.0 is the preservation of order within the auto-generated TrackingEvents.swift files. This allows for greater clarity when comparing changes. 

### Facilitating an array of objects

**JustTrack** now allows for the implementation of an array of objects as part of the payload. In order to implement such events, create a new item of type Dictionary and adhere to the objectPayloadKeys notation as detailed by the example event. An array of objects also supports different data types. To add these to your array of objects, simply append the varable type to the end of the value as follows: 

Integers:

```
itemNumber_int
```

Double:

```
itemPrice_double
```

Booleans:

```
itemAvailable_bool
```

## Upgrading to v3.0

In version 3.0 of **JustTrack** the Configuration class has been removed from the JETracker protocol.

If your client code uses Objective-C then your code should continue to function without changes when upgrading.

If your client code uses Swift then then you have two options.

Option 1) The simplest way to upgrade to v3.0 of the SDK is to reintroduce the Configuration typealias in your client code as follows:

```
public typealias Configuration = [String : String]
```

Option 2) Replace your initialisers with an equivalent where your arguments are passed in a strongly typed manner.  For example, this old init method....

```
public init(configuration: Configuration) {
    super.init()
    self.token = conifiguration[TokenKey]
}
```
might become...

```
public init(token: String) {
    super.init()
    self.token = token
}
```

## License

**JustTrack** is available under the Apache License, Version 2.0. See the LICENSE file for more info.


- Just Eat iOS team
