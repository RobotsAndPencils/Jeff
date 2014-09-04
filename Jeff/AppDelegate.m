//
//  AppDelegate.m
//  Jeff
//
//  Created by Brandon on 2/21/2014.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "AppDelegate.h"

#import <HockeySDK/HockeySDK.h>
#import <DropboxOSX/DropboxOSX.h>

#import "JEFPopoverRecordingsViewController.h"
#import "INPopoverController.h"
#import "JEFPopoverContentViewController.h"
#import "JEFUploaderProtocol.h"

NSString *const JEFClosePopoverNotification = @"JEFClosePopoverNotification";
NSString *const JEFSetStatusViewNotRecordingNotification = @"JEFSetStatusViewNotRecordingNotification";
NSString *const JEFSetStatusViewRecordingNotification = @"JEFSetStatusViewRecordingNotification";
NSString *const JEFStopRecordingNotification = @"JEFStopRecordingNotification";

CGFloat const JEFPopoverVerticalOffset = -3.0;

@interface AppDelegate () <BITHockeyManagerDelegate>

@property (strong, nonatomic) NSStatusItem *statusItem;
@property (strong, nonatomic) INPopoverController *popover;
@property (strong, nonatomic) id popoverTransiencyMonitor;

@end

@implementation AppDelegate

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self setupDropbox];

    [self setupStatusItem];
    [self setupPopover];
    [self registerDefaults];

    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"***REMOVED***"];
    [[BITHockeyManager sharedHockeyManager] startManager];
    [[BITHockeyManager sharedHockeyManager].crashManager setAutoSubmitCrashReport:YES];

    __weak typeof(self) weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:JEFClosePopoverNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [weakSelf closePopover:nil];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:JEFSetStatusViewNotRecordingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [weakSelf setStatusItemActionRecord:NO];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:JEFSetStatusViewRecordingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [weakSelf setStatusItemActionRecord:YES];
    }];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self closePopover:nil];
}

- (void)applicationWillResignActive:(NSNotification *)aNotification {
    [self closePopover:nil];
}

- (void)applicationWillHide:(NSNotification *)aNotification {
    [self closePopover:nil];
}

- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    [self showPopover:self.statusItem.button];
}

#pragma mark - Setup

- (void)setupDropbox {
    NSString *appKey = @"***REMOVED***";
    NSString *appSecret = @"***REMOVED***";
    NSString *root = kDBRootAppFolder;
    DBSession *session = [[DBSession alloc] initWithAppKey:appKey appSecret:appSecret root:root];
    [DBSession setSharedSession:session];

    NSAppleEventManager *eventManager = [NSAppleEventManager sharedAppleEventManager];
    [eventManager setEventHandler:self andSelector:@selector(getUrl:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)setupStatusItem {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.statusItem.button.image = [NSImage imageNamed:@"StatusItemTemplate"];
    self.statusItem.button.target = self;
    [self setStatusItemActionRecord:YES];
}

- (void)setupPopover {
    self.popover = [[INPopoverController alloc] init];
    self.popover.closesWhenApplicationBecomesInactive = YES;
    JEFPopoverContentViewController *popoverController = [[NSStoryboard storyboardWithName:@"JEFPopoverStoryboard" bundle:nil] instantiateInitialController];
    self.popover.contentViewController = popoverController;
    self.popover.animates = YES;
    self.popover.animationType = INPopoverAnimationTypeFadeOut;
    self.popover.color = [NSColor colorWithCalibratedWhite:0.9 alpha:1.0];
}

- (void)registerDefaults {
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{ @"selectedUploader": @(JEFUploaderTypeDropbox) }];
}

#pragma mark - Toggle popover

- (void)showPopover:(NSStatusBarButton *)sender {
    if (self.popover.popoverIsVisible) {
        [self closePopover:nil];
        return;
    }

    [self.popover presentPopoverFromRect:NSOffsetRect(sender.frame, 0, JEFPopoverVerticalOffset) inView:sender preferredArrowDirection:INPopoverArrowDirectionUp anchorsToPositionView:YES];

    if (!self.popoverTransiencyMonitor) {
        __weak __typeof(self) weakSelf = self;
        self.popoverTransiencyMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSLeftMouseDownMask|NSRightMouseDownMask handler:^(NSEvent* event) {
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
