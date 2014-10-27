//
//  JEFHoverStateButton.m
//  Jeff
//
//  Created by Brandon Evans on 2014-10-27.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFHoverStateButton.h"

@implementation JEFHoverStateButton

#pragma mark - Lifecycle

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (!self) return nil;

    [self setupDefaultColors];
    [self setupMouseEventHandlers];

    return self;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (!self) return nil;

    [self setupDefaultColors];
    [self setupMouseEventHandlers];

    return self;
}

#pragma mark - Private

- (void)setupDefaultColors {
    self.titleColor = [NSColor controlTextColor];
    self.titleHoverColor = [NSColor selectedControlTextColor];
    self.titleDownColor = [NSColor selectedControlTextColor];
}

- (void)setupMouseEventHandlers {
    __weak __typeof(self) weakSelf = self;

    self.mouseEnterHandler = ^(JEFMouseEventButton *button, NSEvent *theEvent) {
        [weakSelf updateTitleColor:weakSelf.titleHoverColor];
        if (button.isEnabled) {
            [[NSCursor pointingHandCursor] push];
        }
    };
    self.mouseExitHandler = ^(JEFMouseEventButton *button, NSEvent *theEvent) {
        [weakSelf updateTitleColor:weakSelf.titleColor];
        if (button.isEnabled) {
            [NSCursor pop];
        }
    };
    self.mouseDownHandler = ^(JEFMouseEventButton *button, NSEvent *theEvent) {
        [weakSelf updateTitleColor:weakSelf.titleDownColor];
    };
    self.mouseUpHandler = ^(JEFMouseEventButton *button, NSEvent *theEvent) {
        [weakSelf updateTitleColor:weakSelf.titleColor];
        if (button.isEnabled) {
            [NSCursor pop];
        }
    };
}

- (void)updateTitleColor:(NSColor *)color {
    NSMutableDictionary *mutableAttributes = [[self.attributedTitle attributesAtIndex:0 effectiveRange:NULL] mutableCopy];
    mutableAttributes[NSForegroundColorAttributeName] = color;
    self.attributedTitle = [[NSAttributedString alloc] initWithString:self.title attributes:mutableAttributes];
}

@end
