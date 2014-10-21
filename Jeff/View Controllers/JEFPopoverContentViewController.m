//
//  JEFPopoverContentViewController.m
//  Jeff
//
//  Created by Brandon Evans on 2014-07-02.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFPopoverContentViewController.h"

#import <MASShortcut/MASShortcut.h>
#import <MASShortcut/MASShortcut+UserDefaults.h>
#import "Mixpanel.h"

#import "JEFRecording.h"
#import "JEFQuartzRecorder.h"
#import "JEFRecordingsManager.h"
#import "Converter.h"
#import "JEFAppController.h"
#import "JEFSelectionOverlayWindow.h"
#import "JEFAppDelegate.h"
#import "JEFPopoverUploaderSetupViewController.h"
#import "JEFPopoverRecordingsViewController.h"
#import "JEFUploaderPreferencesViewController.h"
#import "Constants.h"

@interface JEFPopoverContentViewController () <JEFSelectionViewDelegate>

@property (weak, nonatomic) IBOutlet NSVisualEffectView *headerContainerView;
@property (weak, nonatomic) IBOutlet NSButton *recordSelectionButton;

@property (nonatomic, strong) JEFPopoverRecordingsViewController *recordingsViewController;
@property (nonatomic, strong) JEFPopoverUploaderSetupViewController *uploaderSetupViewController;
@property (nonatomic, strong) JEFUploaderPreferencesViewController *preferencesViewController;
@property (strong, nonatomic) NSWindowController *preferencesWindowController;
@property (strong, nonatomic) NSMutableArray *overlayWindows;
@property (strong, nonatomic) JEFQuartzRecorder *recorder;
@property (nonatomic, assign, getter=isShowingSetup) BOOL showingSetup;
@property (assign, nonatomic, getter=isShowingSelection) BOOL showingSelection;

@end

@implementation JEFPopoverContentViewController

#pragma mark NSViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [[DBAccountManager sharedManager] addObserver:self block:^(DBAccount *account) {
        [self updateViewControllerImmediately:NO];
    }];

    [MASShortcut registerGlobalShortcutWithUserDefaultsKey:JEFRecordScreenShortcutKey handler:^{
        [self toggleRecordingScreen];
    }];

    [MASShortcut registerGlobalShortcutWithUserDefaultsKey:JEFRecordSelectionShortcutKey handler:^{
        [self toggleRecordingSelection];
    }];

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __weak __typeof(self) weakSelf = self;
        [[NSNotificationCenter defaultCenter] addObserverForName:JEFStopRecordingNotification object:nil queue:[NSOperationQueue currentQueue] usingBlock:^(NSNotification *note) {
            [weakSelf stopRecording:nil];
        }];
    });

    self.recorder = [[JEFQuartzRecorder alloc] init];
    self.overlayWindows = [NSMutableArray array];

    self.uploaderSetupViewController = [[JEFPopoverUploaderSetupViewController alloc] init];
    [self addChildViewController:self.uploaderSetupViewController];

    self.preferencesViewController = [[JEFUploaderPreferencesViewController alloc] initWithNibName:@"JEFUploaderPreferencesView" bundle:nil];
    [self addChildViewController:self.preferencesViewController];
}

- (void)dealloc {
    [[DBAccountManager sharedManager] removeObserver:self];
}

- (void)viewDidAppear {
    [super viewDidAppear];
    [self updateViewControllerImmediately:YES];
}

- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"EmbedRecordings"]) {
        self.recordingsViewController = segue.destinationController;
        self.recordingsViewController.recordingsManager = self.recordingsManager;
        self.recordingsViewController.contentInsets = NSEdgeInsetsMake(CGRectGetHeight(self.headerContainerView.frame) - 20, 0, 0, 0);
    }
}

#pragma mark Recording

- (void)toggleRecordingScreen {
    if (!self.recorder.isRecording) {
        [self recordScreen:nil];
    }
    else {
        [self stopRecording:nil];
    }
}

