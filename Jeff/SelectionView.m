/*
     File: DrawMouseBoxView.m
 Abstract: Dims the screen and allows user to select a rectangle with a cross-hairs cursor
  Version: 2.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */

#import "SelectionView.h"
#import <QuartzCore/QuartzCore.h>


const CGFloat HandleSize = 5.0;
const CGFloat JEFSelectionMinimumWidth = 50.0;
const CGFloat JEFSelectionMinimumHeight = 50.0;

CGFloat constrain(CGFloat value, CGFloat min, CGFloat max) {
    return fmin(fmax(value, min), max);
}

typedef NS_ENUM(NSInteger, JEFHandleIndex) {
    JEFHandleIndexNone = -1,
    JEFHandleIndexBottomLeft = 0,
    JEFHandleIndexMiddleLeft,
    JEFHandleIndexTopLeft,
    JEFHandleIndexTopMiddle,
    JEFHandleIndexTopRight,
    JEFHandleIndexMiddleRight,
    JEFHandleIndexBottomRight,
    JEFHandleIndexBottomMiddle,
    JEFHandleIndexCount
};


@interface SelectionView ()

@property (nonatomic, strong) CAShapeLayer *shapeLayer;
@property (nonatomic, assign) NSPoint mouseDownPoint;
@property (nonatomic, assign) NSRect selectionRect;
@property (nonatomic, assign) BOOL hasMadeInitialSelection;
@property (nonatomic, assign) BOOL hasConfirmedSelection;

@property (nonatomic, assign) enum JEFHandleIndex clickedHandle;
@property (nonatomic, assign) NSPoint anchor;

@property (nonatomic, strong) NSButton *confirmRectButton;

@end


@implementation SelectionView

#pragma mark - NSView

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setWantsLayer:YES];

        _hasMadeInitialSelection = NO;
        _hasConfirmedSelection = NO;

        _confirmRectButton = [[NSButton alloc] initWithFrame:CGRectMake(0, 0, 100, 24)];
        [_confirmRectButton setButtonType:NSMomentaryLightButton];
        [_confirmRectButton setBezelStyle:NSInlineBezelStyle];
        [_confirmRectButton setTitle:@"Record"];
        _confirmRectButton.hidden = YES;
        [_confirmRectButton setTarget:self];
        [_confirmRectButton setAction:@selector(confirmRect)];
        [self addSubview:self.confirmRectButton];
    }
    return self;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor colorWithCalibratedWhite:0.5 alpha:0.5] setFill];

    NSBezierPath *path = [NSBezierPath bezierPathWithRect:self.selectionRect];
    [path appendBezierPath:[NSBezierPath bezierPathWithRect:self.frame]];
    path.windingRule = NSEvenOddWindingRule;
    [path fill];

    // Draw the "marching ants" CAShapeLayer
    [super drawRect:dirtyRect];

    if (!self.hasConfirmedSelection) {
        [self drawHandles];
    }
}

- (void)drawHandles {
    for (NSInteger handleIndex = JEFHandleIndexBottomLeft; handleIndex < JEFHandleIndexCount; handleIndex++) {
        [self drawHandleAtIndex:(enum JEFHandleIndex)handleIndex];
    }
}

- (void)drawHandleAtIndex:(enum JEFHandleIndex)handleIndex {
    NSRect handleRect = [self rectForHandleAtIndex:handleIndex];
    NSBezierPath *handlePath = [NSBezierPath bezierPathWithOvalInRect:handleRect];
    [handlePath setLineWidth:3.0];

    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor blackColor]];
    [shadow setShadowBlurRadius:2.0f];
    [shadow setShadowOffset:NSMakeSize(0.f, -1.f)];
    [shadow set];

    [[NSColor darkGrayColor] set];
    [handlePath fill];
    [[NSColor whiteColor] set];
    [handlePath stroke];
}

- (void)confirmRect {
    self.hasConfirmedSelection = YES;
    self.confirmRectButton.hidden = YES;
    [self.shapeLayer removeFromSuperlayer];

    [self display];

    [self.delegate selectionView:self didSelectRect:self.selectionRect];
}

