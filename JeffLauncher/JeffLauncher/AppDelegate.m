//
//  AppDelegate.m
//  JeffLauncher
//
//  Created by Brandon Evans on 2014-03-26.
//  Copyright (c) 2014 Robots and Pencils. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Check if main app is already running; if yes, do nothing and terminate helper app
    BOOL alreadyRunning = NO;
    BOOL isActive = NO;
    NSArray *running = [[NSWorkspace sharedWorkspace] runningApplications];
    for (NSRunningApplication *app in running) {
        if ([[app bundleIdentifier] isEqualToString:@"com.robotsandpencils.Jeff"]) {
            alreadyRunning = YES;
            isActive = [app isActive];
            break;
        }
    }

    if (!alreadyRunning || !isActive) {
        NSString *path = [[NSBundle mainBundle] bundlePath];
        NSMutableArray *pathComponents = [[path pathComponents] mutableCopy];
        [pathComponents removeLastObject];
        [pathComponents removeLastObject];
        [pathComponents removeLastObject];
        [pathComponents addObject:@"MacOS"];
        [pathComponents addObject:@"Jeff"];
        NSString *newPath = [NSString pathWithComponents:pathComponents];
        [[NSWorkspace sharedWorkspace] launchApplication:newPath];
    }
    [NSApp terminate:nil];
}

@end
