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
#import "pop/POP.h"

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

typedef NS_ENUM(NSInteger, JEFPopoverContent) {
    JEFPopoverContentSetup = 0,
    JEFPopoverContentRecordings,
    JEFPopoverContentPreferences
};

@interface JEFPopoverContentViewController () <JEFSelectionViewDelegate>

// Header Outlets
@property (weak, nonatomic) IBOutlet NSVisualEffectView *headerContainerView;
@property (weak, nonatomic) IBOutlet NSButton *quitButton;
@property (weak, nonatomic) IBOutlet NSButton *recordSelectionButton;
@property (weak, nonatomic) IBOutlet NSImageView *rightButtonSeparatorImageView;
@property (weak, nonatomic) IBOutlet NSImageView *leftButtonSeparator;
@property (weak, nonatomic) IBOutlet NSButton *preferencesButton;
@property (weak, nonatomic) IBOutlet NSButton *backButton;
@property (weak, nonatomic) IBOutlet NSTextField *preferencesLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backButtonCenterXConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *preferencesLabelCenterXConstraint;
@property (weak, nonatomic) IBOutlet NSTextField *jeffLabel;

@property (weak, nonatomic) IBOutlet NSView *contentContainerView;

// Child View Controllers
@property (nonatomic, strong) JEFPopoverRecordingsViewController *recordingsViewController;
@property (nonatomic, strong) JEFPopoverUploaderSetupViewController *uploaderSetupViewController;
@property (nonatomic, strong) JEFUploaderPreferencesViewController *preferencesViewController;
@property (nonatomic, assign) JEFPopoverContent popoverContent;

// Recording
@property (strong, nonatomic) NSMutableArray *overlayWindows;
@property (strong, nonatomic) JEFQuartzRecorder *recorder;
@property (assign, nonatomic, getter=isShowingSelection) BOOL showingSelection;

@end

@implementation JEFPopoverContentViewController

