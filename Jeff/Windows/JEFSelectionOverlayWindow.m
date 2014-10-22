//
//  JEFSelectionOverlayWindow.m
//  Jeff
//
//  Created by Brandon Evans on 2014-05-28.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFSelectionOverlayWindow.h"

#import "JEFSelectionView.h"


#define kShadyWindowLevel (NSDockWindowLevel + 1000)


@interface JEFSelectionOverlayWindow () <JEFSelectionViewDelegate>

@property (nonatomic, copy) void(^completion)(JEFSelectionView *, NSRect, BOOL);

@end


@implementation JEFSelectionOverlayWindow

- (instancetype)initWithContentRect:(NSRect)contentRect completion:(void (^)(JEFSelectionView *, NSRect, BOOL))completion {
    self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];

    _completion = completion;

    self.backgroundColor = [NSColor clearColor];
    self.opaque = NO;
    self.level = kShadyWindowLevel;
    self.releasedWhenClosed = NO;
    JEFSelectionView *selectionView = [[JEFSelectionView alloc] initWithFrame:contentRect screen:self.screen];
    selectionView.delegate = self;
    self.contentView = selectionView;
    [self makeKeyAndOrderFront:self];
    self.ignoresMouseEvents = NO;
    
    return self;
}

- (BOOL)canBecomeKeyWindow {
    return YES;
}

#pragma mark - JEFSelectionViewDelegate

- (void)selectionView:(JEFSelectionView *)view didSelectRect:(NSRect)rect {
    if (self.completion) self.completion(view, rect, NO);
}

- (void)selectionViewDidCancel:(JEFSelectionView *)view {
    if (self.completion) self.completion(view, NSZeroRect, YES);
}

- (void)placeStopButtonInChildWindow:(NSButton *)stopButton {
    NSWindow *siblingOverlayWindow = [[NSWindow alloc] initWithContentRect:CGRectOffset(stopButton.frame, CGRectGetMinX(stopButton.window.frame), CGRectGetMinY(stopButton.window.frame)) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    siblingOverlayWindow.backgroundColor = [NSColor clearColor];
    siblingOverlayWindow.opaque = NO;
    siblingOverlayWindow.level = self.level + 1;
    siblingOverlayWindow.releasedWhenClosed = NO;
    siblingOverlayWindow.contentView = stopButton;
    siblingOverlayWindow.ignoresMouseEvents = NO;
    [self addChildWindow:siblingOverlayWindow ordered:NSWindowAbove];
}

@end
