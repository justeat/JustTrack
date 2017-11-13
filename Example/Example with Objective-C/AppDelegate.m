//
//  AppDelegate.m
//  Example with Objective-C
//
//  Copyright © 2017 Just Eat Holding Ltd.
//

#import "AppDelegate.h"
#import "JustTrack_Example_ObjC-Swift.h"

@import JustTrack;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    JETracking *trackingService =  [self configureJustTrack];
    [trackingService trackEvent:[[JEEventViewScreen alloc] initWithScreenName:@"RestaurantView" screenData:@"fake screendata"]];
    [trackingService trackEvent:[[JEEventUser alloc] initWithAction:@"UserLogIn" response:@"success" extra:@"Additional info"] ];
    return YES;
}

- (JETracking *)configureJustTrack
{
    JETracking *tracker  = [JETracking sharedInstance];
    tracker.deliveryType = JETrackingDeliveryTypeBatch;
    [tracker loadDefaultTracker:JETrackerTypeConsoleLogger];
    
    [tracker setLogClosure:^(NSString * _Nonnull logString, enum JETrackingLogLevel logLevel) {
        NSLog(@"[JEEventTracker] [%ld] %@",logLevel,logString);
    }];
    [tracker enable];
    return tracker;
}

@end
