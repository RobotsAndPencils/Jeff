//
//  JEFOverlayWindow.m
//  Jeff
//
//  Created by Brandon Evans on 2014-05-28.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFOverlayWindow.h"

#import "SelectionView.h"


#define kShadyWindowLevel (NSDockWindowLevel + 1000)


@interface JEFOverlayWindow () <DrawMouseBoxViewDelegate>

@property (nonatomic, copy) void(^completion)(SelectionView *, NSRect, BOOL);

@end


@implementation JEFOverlayWindow

- (instancetype)initWithContentRect:(NSRect)contentRect completion:(void (^)(SelectionView *, NSRect, BOOL))completion {
    self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];

    _completion = completion;

    [self setBackgroundColor:[NSColor clearColor]];
    [self setOpaque:NO];
    [self setLevel:kShadyWindowLevel];
    [self setReleasedWhenClosed:NO];
    SelectionView *drawMouseBoxView = [[SelectionView alloc] initWithFrame:contentRect screen:self.screen];
    drawMouseBoxView.delegate = self;
    [self setContentView:drawMouseBoxView];
    [self makeKeyAndOrderFront:self];
    
    return self;
}

- (BOOL)canBecomeKeyWindow {
    return YES;
}

#pragma mark - DrawMouseBoxViewDelegate

- (void)selectionView:(SelectionView *)view didSelectRect:(NSRect)rect {
    if (self.completion) self.completion(view, rect, NO);
}

- (void)selectionViewDidCancel:(SelectionView *)view {
    if (self.completion) self.completion(view, NSZeroRect, YES);
}

@end
