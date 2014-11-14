//
//  Constants.h
//  Jeff
//
//  Created by Brandon Evans on 2014-07-09.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import <tgmath.h>

extern NSString *const JEFRecordScreenShortcutKey;
extern NSString *const JEFRecordSelectionShortcutKey;

#pragma mark - Notifications

extern NSString *const JEFRecordingWasSharedNotification;
extern NSString *const JEFSyncingServiceAccountStateChanged;
extern NSString *const JEFOpenPopoverNotification;
extern NSString *const JEFClosePopoverNotification;
extern NSString *const JEFStartRecordingNotification;
extern NSString *const JEFStopRecordingNotification;
extern NSString *const JEFSetStatusViewNotRecordingNotification;
extern NSString *const JEFSetStatusViewRecordingNotification;

static inline CGFloat constrain(CGFloat value, CGFloat min, CGFloat max) {
    return fmin(fmax(value, min), max);
}