#pragma mark NSViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Initialize properties
    self.recorder = [[JEFQuartzRecorder alloc] init];
    self.overlayWindows = [NSMutableArray array];

    // Setup observation
    [[DBAccountManager sharedManager] addObserver:self block:^(DBAccount *account) {
        JEFPopoverContent popoverContent = [self contentTypeForCurrentAccountState];
        [self updateChildViewControllerForContentType:popoverContent immediately:NO];
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

    // Setup child view controllers
    self.uploaderSetupViewController = [[JEFPopoverUploaderSetupViewController alloc] init];
    [self addChildViewController:self.uploaderSetupViewController];

    self.recordingsViewController = [[JEFPopoverRecordingsViewController alloc] initWithNibName:@"JEFPopoverRecordingsView" bundle:nil];
    self.recordingsViewController.recordingsManager = self.recordingsManager;
    self.recordingsViewController.contentInsets = NSEdgeInsetsMake(CGRectGetHeight(self.headerContainerView.frame) - 20, 0, 0, 0);
    [self addChildViewController:self.recordingsViewController];

    self.preferencesViewController = [[JEFUploaderPreferencesViewController alloc] initWithNibName:@"JEFUploaderPreferencesView" bundle:nil];
    [self addChildViewController:self.preferencesViewController];

    // Add the appropriate view as a child to begin
    self.popoverContent = [self contentTypeForCurrentAccountState];
    NSViewController *targetViewController = [self childViewControllerForContentType:self.popoverContent];
    [self.contentContainerView addSubview:targetViewController.view];

    [self updatePreferencesHeaderState:self.popoverContent immediately:YES];
}

- (void)dealloc {
    [[DBAccountManager sharedManager] removeObserver:self];
}

- (void)viewDidAppear {
    [super viewDidAppear];

    // If preferences was shown before the popover closed, keep it shown when re-opening
    if (self.popoverContent == JEFPopoverContentPreferences) return;
    // Otherwise update the type of the VC for the current account state
    JEFPopoverContent popoverContent = [self contentTypeForCurrentAccountState];
    [self updateChildViewControllerForContentType:popoverContent immediately:YES];
    [self updatePreferencesHeaderState:popoverContent immediately:YES];
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
    [self updateChildViewControllerForContentType:JEFPopoverContentPreferences immediately:NO];
}

- (IBAction)hidePreferencesMenu:(id)sender {
    JEFPopoverContent popoverContent = [self contentTypeForCurrentAccountState];
    [self updateChildViewControllerForContentType:popoverContent immediately:NO];
}

- (void)updatePreferencesHeaderState:(JEFPopoverContent)popoverContent immediately:(BOOL)immediately {
    POPBasicAnimation *quitOpacityAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    POPBasicAnimation *recordOpacityAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    POPBasicAnimation *backPositionXAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayoutConstraintConstant];
    POPBasicAnimation *preferencesLabelPositionXAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayoutConstraintConstant];
    POPBasicAnimation *backOpacityAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    POPBasicAnimation *preferencesLabelOpacityAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    POPBasicAnimation *rightButtonSeparatorOpacityAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    POPBasicAnimation *preferencesButtonOpacityAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    POPBasicAnimation *leftButtonSeparatorOpacityAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    POPBasicAnimation *jeffLabelOpacityAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];

    NSArray *animations = @[ quitOpacityAnimation, recordOpacityAnimation, backPositionXAnimation, preferencesLabelPositionXAnimation, backOpacityAnimation, preferencesLabelOpacityAnimation, rightButtonSeparatorOpacityAnimation, preferencesButtonOpacityAnimation, leftButtonSeparatorOpacityAnimation, jeffLabelOpacityAnimation ];

    if (immediately) {
        for (POPBasicAnimation *animation in animations) {
            animation.duration = 0.0;
        }
    }

    switch (popoverContent) {
        case JEFPopoverContentSetup:
            quitOpacityAnimation.toValue = @0;
            recordOpacityAnimation.toValue = @0;
            backPositionXAnimation.toValue = @38;
            preferencesLabelPositionXAnimation.toValue = @(-CGRectGetWidth(self.view.frame) / 2.0 - CGRectGetWidth(self.preferencesLabel.frame) / 2.0);
            backOpacityAnimation.toValue = @0;
            preferencesLabelOpacityAnimation.toValue = @0;
            rightButtonSeparatorOpacityAnimation.toValue = @0;
            preferencesButtonOpacityAnimation.toValue = @0;
            leftButtonSeparatorOpacityAnimation.toValue = @0;
            jeffLabelOpacityAnimation.toValue = @1;
            break;
        case JEFPopoverContentRecordings:
            quitOpacityAnimation.toValue = @0;
            recordOpacityAnimation.toValue = @1;
            backPositionXAnimation.toValue = @38;
            preferencesLabelPositionXAnimation.toValue = @(-CGRectGetWidth(self.view.frame) / 2.0 - CGRectGetWidth(self.preferencesLabel.frame) / 2.0);
            backOpacityAnimation.toValue = @0;
            preferencesLabelOpacityAnimation.toValue = @0;
            rightButtonSeparatorOpacityAnimation.toValue = @1;
            preferencesButtonOpacityAnimation.toValue = @1;
            leftButtonSeparatorOpacityAnimation.toValue = @0;
            jeffLabelOpacityAnimation.toValue = @0;
            break;
        case JEFPopoverContentPreferences:
            quitOpacityAnimation.toValue = @0;
            recordOpacityAnimation.toValue = @0;
            backPositionXAnimation.toValue = @8;
            preferencesLabelPositionXAnimation.toValue = @0;
            backOpacityAnimation.toValue = @1;
            preferencesLabelOpacityAnimation.toValue = @1;
            rightButtonSeparatorOpacityAnimation.toValue = @0;
            preferencesButtonOpacityAnimation.toValue = @0;
            leftButtonSeparatorOpacityAnimation.toValue = @1;
            jeffLabelOpacityAnimation.toValue = @0;
            break;
    }

    [self.quitButton.layer pop_addAnimation:quitOpacityAnimation forKey:@"opacity"];
    [self.recordSelectionButton.layer pop_addAnimation:recordOpacityAnimation forKey:@"opacity"];
    [self.backButtonCenterXConstraint pop_addAnimation:backPositionXAnimation forKey:@"positionX"];
    [self.preferencesLabelCenterXConstraint pop_addAnimation:preferencesLabelPositionXAnimation forKey:@"positionX"];
    [self.backButton.layer pop_addAnimation:backOpacityAnimation forKey:@"opacity"];
    [self.preferencesLabel.layer pop_addAnimation:preferencesLabelOpacityAnimation forKey:@"opacity"];
    [self.rightButtonSeparatorImageView.layer pop_addAnimation:rightButtonSeparatorOpacityAnimation forKey:@"opacity"];
    [self.preferencesButton.layer pop_addAnimation:preferencesButtonOpacityAnimation forKey:@"opacity"];
    [self.leftButtonSeparator.layer pop_addAnimation:leftButtonSeparatorOpacityAnimation forKey:@"opacity"];
    [self.jeffLabel.layer pop_addAnimation:jeffLabelOpacityAnimation forKey:@"opacity"];

    switch (popoverContent) {
        case JEFPopoverContentSetup:
            self.quitButton.enabled = NO;
            self.recordSelectionButton.enabled = YES;
            self.preferencesButton.enabled = YES;
            self.backButton.enabled = NO;
            break;
        case JEFPopoverContentRecordings:
            self.quitButton.enabled = NO;
            self.recordSelectionButton.enabled = YES;
            self.preferencesButton.enabled = YES;
            self.backButton.enabled = NO;
            break;
        case JEFPopoverContentPreferences:
            self.quitButton.enabled = NO;
            self.recordSelectionButton.enabled = NO;
            self.preferencesButton.enabled = NO;
            self.backButton.enabled = YES;
            break;
    }

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

