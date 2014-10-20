//
//  Constants.h
//  Jeff
//
//  Created by Brandon Evans on 2014-07-09.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#ifndef CONSTANTS_H
#define CONSTANTS_H

#import <tgmath.h>

extern NSString *const JEFRecordScreenShortcutKey;
extern NSString *const JEFRecordSelectionShortcutKey;

static inline CGFloat constrain(CGFloat value, CGFloat min, CGFloat max) {
    return fmin(fmax(value, min), max);
}

#endif