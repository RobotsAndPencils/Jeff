//
//  JEFSelectionView.m
//  Jeff
//
//  Created by Brandon Evans on 2014-05-28.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFSelectionView.h"
#import <QuartzCore/QuartzCore.h>
#import "RSVerticallyCenteredTextFieldCell.h"
#import <tgmath.h>
#import <Carbon/Carbon.h>
#import <libextobjc/EXTKeyPathCoding.h>
#import "Constants.h"
#import "JEFColoredButton.h"

const CGFloat HandleSize = 5.0;
const CGFloat JEFSelectionMinimumWidth = 50.0;
const CGFloat JEFSelectionMinimumHeight = 50.0;
const CGFloat JEFSelectionViewInfoMargin = 20.0;
const CGFloat JEFSelectionConfirmButtonMargin = 20.0;
const CGFloat JEFSelectionConfirmButtonMinimumHeightToDisplayOutside = 50.0;

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

@interface JEFSelectionView ()

@property (nonatomic, strong) CAShapeLayer *shapeLayer;
@property (nonatomic, strong) CALayer *handlesLayer;
@property (nonatomic, strong) CAShapeLayer *overlayLayer;
@property (nonatomic, assign) NSPoint mouseDownPoint;
@property (nonatomic, assign) NSRect selectionRect;
@property (nonatomic, assign) BOOL hasMadeInitialSelection;

@property (nonatomic, assign) enum JEFHandleIndex clickedHandle;
@property (nonatomic, assign) NSPoint anchor;

@property (nonatomic, strong) JEFColoredButton *confirmRectButton;
@property (nonatomic, strong) NSVisualEffectView *infoContainer;

@end


@implementation JEFSelectionView

#pragma mark - NSView

- (id)initWithFrame:(NSRect)frameRect screen:(NSScreen *)screen {
    self = [super initWithFrame:frameRect];
    if (self) {
        self.wantsLayer = YES;

        _hasMadeInitialSelection = NO;

        NSTextField *infoTextField = [[NSTextField alloc] initWithFrame:CGRectZero];
        infoTextField.cell = [[RSVerticallyCenteredTextFieldCell alloc] init];
        infoTextField.font = [NSFont systemFontOfSize:18.0];
        infoTextField.alignment = NSCenterTextAlignment;
        infoTextField.stringValue = NSLocalizedString(@"RecordSelectionInfo", @"Instructions for the user to make a selection");

        CGFloat screenWidth = CGRectGetWidth(screen.frame);
        CGSize stringSize = [infoTextField.stringValue sizeWithAttributes:@{ NSFontAttributeName: infoTextField.font }];
        
        CGFloat width = fmin(stringSize.width + JEFSelectionViewInfoMargin * 2, screenWidth);
        CGFloat height = stringSize.height + JEFSelectionViewInfoMargin * 2;
        CGFloat x = (screenWidth - width) / 2;
        CGFloat y = 100.0;
        CGRect infoFrame = CGRectMake(x, y, width, height);
        
        _infoContainer = [[NSVisualEffectView alloc] initWithFrame:infoFrame];
        _infoContainer.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
        [_infoContainer addSubview:infoTextField];

        _overlayLayer = [CAShapeLayer layer];
        _overlayLayer.fillColor = [NSColor colorWithCalibratedWhite:0.5 alpha:0.5].CGColor;
        [self.layer addSublayer:_overlayLayer];
        [self updateOverlayPath];

        _confirmRectButton = [[JEFColoredButton alloc] initWithFrame:CGRectMake(0, 0, 100, 32)];
        _confirmRectButton.wantsLayer = YES;
        _confirmRectButton.buttonType = NSMomentaryLightButton;
        _confirmRectButton.backgroundColor = [NSColor colorWithCalibratedRed:78.0/255.0 green:215.0/255.0 blue:0.0/255.0 alpha:1];
        _confirmRectButton.cornerRadius = 5.0;
        _confirmRectButton.bezelStyle = NSRecessedBezelStyle;
        NSMutableParagraphStyle *centeredParagraphStyle = [[NSMutableParagraphStyle alloc] init];
        centeredParagraphStyle.alignment = NSCenterTextAlignment;
        NSShadow *shadow = [[NSShadow alloc] init];
        shadow.shadowBlurRadius = 0.0;
        shadow.shadowOffset = CGSizeMake(0.0, 0.5);
        shadow.shadowColor = [[NSColor darkGrayColor] colorWithAlphaComponent:0.5];
        NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:@"Record" attributes:@{ NSForegroundColorAttributeName: [NSColor whiteColor], NSFontAttributeName: [NSFont systemFontOfSize:16], NSParagraphStyleAttributeName: centeredParagraphStyle, NSShadowAttributeName: shadow }];
        _confirmRectButton.attributedTitle = attributedTitle;
        _confirmRectButton.alphaValue = 0.0;
        [_confirmRectButton setTarget:self];
        [_confirmRectButton setAction:@selector(confirmRect)];
        [self addSubview:_confirmRectButton];
        [self.layer addSublayer:_confirmRectButton.layer];

        infoTextField.frame = _infoContainer.bounds;
        [self addSubview:_infoContainer];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideInstructions) name:@"JEFRecordingSelectionMadeNotification" object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
    return YES;
}

