//
//  JEFHoverStateButton.m
//  Jeff
//
//  Created by Brandon Evans on 2014-10-27.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFHoverStateButton.h"

@interface JEFHoverStateButton ()

@property (nonatomic, strong) NSTrackingArea *hoverTrackingArea;

@end

@implementation JEFHoverStateButton

#pragma mark - Lifecycle

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (!self) return nil;

    [self setupDefaults];
    [self createTrackingArea];

    return self;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (!self) return nil;

    [self setupDefaults];
    [self createTrackingArea];

    return self;
}

- (void)dealloc {
    [self removeTrackingArea:self.hoverTrackingArea];
}

#pragma mark - Mouse Events

- (void)mouseEntered:(NSEvent *)theEvent {
    [super mouseEntered:theEvent];
    [self updateTitleColor:self.titleHoverColor];
    if (self.isEnabled) {
        [[NSCursor pointingHandCursor] push];
    }
}

- (void)mouseExited:(NSEvent *)theEvent {
    [super mouseExited:theEvent];
    [self updateTitleColor:self.titleColor];
    if (self.isEnabled) {
        [NSCursor pop];
    }
}

- (void)mouseDown:(NSEvent *)theEvent {
    [self updateTitleColor:self.titleDownColor];
    [super mouseDown:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent {
    [self updateTitleColor:self.titleColor];
    [super mouseUp:theEvent];
    if (self.isEnabled) {
        [NSCursor pop];
    }
}

#pragma mark - Private

- (void)setupDefaults {
    self.titleColor = [NSColor controlTextColor];
    self.titleHoverColor = [NSColor selectedControlTextColor];
    self.titleDownColor = [NSColor selectedControlTextColor];
}

- (void)createTrackingArea {
    NSTrackingAreaOptions focusTrackingAreaOptions = NSTrackingActiveInActiveApp | NSTrackingMouseEnteredAndExited | NSTrackingAssumeInside | NSTrackingInVisibleRect;
    self.hoverTrackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds options:focusTrackingAreaOptions owner:self userInfo:nil];
    [self addTrackingArea:self.hoverTrackingArea];
}

- (void)updateTitleColor:(NSColor *)color {
    NSMutableDictionary *mutableAttributes = [[self.attributedTitle attributesAtIndex:0 effectiveRange:NULL] mutableCopy];
    mutableAttributes[NSForegroundColorAttributeName] = color;
    self.attributedTitle = [[NSAttributedString alloc] initWithString:self.title attributes:mutableAttributes];
}

@end
