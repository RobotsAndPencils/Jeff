//
//  AppDelegate.m
//  Jeff
//
//  Created by Brandon on 2/21/2014.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "AppDelegate.h"
#import "StatusItemView.h"
#import "PopoverContentViewController.h"
#import "Recorder.h"
#import "Converter.h"
#import "RBKDepositBoxManager.h"

#define kShadyWindowLevel (NSDockWindowLevel + 1000)

@interface AppDelegate ()

@property (strong, nonatomic) StatusItemView *statusItemView;
@property (strong, nonatomic) NSPopover *popover;
@property (strong, nonatomic) id popoverTransiencyMonitor;
@property (strong, nonatomic) NSMutableArray *overlayWindows;

@end

@implementation AppDelegate

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.overlayWindows = [NSMutableArray array];

    [self setupStatusItem];
    [self setupPopover];
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

#pragma mark - Setup

- (void)setupStatusItem {
    NSStatusItem *statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.statusItemView = [[StatusItemView alloc] initWithStatusItem:statusItem];
    [self setStatusItemActionRecord:YES];
}

- (void)setupPopover {
    self.popover = [[NSPopover alloc] init];
    self.popover.behavior = NSPopoverBehaviorTransient;
    self.popover.contentViewController = [[PopoverContentViewController alloc] initWithNibName:@"PopoverContentView" bundle:nil];
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
            [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[ gifURL ]];
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

	/* Map point into global coordinates. */
    NSRect globalRect = rect;
    NSRect windowRect = [[view window] frame];
    globalRect = NSOffsetRect(globalRect, windowRect.origin.x, windowRect.origin.y);
	globalRect.origin.y = CGDisplayPixelsHigh(CGMainDisplayID()) - globalRect.origin.y;
	CGDirectDisplayID displayID = CGMainDisplayID();
	uint32_t matchingDisplayCount = 0;
    /* Get a list of online displays with bounds that include the specified point. */
	CGError error = CGGetDisplaysWithPoint(NSPointToCGPoint(globalRect.origin), 1, &displayID, &matchingDisplayCount);
	if ((error == kCGErrorSuccess) && (matchingDisplayCount == 1)) {
        /* Add the display as a capture input. */
        [Recorder recordRect:rect display:displayID completion:^(NSURL *movieURL) {
            [self.overlayWindows makeObjectsPerformSelector:@selector(close)];
            [self.overlayWindows removeAllObjects];

            [Converter convertMOVAtURLToGIF:movieURL completion:^(NSURL *gifURL) {
                [[NSFileManager defaultManager] removeItemAtPath:[movieURL path] error:nil];
                [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[ gifURL ]];

                NSString *uuid = [[NSUUID UUID] UUIDString];
                [[RBKDepositBoxManager sharedManager] uploadFileAtPath:[gifURL path] mimeType:@"image/gif" toDepositBoxWithUUID:uuid fileExistsOnDepositBox:NO completionHandler:^(BOOL suceeded) {
                    NSURL *webURL = [NSURL URLWithString:uuid relativeToURL:[NSURL URLWithString:@"https://deposit-box.rnp.io/api/documents/"]];

                    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
                    [pasteboard clearContents];
                    [pasteboard setString:[webURL absoluteString] forType:NSStringPboardType];

                    NSUserNotification *publishedNotification = [[NSUserNotification alloc] init];
                    publishedNotification.title = NSLocalizedString(@"GIFSharedSuccessNotificationTitle", nil);
                    publishedNotification.informativeText = NSLocalizedString(@"GIFSharedSuccessNotificationBody", nil);
                    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:publishedNotification];
                }];
            }];
        }];
    }

	[[NSCursor currentCursor] pop];
}

@end
