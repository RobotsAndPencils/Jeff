//
//  RSVerticallyCenteredTextField.m
//  RSCommon
//
//  Created by Daniel Jalkut on 6/17/06.
//  Copyright 2006 Red Sweater Software. All rights reserved.
//

#import "RSVerticallyCenteredTextFieldCell.h"

@interface RSVerticallyCenteredTextFieldCell ()

@property (nonatomic, assign) BOOL isEditingOrSelecting;

@end

@implementation RSVerticallyCenteredTextFieldCell

- (NSRect)drawingRectForBounds:(NSRect)theRect {
    // Get the parent's idea of where we should draw
    NSRect newRect = [super drawingRectForBounds:theRect];

    // When the text field is being
    // edited or selected, we have to turn off the magic because it screws up
    // the configuration of the field editor.  We sneak around this by
    // intercepting selectWithFrame and editWithFrame and sneaking a
    // reduced, centered rect in at the last minute.
    if (!self.isEditingOrSelecting) {
        // Get our ideal size for current text
        NSSize textSize = [self cellSizeForBounds:theRect];

        // Center that in the proposed rect
        CGFloat heightDelta = newRect.size.height - textSize.height;
        if (heightDelta > 0) {
            newRect.size.height -= heightDelta;
            newRect.origin.y += (heightDelta / 2);
        }
    }

    return newRect;
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength {
    aRect = [self drawingRectForBounds:aRect];
    self.isEditingOrSelecting = YES;
    [super selectWithFrame:aRect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
    self.isEditingOrSelecting = NO;
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent {
    aRect = [self drawingRectForBounds:aRect];
    self.isEditingOrSelecting = YES;
    [super editWithFrame:aRect inView:controlView editor:textObj delegate:anObject event:theEvent];
    self.isEditingOrSelecting = NO;
}

@end
