//
//  JEFCreditsTextView.m
//  Jeff
//
//  Created by Brandon Evans on 2014-08-05.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFCreditsTextView.h"

@implementation JEFCreditsTextView

// Prevent scrolling this text view
- (NSRect)adjustScroll:(NSRect)proposedVisibleRect {
    return CGRectZero;
}

@end