- (void)toggleRecordingSelection {
    if (!self.recorder.isRecording && !self.isShowingSelection) {
        [self recordSelection:nil];
    }

    else if (!self.recorder.isRecording && self.isShowingSelection) {
        [self selectionViewDidCancel:nil];
    }
    else {
        [self stopRecording:nil];
    }

    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (void)stopRecording:(id)sender {
    if (!self.recorder.isRecording && self.isShowingSelection) {
        [self selectionViewDidCancel:nil];
        return;
    }

    [self.recorder finishRecording];
    [[NSNotificationCenter defaultCenter] postNotificationName:JEFSetStatusViewRecordingNotification object:self];
}

#pragma mark Actions

- (IBAction)showPreferencesMenu:(id)sender {
    NSViewController *currentViewController = self.isShowingSetup ? self.uploaderSetupViewController : self.recordingsViewController;
    [self transitionFromViewController:currentViewController toViewController:self.preferencesViewController options:NSViewControllerTransitionSlideBackward completionHandler:^{}];
}

- (IBAction)quit:(id)sender {
    [NSApp terminate:self];
}

- (IBAction)recordSelection:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:JEFClosePopoverNotification object:self];

    __weak __typeof(self) weakSelf = self;
    for (NSScreen *screen in [NSScreen screens]) {
        NSRect frame = [screen frame];
        JEFSelectionOverlayWindow *window = [[JEFSelectionOverlayWindow alloc] initWithContentRect:frame completion:^(JEFSelectionView *view, NSRect rect, BOOL cancelled) {
            if (!cancelled) {
                [weakSelf selectionView:view didSelectRect:rect];
            }
            else {
                [weakSelf selectionViewDidCancel:view];
            }
        }];

        [self.overlayWindows addObject:window];
    }

    [[NSCursor crosshairCursor] push];
    self.showingSelection = YES;
}

- (IBAction)recordScreen:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:JEFSetStatusViewNotRecordingNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:JEFClosePopoverNotification object:self];

    __weak __typeof(self) weakSelf = self;
    [self.recorder recordScreen:[NSScreen mainScreen] completion:^(NSURL *framesURL) {
        [Converter convertFramesAtURL:framesURL completion:^(NSURL *gifURL) {
            NSError *framesError;
            NSArray *frames = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:framesURL includingPropertiesForKeys:nil options:0 error:&framesError];
            if (!frames && framesError) {
                NSLog(@"Error fetching frames for poster frame image: %@", framesError);
            }
            NSURL *firstFrameURL = frames.firstObject;

            [weakSelf.recordingsManager uploadNewRecordingWithGIFURL:gifURL posterFrameURL:firstFrameURL completion:^(JEFRecording *recording) {
                [[Mixpanel sharedInstance] track:@"Create Recording"];
                [[[Mixpanel sharedInstance] people] increment:@"Recordings" by:@1];
            }];

            // Really don't care about removeItemAtPath:error: failing since it's in a temp directory anyways
            [[NSFileManager defaultManager] removeItemAtPath:[framesURL path] error:nil];
        }];
    }];

    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

#pragma mark Private

- (void)updateViewControllerImmediately:(BOOL)immediately {
    BOOL linked = [[DBAccountManager sharedManager] linkedAccount] != nil;

    if (linked && self.isShowingSetup) {
        NSViewControllerTransitionOptions transition = immediately ? NSViewControllerTransitionNone : NSViewControllerTransitionSlideBackward;
        __weak __typeof(self) weakSelf = self;
        [self transitionFromViewController:self.uploaderSetupViewController toViewController:self.recordingsViewController options:transition completionHandler:^() {
            [weakSelf.recordingsManager setupDropboxFilesystem];
            [self.recordingsViewController viewDidAppear]; // This shouldn't be called manually, but it's not called when it's shown. Need to investigate more to file a radar.
        }];
        self.showingSetup = NO;
    }
    else if (!linked && !self.isShowingSetup) {
        NSViewControllerTransitionOptions transition = immediately ? NSViewControllerTransitionNone : NSViewControllerTransitionSlideForward;
        [self transitionFromViewController:self.recordingsViewController toViewController:self.uploaderSetupViewController options:transition completionHandler:^() {
        }];
        self.showingSetup = YES;
    }
}

