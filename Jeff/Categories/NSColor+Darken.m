//
//  NSColor+Darken.m
//  Jeff
//
//  Created by Brandon Evans on 2014-10-20.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "NSColor+Darken.h"
#import "Constants.h"

@implementation NSColor (Darken)

- (NSColor *)darken:(CGFloat)amount {
    CGFloat red, green, blue;
    amount = constrain(amount, 0.0, 1.0);

    [self getRed:&red green:&green blue:&blue alpha:NULL];
    red *= 1.0 - amount;
    green *= 1.0 - amount;
    blue *= 1.0 - amount;

    return [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:self.alphaComponent];
}

@end
