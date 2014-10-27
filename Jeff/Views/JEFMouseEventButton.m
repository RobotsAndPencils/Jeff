//
//  JEFMouseEventButton.m
//  Jeff
//
//  Created by Brandon Evans on 2014-10-27.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFMouseEventButton.h"

@interface JEFMouseEventButton ()

@property (nonatomic, strong) NSTrackingArea *hoverTrackingArea;

@end

@implementation JEFMouseEventButton

#pragma mark - Lifecycle

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (!self) return nil;

    [self createTrackingArea];

    return self;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (!self) return nil;

    [self createTrackingArea];

    return self;
}

- (void)dealloc {
    [self removeTrackingArea:self.hoverTrackingArea];
}

#pragma mark - Mouse Events

- (void)mouseEntered:(NSEvent *)theEvent {
    [super mouseEntered:theEvent];
    if (self.mouseEnterHandler) self.mouseEnterHandler(self, theEvent);
}

- (void)mouseExited:(NSEvent *)theEvent {
    [super mouseExited:theEvent];
    if (self.mouseExitHandler) self.mouseExitHandler(self, theEvent);
}

- (void)mouseDown:(NSEvent *)theEvent {
    if (self.mouseDownHandler) self.mouseDownHandler(self, theEvent);
    [super mouseDown:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent {
    if (self.mouseUpHandler) self.mouseUpHandler(self, theEvent);
    [super mouseUp:theEvent];
}

#pragma mark - Private

- (void)createTrackingArea {
    NSTrackingAreaOptions focusTrackingAreaOptions = NSTrackingActiveInActiveApp | NSTrackingMouseEnteredAndExited | NSTrackingAssumeInside | NSTrackingInVisibleRect;
    self.hoverTrackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds options:focusTrackingAreaOptions owner:self userInfo:nil];
    [self addTrackingArea:self.hoverTrackingArea];
}

@end
