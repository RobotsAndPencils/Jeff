//
//  JEFAppController.m
//  Jeff
//
//  Created by Brandon Evans on 2014-10-08.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFAppController.h"

#import <Dropbox/DBAccountManager.h>
#import <libextobjc/EXTKeyPathCoding.h>
#import "INPopoverController.h"

#import "JEFDropboxRepository.h"
#import "JEFPopoverContentViewController.h"
#import "JEFQuartzRecorder.h"
#import "JEFDropboxService.h"
#import "JEFRecordingsController.h"
#import "JEFRecordingsRepository.h"
#import "JEFDropboxRepository.h"
#import "Constants.h"

CGFloat const JEFPopoverVerticalOffset = -3.0;

@interface JEFAppController ()

@property (strong, nonatomic) NSStatusItem *statusItem;
@property (strong, nonatomic) INPopoverController *popover;
@property (strong, nonatomic) id popoverTransiencyMonitor;
@property (strong, nonatomic) NSMutableArray *observers;
@property (strong, nonatomic) JEFRecordingsController *recordingsController;
@property (strong, nonatomic) NSObject<JEFSyncingService> *syncingService;
@property (strong, nonatomic) id<JEFRecordingsRepository> recordingsRepository;
@property (strong, nonatomic) JEFQuartzRecorder *recorder;

@end

@implementation JEFAppController

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _observers = [NSMutableArray array];
    _syncingService = [[JEFDropboxService alloc] init];
    _recordingsRepository = [[JEFDropboxRepository alloc] init];
    _recordingsController = [[JEFRecordingsController alloc] initWithSyncingService:_syncingService recordingsRepo:_recordingsRepository];
    _recorder = [[JEFQuartzRecorder alloc] init];

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

    [self.syncingService addObserver:self forKeyPath:@keypath(self.syncingService, totalUploadProgress.fractionCompleted) options:0 context:NULL];

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
    [self.syncingService removeObserver:self forKeyPath:@keypath(self.syncingService, totalUploadProgress.fractionCompleted)];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (self.syncingService.totalUploadProgress && !self.recorder.isRecording) {
        // Images are sequenced 1-31
        NSInteger imageNumber = (NSInteger)floor(self.syncingService.totalUploadProgress.fractionCompleted * 30.0) + 1;
        self.statusItem.button.image = [NSImage imageNamed:[NSString stringWithFormat:@"jeff_menu_ic_uploading_%ld", imageNumber]];
    }
    else {
        [self setStatusItemActionRecord:!self.recorder.isRecording];
    }
}

- (void)setupStatusItem {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.statusItem.button.image = [NSImage imageNamed:@"Menu Bar Normal Icon"];
    self.statusItem.button.target = self;
    [self setStatusItemActionRecord:YES];
}

- (void)setupPopover {
    self.popover = [[INPopoverController alloc] init];
    JEFPopoverContentViewController *popoverController = [[NSStoryboard storyboardWithName:@"JEFPopoverStoryboard" bundle:nil] instantiateInitialController];
    popoverController.recorder = self.recorder;
    popoverController.recordingsController = self.recordingsController;
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
        self.statusItem.button.image = [NSImage imageNamed:@"Menu Bar Normal Icon"];
        self.statusItem.button.action = @selector(showPopover:);
    }
    else {
        self.statusItem.button.image = [NSImage imageNamed:@"Menu Bar Stop Icon"];
        self.statusItem.button.action = @selector(stopRecording:);
    }
}
@end