#pragma mark - NSResponder

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)cancelOperation:(id)sender {
    [self.delegate selectionViewDidCancel:self];
}

#pragma mark - Mouse events

- (void)mouseDown:(NSEvent *)theEvent {
    if (self.hasMadeInitialSelection) {
        NSPoint mousePoint = [theEvent locationInWindow];
        self.clickedHandle = [self handleAtPoint:mousePoint];
        self.anchor = mousePoint;
    }
    else {
        self.mouseDownPoint = [theEvent locationInWindow];

        self.shapeLayer = [CAShapeLayer layer];
        self.shapeLayer.lineWidth = 1.0;
        self.shapeLayer.strokeColor = [[NSColor blackColor] CGColor];
        self.shapeLayer.fillColor = [[NSColor clearColor] CGColor];
        self.shapeLayer.lineDashPattern = @[ @3, @3 ];
        [self.layer addSublayer:self.shapeLayer];

        CABasicAnimation *dashAnimation;
        dashAnimation = [CABasicAnimation animationWithKeyPath:@"lineDashPhase"];
        [dashAnimation setFromValue:@0.0f];
        [dashAnimation setToValue:@6.0f];
        [dashAnimation setDuration:0.75f];
        [dashAnimation setRepeatCount:HUGE_VALF];
        [self.shapeLayer addAnimation:dashAnimation forKey:@"linePhase"];
    }
}

- (void)mouseDragged:(NSEvent *)theEvent {
    if (self.hasMadeInitialSelection) {
        NSPoint mousePoint = [theEvent locationInWindow];
        NSPoint newPoint;
        

        newPoint.x = mousePoint.x - self.anchor.x;
        newPoint.y = mousePoint.y - self.anchor.y;

        // Dragging to move the selection
        if (self.clickedHandle == JEFHandleIndexNone) {
            [self offsetSelectionRectLocationByX:newPoint.x y:newPoint.y];
        }
        // Dragging a selection handle
        else if (self.clickedHandle >= JEFHandleIndexNone && self.clickedHandle < JEFHandleIndexCount) {
            NSRect newBounds = [self newBoundsFromBounds:self.selectionRect forHandle:self.clickedHandle withDelta:newPoint];
            self.selectionRect = newBounds;
        }

        mousePoint = [self constrainMousePoint:mousePoint onHandle:self.clickedHandle inRect:self.selectionRect];
        self.anchor = mousePoint;
    } else {
        NSPoint curPoint = [theEvent locationInWindow];
        self.selectionRect = NSIntegralRect(NSMakeRect(
            MIN(self.mouseDownPoint.x, curPoint.x),
            MIN(self.mouseDownPoint.y, curPoint.y),
            MAX(self.mouseDownPoint.x, curPoint.x) - MIN(self.mouseDownPoint.x, curPoint.x),
            MAX(self.mouseDownPoint.y, curPoint.y) - MIN(self.mouseDownPoint.y, curPoint.y)));
    }

    [self updateConfirmRectButtonFrame];
    [self updateMarchingAntsPath];
    [self setNeedsDisplayInRect:[self bounds]];
}

- (NSPoint)constrainMousePoint:(NSPoint)mousePoint onHandle:(JEFHandleIndex)handle inRect:(NSRect)rect {
    switch (handle) {
        case JEFHandleIndexBottomLeft:
            return NSMakePoint(constrain(mousePoint.x, CGFLOAT_MIN, CGRectGetMinX(rect)), constrain(mousePoint.y, CGFLOAT_MIN, CGRectGetMinY(rect)));
        case JEFHandleIndexMiddleLeft:
            return NSMakePoint(constrain(mousePoint.x, CGFLOAT_MIN, CGRectGetMinX(rect)), mousePoint.y);
        case JEFHandleIndexTopLeft:
            return NSMakePoint(constrain(mousePoint.x, CGFLOAT_MIN, CGRectGetMinX(rect)), constrain(mousePoint.y, CGRectGetMaxY(rect), CGFLOAT_MAX));
        case JEFHandleIndexTopMiddle:
            return NSMakePoint(mousePoint.x, constrain(mousePoint.y, CGRectGetMaxY(rect), CGFLOAT_MAX));
        case JEFHandleIndexTopRight:
            return NSMakePoint(constrain(mousePoint.x, CGRectGetMaxX(rect), CGFLOAT_MAX), constrain(mousePoint.y, CGRectGetMaxY(rect), CGFLOAT_MAX));
        case JEFHandleIndexMiddleRight:
            return NSMakePoint(constrain(mousePoint.x, CGRectGetMaxX(rect), CGFLOAT_MAX), mousePoint.y);
        case JEFHandleIndexBottomRight:
            return NSMakePoint(constrain(mousePoint.x, CGRectGetMaxX(rect), CGFLOAT_MAX), constrain(mousePoint.y, CGFLOAT_MIN, CGRectGetMinY(rect)));
        case JEFHandleIndexBottomMiddle:
            return NSMakePoint(mousePoint.x, constrain(mousePoint.y, CGFLOAT_MIN, CGRectGetMinY(rect)));
        default:
            return mousePoint;
    }
}

