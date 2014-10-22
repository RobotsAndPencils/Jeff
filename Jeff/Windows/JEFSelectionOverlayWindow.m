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
    JEFSelectionView *drawMouseBoxView = [[JEFSelectionView alloc] initWithFrame:contentRect screen:self.screen];
    drawMouseBoxView.delegate = self;
    self.contentView = drawMouseBoxView;
    [self makeKeyAndOrderFront:self];
    self.ignoresMouseEvents = NO;
    
    return self;
}

- (BOOL)canBecomeKeyWindow {
    return YES;
}

#pragma mark - DrawMouseBoxViewDelegate

- (void)selectionView:(JEFSelectionView *)view didSelectRect:(NSRect)rect {
    if (self.completion) self.completion(view, rect, NO);
}

- (void)selectionViewDidCancel:(JEFSelectionView *)view {
    if (self.completion) self.completion(view, NSZeroRect, YES);
}

@end
