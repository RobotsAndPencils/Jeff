//
//  AppDelegate.h
//  Jeff
//
//  Created by Brandon on 2/21/2014.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SelectionView.h"

extern NSString *const JEFClosePopoverNotification;
extern NSString *const JEFDisplayPasteboardNotificationNotification;

@interface AppDelegate : NSObject <NSApplicationDelegate, DrawMouseBoxViewDelegate>

@end