- (void)updateChildViewControllerForContentType:(JEFPopoverContent)targetPopoverContent immediately:(BOOL)immediately {
    if (self.popoverContent == targetPopoverContent) return;

    NSViewController *currentChildViewController = [self childViewControllerForContentType:self.popoverContent];
    NSViewControllerTransitionOptions transition;

    switch (targetPopoverContent) {
        case JEFPopoverContentSetup: {
            transition = immediately ? NSViewControllerTransitionNone : NSViewControllerTransitionSlideBackward;
            [self transitionFromViewController:currentChildViewController toViewController:self.uploaderSetupViewController options:transition completionHandler:^() {}];
            self.popoverContent = JEFPopoverContentSetup;
            break;
        }
        case JEFPopoverContentRecordings: {
            switch (self.popoverContent) {
                case JEFPopoverContentSetup:
                    transition = immediately ? NSViewControllerTransitionNone : NSViewControllerTransitionSlideForward;
                    break;
                case JEFPopoverContentPreferences:
                    transition = immediately ? NSViewControllerTransitionNone : NSViewControllerTransitionSlideBackward;
                    break;
                default:
                    transition = NSViewControllerTransitionNone;
                    break;
            }

            __weak __typeof(self) weakSelf = self;
            [self transitionFromViewController:currentChildViewController toViewController:self.recordingsViewController options:transition completionHandler:^() {
                [weakSelf.recordingsManager setupDropboxFilesystem];
                [self.recordingsViewController viewDidAppear]; // This shouldn't be called manually, but it's not called when it's shown. Need to investigate more to file a radar.
            }];

            self.popoverContent = JEFPopoverContentRecordings;
            break;
        }
        case JEFPopoverContentPreferences: {
            transition = immediately ? NSViewControllerTransitionNone : NSViewControllerTransitionSlideForward;
            [self transitionFromViewController:currentChildViewController toViewController:self.preferencesViewController options:transition completionHandler:^() {}];
            self.popoverContent = JEFPopoverContentPreferences;
            break;
        }
    }

    [self updatePreferencesHeaderState:targetPopoverContent immediately:immediately];
}

- (NSViewController *)childViewControllerForContentType:(JEFPopoverContent)popoverContent {
    switch (popoverContent) {
        case JEFPopoverContentSetup:
            return self.uploaderSetupViewController;
        case JEFPopoverContentRecordings:
            return self.recordingsViewController;
        case JEFPopoverContentPreferences:
            return self.preferencesViewController;
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

- (JEFPopoverContent)contentTypeForCurrentAccountState {
    BOOL linked = ([[DBAccountManager sharedManager] linkedAccount] != nil);
    JEFPopoverContent popoverContent;

    if (linked) {
        popoverContent = JEFPopoverContentRecordings;
    }
    else {
        popoverContent = JEFPopoverContentSetup;
    }
    return popoverContent;
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