- (void)confirmRect {
    if (CGRectEqualToRect(self.selectionRect, CGRectZero)) return;

    self.confirmRectButton.hidden = YES;
    [self.shapeLayer removeFromSuperlayer];
    [self.handlesLayer removeFromSuperlayer];

    [self display];

    if ([self.delegate respondsToSelector:@selector(selectionView:didSelectRect:)]) {
        [self.delegate selectionView:self didSelectRect:self.selectionRect];
    }
}

#pragma mark - NSResponder

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)cancelOperation:(id)sender {
    [self.delegate selectionViewDidCancel:self];
}

- (void)keyDown:(NSEvent *)theEvent {
    if (theEvent.keyCode == kVK_Return) {
        [self confirmRect];
        return;
    }
    [super keyDown:theEvent];
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

        self.handlesLayer = [CALayer layer];
        for (NSUInteger handleIndex = 0; handleIndex < 8; handleIndex += 1) {
            CAShapeLayer *handleLayer = [CAShapeLayer layer];
            handleLayer.lineWidth = 3.0;
            handleLayer.fillColor = [[NSColor darkGrayColor] colorWithAlphaComponent:0.75].CGColor;
            handleLayer.strokeColor = [NSColor whiteColor].CGColor;
            handleLayer.shadowColor = [NSColor blackColor].CGColor;
            handleLayer.shadowRadius = 2.0f;
            handleLayer.shadowOffset = NSMakeSize(0, -1);
            [self.handlesLayer addSublayer:handleLayer];
        }
        [self.layer addSublayer:self.handlesLayer];

        CABasicAnimation *dashAnimation;
        dashAnimation = [CABasicAnimation animationWithKeyPath:@keypath(self.shapeLayer, lineDashPhase)];
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
    [self updateHandlePaths];
    [self updateOverlayPath];

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
    else if (!CGSizeEqualToSize(self.selectionRect.size, CGSizeZero)) {
        self.hasMadeInitialSelection = YES;
        // This notification will hide the instructions on all displays, including the display with *this* view.
        // We don't need to call hideInstructions here for that reason
        [[NSNotificationCenter defaultCenter] postNotificationName:@"JEFRecordingSelectionMadeNotification" object:self];

        [self updateConfirmRectButtonFrame];
        [self showRecordButton];
    }
}

#pragma mark - Private

