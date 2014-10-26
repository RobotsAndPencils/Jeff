//
//  NSSharingService+ActivityType.m
//  Jeff
//
//  Created by Brandon Evans on 2014-10-25.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "NSSharingService+ActivityType.h"

@implementation NSSharingService (ActivityType)

- (NSString *)jef_activityType {
    NSRange range = [self.description rangeOfString:@"\\[com.apple.share.*\\]" options:NSRegularExpressionSearch];
    if (range.location == NSNotFound) return @"";
    range.location++; // Start after [
    range.length -= 2; // Remove both [ and ]
    return [self.description substringWithRange:range];
}

@end
