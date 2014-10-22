//
//  JEFAppController.m
//  Jeff
//
//  Created by Brandon Evans on 2014-10-08.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFPopoverContentViewController.h"
#import "INPopoverController.h"
#import "JEFAppController.h"
#import "JEFRecordingsManager.h"
#import <Dropbox/DBAccountManager.h>

NSString *const JEFOpenPopoverNotification = @"JEFOpenPopoverNotification";
NSString *const JEFClosePopoverNotification = @"JEFClosePopoverNotification";
NSString *const JEFSetStatusViewNotRecordingNotification = @"JEFSetStatusViewNotRecordingNotification";
NSString *const JEFSetStatusViewRecordingNotification = @"JEFSetStatusViewRecordingNotification";
NSString *const JEFStopRecordingNotification = @"JEFStopRecordingNotification";
CGFloat const JEFPopoverVerticalOffset = -3.0;

@interface JEFAppController ()

@property (strong, nonatomic) NSStatusItem *statusItem;
@property (strong, nonatomic) INPopoverController *popover;
@property (strong, nonatomic) id popoverTransiencyMonitor;
@property (strong, nonatomic) NSMutableArray *observers;

@end

@implementation JEFAppController

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _observers = [NSMutableArray array];

    [self setupStatusItem];
    [self setupPopover];

    __weak typeof(self) weakSelf = self;
    [self.observers addObject:[[NSNotificationCenter defaultCenter] addObserverForName:JEFOpenPopoverNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [weakSelf showPopover:weakSelf.statusItem.button];
    }]];
    [self.observers addObject:[[NSNotificationCenter defaultCenter] addObserverForName:JEFClosePopoverNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [weakSelf closePopover:nil];
    }]];
    [self.observers addObject:[[NSNotificationCenter defaultCenter] addObserverForName:JEFSetStatusViewNotRecordingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [weakSelf setStatusItemActionRecord:NO];
    }]];
    [self.observers addObject:[[NSNotificationCenter defaultCenter] addObserverForName:JEFSetStatusViewRecordingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [weakSelf setStatusItemActionRecord:YES];
    }]];

    // If Dropbox isn't set up yet, prompt the user by displaying the popover
    BOOL dropboxLinked = ([DBAccountManager sharedManager].linkedAccount != nil);
    if (!dropboxLinked) {
        // Give it a run loop otherwise the popover presents from the wrong rect inside the status bar item's button
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showPopover:self.statusItem.button];
        });
    }

    return self;
}

- (void)dealloc {
    for (id observer in self.observers) {
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    }
}

- (void)setupStatusItem {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.statusItem.button.image = [NSImage imageNamed:@"StatusItemTemplate"];
    self.statusItem.button.target = self;
    [self setStatusItemActionRecord:YES];
}

- (void)setupPopover {
    self.popover = [[INPopoverController alloc] init];
    JEFPopoverContentViewController *popoverController = [[NSStoryboard storyboardWithName:@"JEFPopoverStoryboard" bundle:nil] instantiateInitialController];
    popoverController.recordingsManager = [[JEFRecordingsManager alloc] init];
    self.popover.contentViewController = popoverController;
    self.popover.animates = NO;
    self.popover.closesWhenApplicationBecomesInactive = YES;
    self.popover.color = [self.popover.color colorWithAlphaComponent:1.0];
}

- (void)showPopover:(NSStatusBarButton *)sender {
    if (self.popover.popoverIsVisible) {
        [self closePopover:nil];
        return;
    }

    [self.popover presentPopoverFromRect:NSOffsetRect(sender.frame, 0, JEFPopoverVerticalOffset) inView:sender preferredArrowDirection:INPopoverArrowDirectionUp anchorsToPositionView:YES];

    if (!self.popoverTransiencyMonitor) {
        __weak __typeof(self) weakSelf = self;
        self.popoverTransiencyMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSLeftMouseDownMask | NSRightMouseDownMask handler:^(NSEvent *event) {
            [weakSelf closePopover:sender];
        }];
    }

    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (void)closePopover:(id)sender {
    if (self.popoverTransiencyMonitor) {
        [NSEvent removeMonitor:self.popoverTransiencyMonitor];
        self.popoverTransiencyMonitor = nil;
        [self.popover closePopover:nil];
    }
}

- (void)stopRecording:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:JEFStopRecordingNotification object:nil];
}

- (void)setStatusItemActionRecord:(BOOL)record {
    if (record) {
        self.statusItem.button.image = [NSImage imageNamed:@"StatusItemTemplate"];
        self.statusItem.button.action = @selector(showPopover:);
    }
    else {
        self.statusItem.button.image = [NSImage imageNamed:NSImageNameStopProgressTemplate];
        self.statusItem.button.action = @selector(stopRecording:);
    }
}
@end