- (void)setStyleForButton:(NSButton *)button {
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [NSColor whiteColor];
    shadow.shadowOffset = CGSizeMake(0.0, 1.0);

    NSFont *font = [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSRegularControlSize]];

    NSColor *fontColor = [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];

    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paragraphStyle setAlignment:NSCenterTextAlignment];

    NSDictionary *attrsDictionary = @{ NSShadowAttributeName : shadow, NSFontAttributeName : font, NSParagraphStyleAttributeName : paragraphStyle, NSForegroundColorAttributeName : fontColor };
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:button.title ?: @"" attributes:attrsDictionary];
    [button setAttributedTitle:attrString];
}

#pragma mark JEFSelectionViewDelegate

- (void)selectionView:(JEFSelectionView *)view didSelectRect:(NSRect)rect {
    [[NSNotificationCenter defaultCenter] postNotificationName:JEFSetStatusViewNotRecordingNotification object:self];

    for (NSWindow *window in self.overlayWindows) {
        [window setIgnoresMouseEvents:YES];
    }

    // Map point into global CG coordinates.
    NSRect globalRect = CGRectOffset(rect, CGRectGetMinX(view.window.frame), CGRectGetMinY(view.window.frame));

    // Get a list of online displays with bounds that include the specified point.
    NSScreen *selectedScreen;
    for (NSScreen *screen in [NSScreen screens]) {
        if (CGRectContainsPoint([screen frame], globalRect.origin)) {
            selectedScreen = screen;
            break;
        }
    }

    if (selectedScreen) {
        // Convert Cocoa screen coordinates (bottom left) to Quartz coordinates (top left)
        CGRect localQuartzRect = rect;
        localQuartzRect.origin = CGPointMake(rect.origin.x, CGRectGetHeight(selectedScreen.frame) - CGRectGetMaxY(rect));

        [self.recorder recordRect:localQuartzRect screen:selectedScreen completion:^(NSURL *framesURL) {
            [self.overlayWindows makeObjectsPerformSelector:@selector(close)];
            [self.overlayWindows removeAllObjects];

            NSError *framesError;
            NSArray *frames = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:framesURL includingPropertiesForKeys:nil options:0 error:&framesError];
            if (!frames && framesError) {
                NSLog(@"Error fetching frames for poster frame image: %@", framesError);
            }
            NSURL *firstFrameURL = frames.firstObject;

            [Converter convertFramesAtURL:framesURL completion:^(NSURL *gifURL) {
                [self.recordingsManager uploadNewRecordingWithGIFURL:gifURL posterFrameURL:firstFrameURL completion:^(JEFRecording *recording) {
                    [[Mixpanel sharedInstance] track:@"Create Recording"];
                    [[[Mixpanel sharedInstance] people] increment:@"Recordings" by:@1];
                }];

                // Really don't care about removeItemAtPath:error: failing since it's in a temp directory anyways
                [[NSFileManager defaultManager] removeItemAtPath:[framesURL path] error:nil];
            }];
        }];
    }

    [[NSCursor currentCursor] pop];
    self.showingSelection = NO;
}

- (void)selectionViewDidCancel:(JEFSelectionView *)view {
    [[NSNotificationCenter defaultCenter] postNotificationName:JEFSetStatusViewRecordingNotification object:self];

    for (NSWindow *window in self.overlayWindows) {
        [window setIgnoresMouseEvents:YES];
    }

    [self.overlayWindows makeObjectsPerformSelector:@selector(close)];
    [self.overlayWindows removeAllObjects];
    self.showingSelection = NO;
}

@end
