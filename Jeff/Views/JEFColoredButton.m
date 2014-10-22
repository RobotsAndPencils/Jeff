//
//  JEFColoredButton.m
//  Jeff
//
//  Created by Brandon Evans on 2014-10-20.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFColoredButton.h"
#import "JEFColoredButtonCell.h"

@implementation JEFColoredButton

+ (Class)cellClass {
    return [JEFColoredButtonCell class];
}

- (void)setBackgroundColor:(NSColor *)backgroundColor {
    _backgroundColor = backgroundColor;
    self.needsDisplay = YES;
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    _cornerRadius = cornerRadius;
    self.needsDisplay = YES;
}

@end