- (void)updateConfirmRectButtonFrame {
    CGRect newButtonRect = CGRectZero;
    newButtonRect.size = self.confirmRectButton.frame.size;
    CGPoint origin = CGPointZero;
    // The button should always be centered horizontally
    origin.x = CGRectGetMinX(self.selectionRect) + CGRectGetWidth(self.selectionRect) / 2 - CGRectGetWidth(newButtonRect) / 2;

    // Position the button in this preferred order:
    // Outside the bottom edge of the selection
    if (CGRectGetMinY(self.selectionRect) > JEFSelectionConfirmButtonMinimumHeightToDisplayOutside) {
        origin.y = CGRectGetMinY(self.selectionRect)  - CGRectGetHeight(newButtonRect) - JEFSelectionConfirmButtonMargin;
    }
    // Outside the top edge
    else if (CGRectGetHeight(self.bounds) - CGRectGetMaxY(self.selectionRect) > JEFSelectionConfirmButtonMinimumHeightToDisplayOutside) {
        origin.y = CGRectGetMaxY(self.selectionRect) + JEFSelectionConfirmButtonMargin;
    }
    // Inside the bottom edge
    else {
        origin.y = CGRectGetMinY(self.selectionRect) + JEFSelectionConfirmButtonMargin;
    }
    newButtonRect.origin = origin;

    self.confirmRectButton.frame = newButtonRect;
}

- (void)updateMarchingAntsPath {
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, self.selectionRect);
    self.shapeLayer.path = path;
    CGPathRelease(path);
}

- (void)updateHandlePaths {
    NSUInteger handleIndex = 0;
    for (CAShapeLayer *handleLayer in self.handlesLayer.sublayers) {
        NSRect handleRect = [self rectForHandleAtIndex:handleIndex];
        CGPathRef handlePath = CGPathCreateWithEllipseInRect(handleRect, NULL);
        handleLayer.path = handlePath;
        handleLayer.shadowPath = handlePath;
        CGPathRelease(handlePath);
        handleIndex += 1;
    }
}

- (void)updateOverlayPath {
    CGMutablePathRef overlayPath = CGPathCreateMutable();
    CGPathAddRect(overlayPath, NULL, CGRectMake(CGRectGetMinX(self.frame), CGRectGetMaxY(self.selectionRect), CGRectGetWidth(self.frame), CGRectGetMaxY(self.frame) - CGRectGetMaxY(self.selectionRect)));
    CGPathAddRect(overlayPath, NULL, CGRectMake(CGRectGetMinX(self.frame), CGRectGetMinY(self.selectionRect), CGRectGetMinX(self.frame) + CGRectGetMinX(self.selectionRect), CGRectGetHeight(self.selectionRect)));
    CGPathAddRect(overlayPath, NULL, CGRectMake(CGRectGetMaxX(self.selectionRect), CGRectGetMinY(self.selectionRect), CGRectGetWidth(self.frame) - CGRectGetMaxX(self.selectionRect), CGRectGetHeight(self.selectionRect)));
    CGPathAddRect(overlayPath, NULL, CGRectMake(CGRectGetMinX(self.frame), CGRectGetMinY(self.frame), CGRectGetWidth(self.frame), CGRectGetMinY(self.frame) + CGRectGetMinY(self.selectionRect)));
    self.overlayLayer.path = overlayPath;
    CGPathRelease(overlayPath);
}

- (void)offsetSelectionRectLocationByX:(CGFloat)x y:(CGFloat)y {
    self.selectionRect = ({
        CGRect selectionRect = self.selectionRect;
        CGPoint origin = self.selectionRect.origin;
        origin.x = fmax(fmin(origin.x + x, CGRectGetWidth(self.window.screen.frame)), 0);
        origin.y = fmax(fmin(origin.y + y, CGRectGetHeight(self.window.screen.frame)), 0);
        selectionRect.origin = origin;
        selectionRect;
    });

    // Constrain to the bounds of the current screen
    self.selectionRect = CGRectIntersection(CGRectMake(0, 0, CGRectGetWidth(self.window.screen.frame), CGRectGetHeight(self.window.screen.frame)), self.selectionRect);
}

- (void)hideInstructions {
    [NSAnimationContext currentContext].duration = 0.1;
    self.infoContainer.animator.alphaValue = 0.0;
}

- (void)showRecordButton {
    [NSAnimationContext currentContext].duration = 0.1;
    self.confirmRectButton.animator.alphaValue = 1.0;
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
