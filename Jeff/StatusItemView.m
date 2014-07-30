//
//  StatusItemView.m
//  Jeff
//
//  Created by Brandon on 2/21/2014.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "StatusItemView.h"

@implementation StatusItemView

- (id)initWithStatusItem:(NSStatusItem *)statusItem
{
    CGFloat itemWidth = [statusItem length];
    CGFloat itemHeight = [[NSStatusBar systemStatusBar] thickness];
    NSRect itemRect = NSMakeRect(0.0, 0.0, itemWidth, itemHeight);
    self = [super initWithFrame:itemRect];

    if (self != nil) {
        _statusItem = statusItem;
        _statusItem.view = self;
    }
    return self;
}

#pragma mark NSView

- (void)drawRect:(NSRect)dirtyRect {
	[self.statusItem drawStatusBarBackgroundInRect:dirtyRect withHighlight:self.isHighlighted];

    NSImage *icon = self.isHighlighted ? self.alternateImage : self.image;
    NSSize iconSize = [icon size];
    NSRect bounds = self.bounds;
    CGFloat iconX = roundf((NSWidth(bounds) - iconSize.width) / 2);
    CGFloat iconY = roundf((NSHeight(bounds) - iconSize.height) / 2);
    NSPoint iconPoint = NSMakePoint(iconX, iconY);

	[icon drawAtPoint:iconPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

#pragma mark Mouse Events

- (void)mouseDown:(NSEvent *)theEvent {
    if (self.clickHandler) self.clickHandler(self);
}

#pragma mark Properties

- (void)setHighlighted:(BOOL)newFlag {
    if (_isHighlighted == newFlag) return;
    _isHighlighted = newFlag;
    [self setNeedsDisplay:YES];
}

- (void)setImage:(NSImage *)newImage {
    if (_image != newImage) {
        _image = newImage;
        [self setNeedsDisplay:YES];
    }
}

- (void)setAlternateImage:(NSImage *)newImage {
    if (_alternateImage != newImage) {
        _alternateImage = newImage;
        if (self.isHighlighted) {
            [self setNeedsDisplay:YES];
        }
    }
}

@end
