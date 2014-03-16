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

#import "StatusItemView.h"
#import "PopoverContentViewController.h"
#import "Recorder.h"
#import "Converter.h"
#import "RBKDepositBoxManager.h"
#import "JEFRecording.h"
#import "JEFUploaderProtocol.h"
#import "JEFDropboxUploader.h"
#import "JEFDepositBoxUploader.h"

#define kShadyWindowLevel (NSDockWindowLevel + 1000)

@interface AppDelegate () <BITHockeyManagerDelegate, NSUserNotificationCenterDelegate>

@property (strong, nonatomic) StatusItemView *statusItemView;
@property (strong, nonatomic) NSPopover *popover;
@property (strong, nonatomic) id popoverTransiencyMonitor;
@property (strong, nonatomic) NSMutableArray *overlayWindows;

@property (strong, nonatomic) NSMutableArray *recentRecordings;

@end

@implementation AppDelegate

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.overlayWindows = [NSMutableArray array];
    self.recentRecordings = [self loadRecentRecordings];

    [self setupDropbox];

    [self setupStatusItem];
    [self setupPopover];

    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"8937bcd0d2b85a5ebe3ae3c924af1efb" companyName:@"Brandon Evans" delegate:self];
    [[BITHockeyManager sharedHockeyManager] startManager];
    [[BITHockeyManager sharedHockeyManager].crashManager setAutoSubmitCrashReport: YES];

    [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;

    [[NSNotificationCenter defaultCenter] addObserverForName:@"ClosePopover" object:nil queue:[NSOperationQueue currentQueue] usingBlock:^(NSNotification *note) {
        [self closePopover:nil];
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
}

#pragma mark - Setup

- (void)setupDropbox {
    NSString *appKey = @"iugqsnjvza6fuub";
    NSString *appSecret = @"pucvuohcbvte3z8";
    NSString *root = kDBRootAppFolder;
    DBSession *session = [[DBSession alloc] initWithAppKey:appKey appSecret:appSecret root:root];
    [DBSession setSharedSession:session];

    NSAppleEventManager *eventManager = [NSAppleEventManager sharedAppleEventManager];
    [eventManager setEventHandler:self andSelector:@selector(getUrl:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)setupStatusItem {
    NSStatusItem *statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.statusItemView = [[StatusItemView alloc] initWithStatusItem:statusItem];
    [self setStatusItemActionRecord:YES];
}

- (void)setupPopover {
    self.popover = [[NSPopover alloc] init];
    self.popover.behavior = NSPopoverBehaviorTransient;
    PopoverContentViewController *popoverController = [[PopoverContentViewController alloc] initWithNibName:@"PopoverContentView" bundle:nil];
    popoverController.recentRecordings = self.recentRecordings;
    self.popover.contentViewController = popoverController;
    self.popover.animates = NO;
}

#pragma mark - Toggle popover

- (void)showPopover:(StatusItemView *)sender {
    [self.statusItemView setHighlighted:YES];
    if (self.popover.shown) return;

    [self.popover showRelativeToRect:sender.frame ofView:sender preferredEdge:NSMinYEdge];

    if (!self.popoverTransiencyMonitor) {
        __weak __typeof(self) weakSelf = self;
        self.popoverTransiencyMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSLeftMouseDownMask|NSRightMouseDownMask handler:^(NSEvent* event) {
            [weakSelf closePopover:sender];
        }];
    }

    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (void)closePopover:(id)sender {
    [self.statusItemView setHighlighted:NO];
    if (self.popoverTransiencyMonitor) {
        [NSEvent removeMonitor:self.popoverTransiencyMonitor];
        self.popoverTransiencyMonitor = nil;
        [self.popover close];
    }
}

- (void)setStatusItemActionRecord:(BOOL)record {
    if (record) {
        self.statusItemView.image = [NSImage imageNamed:NSImageNameRightFacingTriangleTemplate];
        self.statusItemView.alternateImage = [NSImage imageNamed:NSImageNameRightFacingTriangleTemplate];
        self.statusItemView.action = @selector(showPopover:);
    }
    else {
        self.statusItemView.image = [NSImage imageNamed:NSImageNameStopProgressTemplate];
        self.statusItemView.action = @selector(stopRecording:);
    }
}

#pragma mark - Recording

- (void)recordScreen:(id)sender {
    [self setStatusItemActionRecord:NO];
    [self closePopover:nil];

    [Recorder screenRecordingWithCompletion:^(NSURL *movieURL) {
        [Converter convertMOVAtURLToGIF:movieURL completion:^(NSURL *gifURL) {
            [[NSFileManager defaultManager] removeItemAtPath:[movieURL path] error:nil];
            [self uploadGIFAtURL:gifURL];
        }];
    }];
}

- (void)recordSelection:(id)sender {
    [self closePopover:nil];

	for (NSScreen* screen in [NSScreen screens]) {
		NSRect frame = [screen frame];
		NSWindow * window = [[NSWindow alloc] initWithContentRect:frame styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
        [window setBackgroundColor:[NSColor clearColor]];
        [window setOpaque:NO];
		[window setLevel:kShadyWindowLevel];
		[window setReleasedWhenClosed:NO];
		SelectionView * drawMouseBoxView = [[SelectionView alloc] initWithFrame:frame];
		drawMouseBoxView.delegate = self;
		[window setContentView:drawMouseBoxView];
		[window makeKeyAndOrderFront:self];

        [self.overlayWindows addObject:window];
	}

	[[NSCursor crosshairCursor] push];
}

- (void)stopRecording:(id)sender {
    [Recorder finishRecording];
    [self setStatusItemActionRecord:YES];
}

#pragma mark - DrawMouseBoxViewDelegate

- (void)selectionView:(SelectionView *)view didSelectRect:(NSRect)rect {
    [self setStatusItemActionRecord:NO];

    for (NSWindow* window in self.overlayWindows) {
        [window setIgnoresMouseEvents:YES];
    }

	// Map point into global coordinates.
    NSRect globalRect = rect;
    NSRect windowRect = [[view window] frame];
    globalRect = NSOffsetRect(globalRect, windowRect.origin.x, windowRect.origin.y);
	globalRect.origin.y = CGDisplayPixelsHigh(CGMainDisplayID()) - globalRect.origin.y;

    // Get a list of online displays with bounds that include the specified point.
	CGDirectDisplayID displayID = CGMainDisplayID();
	uint32_t matchingDisplayCount = 0;
	CGError error = CGGetDisplaysWithPoint(NSPointToCGPoint(globalRect.origin), 1, &displayID, &matchingDisplayCount);
	if ((error == kCGErrorSuccess) && (matchingDisplayCount == 1)) {
        [Recorder recordRect:rect display:displayID completion:^(NSURL *movieURL) {
            [self.overlayWindows makeObjectsPerformSelector:@selector(close)];
            [self.overlayWindows removeAllObjects];

            [Converter convertMOVAtURLToGIF:movieURL completion:^(NSURL *gifURL) {
                [[NSFileManager defaultManager] removeItemAtPath:[movieURL path] error:nil];
                [self uploadGIFAtURL:gifURL];
            }];
        }];
    }

	[[NSCursor currentCursor] pop];
}

- (void)uploadGIFAtURL:(NSURL *)gifURL {
    [[self uploader] uploadGIF:gifURL withName:[[gifURL path] lastPathComponent] completion:^(BOOL succeeded, NSURL *publicURL, NSError *error){
        [[NSFileManager defaultManager] removeItemAtPath:[gifURL path] error:nil];

        JEFRecording *newRecording = [JEFRecording recordingWithURL:publicURL];
        [self insertObject:newRecording inRecentClipsAtIndex:[self countOfRecentClips]];
        [self saveRecentRecordings];

        [newRecording copyURLStringToPasteboard];
        [self displayPasteboardUserNotification];
    }];
}

- (id <JEFUploaderProtocol>)uploader {
    enum JEFUploaderType uploaderType = (enum JEFUploaderType)[[NSUserDefaults standardUserDefaults] integerForKey:@"selectedUploader"];
    switch (uploaderType) {
        case JEFUploaderTypeDropbox:
            return [JEFDropboxUploader uploader];
        case JEFUploaderTypeDepositBox:
        default:
            return [JEFDepositBoxUploader uploader];
    }
}

#pragma mark - Saving recent recordings

- (NSString *)userDataFilePathForUserID:(NSString *)userID {
    return [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/userID"] stringByAppendingPathExtension:@"plist"];
}

- (NSMutableArray *)loadRecentRecordings {
    NSString *filePath = [self userDataFilePathForUserID:nil];
    NSMutableDictionary *userData = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    if (!userData) {
        userData = [@{} mutableCopy];
        userData[@"recentRecordings"] = [NSKeyedArchiver archivedDataWithRootObject:[@[] mutableCopy]];
        [userData writeToFile:filePath atomically:YES];
    }
    return [NSKeyedUnarchiver unarchiveObjectWithData:userData[@"recentRecordings"]];
}

- (void)saveRecentRecordings {
    NSString *filePath = [self userDataFilePathForUserID:nil];
    NSMutableDictionary *userData = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    userData[@"recentRecordings"] = [NSKeyedArchiver archivedDataWithRootObject:self.recentRecordings];
    [userData writeToFile:filePath atomically:YES];
}

#pragma mark - Recent Clips KVO

- (NSUInteger)countOfRecentClips {
    return [self.recentRecordings count];
}

- (void)insertObject:(JEFRecording *)recording inRecentClipsAtIndex:(NSUInteger)index {
    [self.recentRecordings insertObject:recording atIndex:index];
}

- (void)insertRecentClips:(NSArray *)array atIndexes:(NSIndexSet *)indexes {
    [self.recentRecordings insertObjects:array atIndexes:indexes];
}

- (void)removeObjectFromRecentClipsAtIndex:(NSUInteger)index {
    [self.recentRecordings removeObjectAtIndex:index];
}

- (void)removeRecentClipsAtIndexes:(NSIndexSet *)indexes {
    [self.recentRecordings removeObjectsAtIndexes:indexes];
}

#pragma mark - NSUserNotificationCenterDelegate

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
    return YES;
}

#pragma mark - Private

- (void)displayPasteboardUserNotification {
    NSUserNotification *publishedNotification = [[NSUserNotification alloc] init];
    publishedNotification.title = NSLocalizedString(@"GIFSharedSuccessNotificationTitle", nil);
    publishedNotification.informativeText = NSLocalizedString(@"GIFSharedSuccessNotificationBody", nil);
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:publishedNotification];
}

@end
