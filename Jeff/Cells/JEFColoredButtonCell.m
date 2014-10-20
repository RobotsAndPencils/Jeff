//
//  JEFColoredButtonCell.m
//  Jeff
//
//  Created by Brandon Evans on 2014-10-20.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFColoredButtonCell.h"
#import "JEFColoredButton.h"
#import "Constants.h"
#import "NSColor+Darken.h"

@implementation JEFColoredButtonCell

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView {
    NSGraphicsContext *ctx = [NSGraphicsContext currentContext];

    JEFColoredButton *containingButton = (JEFColoredButton *)self.controlView;
    CGFloat roundedRadius = containingButton.cornerRadius;
    NSColor *backgroundColor = containingButton.backgroundColor;

    // Background color
    [ctx saveGraphicsState];
    NSBezierPath *backgroundPath = [NSBezierPath bezierPathWithRoundedRect:frame xRadius:roundedRadius yRadius:roundedRadius];
    [backgroundPath setClip];
    NSGradient *outerGradient = [[NSGradient alloc] initWithColorsAndLocations:backgroundColor, 0.0, [backgroundColor darken:0.1], 1.0, nil];
    [outerGradient drawInRect:backgroundPath.bounds angle:90.0];
    [ctx restoreGraphicsState];

    // Draw darker overlay if button is pressed
    if ([self isHighlighted]) {
        [ctx saveGraphicsState];
        [backgroundPath setClip];
        [[NSColor colorWithCalibratedWhite:0.0f alpha:0.35] setFill];
        NSRectFillUsingOperation(frame, NSCompositeSourceOver);
        [ctx restoreGraphicsState];
    }
}

// This inset properly centers the title with the current font settings as specified in JEFSelectionView.
// If this button gets used elsewhere with other settings it might be necessary to change how this is done.
- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView {
    frame = CGRectInset(frame, 0, 1.0);
    [title drawInRect:frame];
    return frame;
}

@end