- (void)mouseUp:(NSEvent *)theEvent {
    if (self.hasMadeInitialSelection) {
        self.clickedHandle = JEFHandleIndexNone;
    }
    else {
        self.hasMadeInitialSelection = YES;

        self.confirmRectButton.frame = ({
            CGRect centeredRect = CGRectZero;
            centeredRect.size = self.confirmRectButton.frame.size;
            CGPoint origin = CGPointZero;
            origin.x = CGRectGetMinX(self.selectionRect) + CGRectGetWidth(self.selectionRect) / 2 - CGRectGetWidth(centeredRect) / 2;
            origin.y = CGRectGetMinY(self.selectionRect) + CGRectGetHeight(self.selectionRect) / 2 - CGRectGetHeight(centeredRect) / 2;
            centeredRect.origin = origin;
            centeredRect;
        });
        self.confirmRectButton.hidden = NO;
    }
}

#pragma mark - Private

- (void)updateConfirmRectButtonFrame {
    self.confirmRectButton.frame = ({
        CGRect centeredRect = CGRectZero;
        centeredRect.size = self.confirmRectButton.frame.size;
        CGPoint origin = CGPointZero;
        origin.x = CGRectGetMinX(self.selectionRect) + CGRectGetWidth(self.selectionRect) / 2 - CGRectGetWidth(centeredRect) / 2;
        origin.y = CGRectGetMinY(self.selectionRect) + CGRectGetHeight(self.selectionRect) / 2 - CGRectGetHeight(centeredRect) / 2;
        centeredRect.origin = origin;
        centeredRect;
    });
}

- (void)updateMarchingAntsPath {
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, self.selectionRect);
    self.shapeLayer.path = path;
    CGPathRelease(path);
}

- (void)offsetSelectionRectLocationByX:(CGFloat)x y:(CGFloat)y {
    self.selectionRect = ({
        CGRect selectionRect = self.selectionRect;
        CGPoint origin = self.selectionRect.origin;
        origin.x += x;
        origin.y += y;
        selectionRect.origin = origin;
        selectionRect;
    });
}

#pragma mark - Handles

- (NSRect)rectForHandleAtIndex:(enum JEFHandleIndex)handleIndex {
    NSPoint handleCenter = NSZeroPoint;
    NSRect selectionBounds = [self selectionRect];

    switch (handleIndex) {
        case JEFHandleIndexBottomLeft:
            handleCenter.x = NSMinX(selectionBounds);
            handleCenter.y = NSMinY(selectionBounds);
            break;

        case JEFHandleIndexMiddleLeft:
            handleCenter.x = NSMinX(selectionBounds);
            handleCenter.y = NSMidY(selectionBounds);
            break;

        case JEFHandleIndexTopLeft:
            handleCenter.x = NSMinX(selectionBounds);
            handleCenter.y = NSMaxY(selectionBounds);
            break;

        case JEFHandleIndexTopMiddle:
            handleCenter.x = NSMidX(selectionBounds);
            handleCenter.y = NSMaxY(selectionBounds);
            break;

        case JEFHandleIndexTopRight:
            handleCenter.x = NSMaxX(selectionBounds);
            handleCenter.y = NSMaxY(selectionBounds);
            break;

        case JEFHandleIndexMiddleRight:
            handleCenter.x = NSMaxX(selectionBounds);
            handleCenter.y = NSMidY(selectionBounds);
            break;

        case JEFHandleIndexBottomRight:
            handleCenter.x = NSMaxX(selectionBounds);
            handleCenter.y = NSMinY(selectionBounds);
            break;

        case JEFHandleIndexBottomMiddle:
            handleCenter.x = NSMidX(selectionBounds);
            handleCenter.y = NSMinY(selectionBounds);
            break;

        default:
            break;
    }

    selectionBounds.origin = handleCenter;
    selectionBounds.size = NSZeroSize;
    return NSInsetRect(selectionBounds, -HandleSize, -HandleSize);
}

