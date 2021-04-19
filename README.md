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

```Objective-C
// Objective-C
@import JustTrack;
```

#### In your target *Build Phases* add this script

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

```Swift
func configureJustTrack() -> JETracking {
    // configure the tracking Singleton with settings and trackers
    let tracker: JETracking = JETracking.sharedInstance
    
    tracker.deliveryType = .batch
    
    tracker.logClosure = { (logString: String, logLevel: JETrackingLogLevel) -> Void in
        print("[JEEventTracker] [\(logLevel.rawValue)] \(logString)")
    }
    
    // load the default tracker, in this case the console tracker
    tracker.loadDefaultTracker(.consoleLogger)
    
    //enable JustTrack
    tracker.enable()
    
    return tracker
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
public class JEEventUser: NSObject, JEEvent {

    // JEEvent protocol
    public let name: String = "User"

    public var payload: Payload {
        return [kAction : action as NSObject, kResponse : response as NSObject, kExtra : extra as NSObject]
    }

    public var registeredTrackers: [String] {
        return ["console", "Firebase"]
    }

    // keys
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
```

#### Using Events

```Swift
//Swift
let trackingService: JETracking = configureJustTrack()
trackingService.trackEvent(JEEventUser(action: "UserLogIn", response: "success", extra: "Additional info"))
```

```Objective-C
//Objective-C
JETracking *trackingService =  [self configureJustTrack];
[trackingService trackEvent:[[JEEventUser alloc] initWithAction:@"UserLogIn" response:@"success" extra:@"Additional info"] ];
```

##### Hardcoded events

You can also create "hardcoded" events by implementing the JEEvent protocol. However we do recommend that you use a `plist` file exclusively.

### Trackers

A Tracker is an object implementing the **JETracker** protocol and is loaded using: ```tracker.loadCustomTracker( ... )``` function. You can implement any tracker you want and **JustTrack** provides a few default trackers:

* [x] JETrackerConsole - print events to the system's console
* [ ] JEFacebookTraker (not yet implemented)
* [ ] ~~JEGoogleAnalyticsTraker~~ (not yet implemented, Google's pods can't be used as a dependency in a pod)
* [ ] ~~JETrakerFirebase~~ (not yet implemented, Google's pods can't be used as a dependency in a pod)




## Upgrading to v3.0

In version 3.0 of JustTrack the Configuration class has been removed from the JETracker protocol.

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

JustTrack is available under the Apache License, Version 2.0. See the LICENSE file for more info.


- Just Eat iOS team