- (NSRect)newBoundsFromBounds:(NSRect)oldBounds forHandle:(enum JEFHandleIndex)handleIndex withDelta:(NSPoint)boundsDelta {
    NSRect newBounds = oldBounds;

    switch (handleIndex) {
        case JEFHandleIndexTopMiddle:
            newBounds.size.height += boundsDelta.y;
            break;

        case JEFHandleIndexMiddleRight:
            newBounds.size.width += boundsDelta.x;
            break;

        case JEFHandleIndexMiddleLeft:
            newBounds.size.width -= boundsDelta.x;
            newBounds.origin.x += boundsDelta.x;
            break;

        case JEFHandleIndexBottomMiddle:
            newBounds.size.height -= boundsDelta.y;
            newBounds.origin.y += boundsDelta.y;
            break;

        case JEFHandleIndexBottomLeft:
            newBounds.size.width -= boundsDelta.x;
            newBounds.origin.x += boundsDelta.x;
            newBounds.size.height -= boundsDelta.y;
            newBounds.origin.y += boundsDelta.y;
            break;

        case JEFHandleIndexTopLeft:
            newBounds.size.height += boundsDelta.y;
            newBounds.origin.x += boundsDelta.x;
            newBounds.size.width -= boundsDelta.x;
            break;

        case JEFHandleIndexTopRight:
            newBounds.size.width += boundsDelta.x;
            newBounds.size.height += boundsDelta.y;
            break;

        case JEFHandleIndexBottomRight:
            newBounds.size.width += boundsDelta.x;
            newBounds.origin.y += boundsDelta.y;
            newBounds.size.height -= boundsDelta.y;
            break;

        default:
            break;
    }

    NSSize minimumSize = newBounds.size;
    // Explicitly not using CGGeometry here so as not to normalize the rect
    if (newBounds.size.width < JEFSelectionMinimumWidth) {
        minimumSize.width = JEFSelectionMinimumWidth;
        if (handleIndex == JEFHandleIndexTopLeft || handleIndex == JEFHandleIndexMiddleLeft || handleIndex == JEFHandleIndexBottomLeft) {
            newBounds.origin.x = CGRectGetMaxX(oldBounds) - minimumSize.width;
        }
        else {
            newBounds.origin.x = oldBounds.origin.x;
        }
    }
    if (newBounds.size.height < JEFSelectionMinimumHeight) {
        minimumSize.height = JEFSelectionMinimumHeight;
        if (handleIndex == JEFHandleIndexBottomLeft || handleIndex == JEFHandleIndexBottomMiddle || handleIndex == JEFHandleIndexBottomRight) {
            newBounds.origin.y = CGRectGetMaxY(oldBounds) - minimumSize.height;
        }
        else {
            newBounds.origin.y = oldBounds.origin.y;
        }
    }
    newBounds.size = minimumSize;

    return newBounds;
}

- (enum JEFHandleIndex)handleAtPoint:(NSPoint)point {
    enum JEFHandleIndex handleIndex;
    NSRect handleRect;

    if (CGRectEqualToRect([self bounds], CGRectZero)) {
        return JEFHandleIndexNone;
    }
    else {
        for (handleIndex = JEFHandleIndexBottomLeft; handleIndex < JEFHandleIndexCount; handleIndex++) {
            handleRect = [self rectForHandleAtIndex:handleIndex];

            if (NSPointInRect(point, handleRect)) {
                return handleIndex;
            }
        }
    }

    return JEFHandleIndexNone;
}

@end
