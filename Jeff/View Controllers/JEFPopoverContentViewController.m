//
//  JEFPopoverContentViewController.m
//  Jeff
//
//  Created by Brandon Evans on 2014-07-02.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFPopoverContentViewController.h"

#import <QuartzCore/CAMediaTimingFunction.h>
#import <MASShortcut/MASShortcut.h>
#import <MASShortcut/MASShortcut+UserDefaults.h>
#import "Mixpanel.h"
#import "pop/POP.h"
#import "pop/POPCGUtils.h"

#import "JEFRecording.h"
#import "JEFQuartzRecorder.h"
#import "JEFRecordingsManager.h"
#import "JEFConverter.h"
#import "JEFAppController.h"
#import "JEFSelectionOverlayWindow.h"
#import "JEFAppDelegate.h"
#import "JEFPopoverUploaderSetupViewController.h"
#import "JEFPopoverRecordingsViewController.h"
#import "JEFUploaderPreferencesViewController.h"
#import "Constants.h"
#import "JEFColoredButton.h"
#import "RBKCommonUtils.h"
#import "JEFRecordingsTableViewDataSource.h"

typedef NS_ENUM(NSInteger, JEFPopoverContent) {
    JEFPopoverContentSetup = 0,
    JEFPopoverContentRecordings,
    JEFPopoverContentPreferences
};

@interface JEFPopoverContentViewController ()

// Header Outlets
@property (weak, nonatomic) IBOutlet NSVisualEffectView *headerContainerView;
@property (weak, nonatomic) IBOutlet JEFColoredButton *recordSelectionButton;
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
@property (assign, nonatomic, getter=isShowingSelection) BOOL showingSelection;
@property (strong, nonatomic) id stopRecordingObserver;

@end

@implementation JEFPopoverContentViewController

#pragma mark NSViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Initialize properties
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

    __weak __typeof(self) weakSelf = self;
    self.stopRecordingObserver = [[NSNotificationCenter defaultCenter] addObserverForName:JEFStopRecordingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [weakSelf stopRecording:nil];
    }];

    self.recordSelectionButton.backgroundColor = [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:0.5];
    self.recordSelectionButton.cornerRadius = CGRectGetHeight(self.recordSelectionButton.frame) / 2.0;
    [self setStyleForButton:self.recordSelectionButton];

    // Setup child view controllers
    self.uploaderSetupViewController = [[JEFPopoverUploaderSetupViewController alloc] init];
    [self addChildViewController:self.uploaderSetupViewController];

    self.recordingsViewController = [[JEFPopoverRecordingsViewController alloc] initWithNibName:@"JEFPopoverRecordingsView" bundle:nil];
    self.recordingsViewController.recordingsManager = self.recordingsManager;
    self.recordingsViewController.recordingsTableViewDataSource = [[JEFRecordingsTableViewDataSource alloc] initWithRepo:self.recordingsManager];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self.stopRecordingObserver];
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
    POPBasicAnimation *recordOpacityAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    POPBasicAnimation *backPositionXAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayoutConstraintConstant];
    POPBasicAnimation *preferencesLabelPositionXAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayoutConstraintConstant];
    POPBasicAnimation *backOpacityAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    POPBasicAnimation *preferencesLabelOpacityAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    POPBasicAnimation *preferencesButtonOpacityAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    POPBasicAnimation *jeffLabelOpacityAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];

    NSArray *animations = @[ recordOpacityAnimation, backPositionXAnimation, preferencesLabelPositionXAnimation, backOpacityAnimation, preferencesLabelOpacityAnimation, preferencesButtonOpacityAnimation, jeffLabelOpacityAnimation ];

    if (immediately) {
        for (POPBasicAnimation *animation in animations) {
            animation.duration = 0.0;
        }
    }

    switch (popoverContent) {
        case JEFPopoverContentSetup:
            recordOpacityAnimation.toValue = @0;
            backPositionXAnimation.toValue = @38;
            preferencesLabelPositionXAnimation.toValue = @(-CGRectGetWidth(self.view.frame) / 2.0 - CGRectGetWidth(self.preferencesLabel.frame) / 2.0);
            backOpacityAnimation.toValue = @0;
            preferencesLabelOpacityAnimation.toValue = @0;
            preferencesButtonOpacityAnimation.toValue = @0;
            jeffLabelOpacityAnimation.toValue = @1;
            break;
        case JEFPopoverContentRecordings:
            recordOpacityAnimation.toValue = @1;
            backPositionXAnimation.toValue = @38;
            preferencesLabelPositionXAnimation.toValue = @(-CGRectGetWidth(self.view.frame) / 2.0 - CGRectGetWidth(self.preferencesLabel.frame) / 2.0);
            backOpacityAnimation.toValue = @0;
            preferencesLabelOpacityAnimation.toValue = @0;
            preferencesButtonOpacityAnimation.toValue = @1;
            jeffLabelOpacityAnimation.toValue = @0;
            break;
        case JEFPopoverContentPreferences:
            recordOpacityAnimation.toValue = @0;
            backPositionXAnimation.toValue = @8;
            preferencesLabelPositionXAnimation.toValue = @0;
            backOpacityAnimation.toValue = @1;
            preferencesLabelOpacityAnimation.toValue = @1;
            preferencesButtonOpacityAnimation.toValue = @0;
            jeffLabelOpacityAnimation.toValue = @0;
            break;
    }

    [self.recordSelectionButton.layer pop_addAnimation:recordOpacityAnimation forKey:@"opacity"];
    [self.backButtonCenterXConstraint pop_addAnimation:backPositionXAnimation forKey:@"positionX"];
    [self.preferencesLabelCenterXConstraint pop_addAnimation:preferencesLabelPositionXAnimation forKey:@"positionX"];
    [self.backButton.layer pop_addAnimation:backOpacityAnimation forKey:@"opacity"];
    [self.preferencesLabel.layer pop_addAnimation:preferencesLabelOpacityAnimation forKey:@"opacity"];
    [self.preferencesButton.layer pop_addAnimation:preferencesButtonOpacityAnimation forKey:@"opacity"];
    [self.jeffLabel.layer pop_addAnimation:jeffLabelOpacityAnimation forKey:@"opacity"];

    switch (popoverContent) {
        case JEFPopoverContentSetup:
            self.recordSelectionButton.enabled = YES;
            self.preferencesButton.enabled = YES;
            self.backButton.enabled = NO;
            break;
        case JEFPopoverContentRecordings:
            self.recordSelectionButton.enabled = YES;
            self.preferencesButton.enabled = YES;
            self.backButton.enabled = NO;
            break;
        case JEFPopoverContentPreferences:
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
        NSRect frame = screen.frame;
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
        [JEFConverter convertFramesAtURL:framesURL completion:^(NSURL *gifURL) {
            NSError *framesError;
            NSArray *frames = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:framesURL includingPropertiesForKeys:nil options:0 error:&framesError];
            if (!frames && framesError) {
                RBKLog(@"Error fetching frames for poster frame image: %@", framesError);
            }
            NSURL *firstFrameURL = frames.firstObject;

            [weakSelf.recordingsManager uploadNewRecordingWithGIFURL:gifURL posterFrameURL:firstFrameURL completion:^(JEFRecording *recording) {
                [[Mixpanel sharedInstance] track:@"Create Recording"];
                [[Mixpanel sharedInstance].people increment:@"Recordings" by:@1];
            }];

            // Really don't care about removeItemAtPath:error: failing since it's in a temp directory anyways
            [[NSFileManager defaultManager] removeItemAtPath:framesURL.path error:nil];
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
            [self transitionFromViewController:currentChildViewController toViewController:self.uploaderSetupViewController options:transition completionHandler:nil];
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
            [self transitionFromViewController:currentChildViewController toViewController:self.preferencesViewController options:transition completionHandler:nil];
            self.popoverContent = JEFPopoverContentPreferences;
            break;
        }
    }

    [self updatePreferencesHeaderState:targetPopoverContent immediately:immediately];
}

/**
 *  This API is great at first but the animation is really slow and you can't change it, so here we are overriding it.
 *  I only care about the options that I'm using, so don't pass crossfade and expect it to work.
 *  Oh, and this one will accept nil completion blocks (!?)
 *
 *  @param fromViewController
 *  @param toViewController
 *  @param options
 *  @param completion
 */
- (void)transitionFromViewController:(NSViewController *)fromViewController toViewController:(NSViewController *)toViewController options:(NSViewControllerTransitionOptions)options completionHandler:(void (^)(void))completion {
    // Pop only comes with layer support for OS X, and we can't animate the layer position because we'd lose interactivity, so make an animatable property for the view's origin
    POPAnimatableProperty *viewOriginAnimatableProperty = [POPAnimatableProperty propertyWithName:@"frame.origin" initializer:^(POPMutableAnimatableProperty *prop) {
        prop.readBlock = ^(NSView *obj, CGFloat values[]) {
            values_from_point(values, obj.frame.origin);
        };
        prop.writeBlock = ^(NSView *obj, const CGFloat values[]) {
            CGRect frame = obj.frame;
            frame.origin.x = values[0];
            frame.origin.y = values[1];
            obj.frame = frame;
        };
        prop.threshold = 0.01;
    }];

    // Here we're figuring out what the initial and final positions for the two views should be
    // This is hard-coded for position animations, but it should support RTL and LTR UI
    CGFloat fromViewToOffset = 0;
    switch (options) {
        case NSViewControllerTransitionSlideBackward:
            if ([NSApp userInterfaceLayoutDirection] == NSUserInterfaceLayoutDirectionLeftToRight) {
                toViewController.view.frame = CGRectOffset(fromViewController.view.frame, -CGRectGetWidth(fromViewController.view.frame), 0);
                fromViewToOffset = CGRectGetWidth(fromViewController.view.frame);
            }
            else {
                toViewController.view.frame = CGRectOffset(fromViewController.view.frame, CGRectGetWidth(fromViewController.view.frame), 0);
                fromViewToOffset = -CGRectGetWidth(fromViewController.view.frame);
            }
            break;
        case NSViewControllerTransitionSlideForward:
            if ([NSApp userInterfaceLayoutDirection] == NSUserInterfaceLayoutDirectionLeftToRight) {
                toViewController.view.frame = CGRectOffset(fromViewController.view.frame, CGRectGetWidth(fromViewController.view.frame), 0);
                fromViewToOffset = -CGRectGetWidth(fromViewController.view.frame);
            }
            else {
                toViewController.view.frame = CGRectOffset(fromViewController.view.frame, -CGRectGetWidth(fromViewController.view.frame), 0);
                fromViewToOffset = CGRectGetWidth(fromViewController.view.frame);
            }
            break;
        default:
            break;
    }
    [fromViewController.view.superview addSubview:toViewController.view];

    POPBasicAnimation *fromViewPositionAnimation = [POPBasicAnimation animation];
    fromViewPositionAnimation.property = viewOriginAnimatableProperty;
    fromViewPositionAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(fromViewToOffset, 0)];
    if (options == NSViewControllerTransitionNone) {
        fromViewPositionAnimation.duration = 0.0;
    }
    [fromViewController.view pop_addAnimation:fromViewPositionAnimation forKey:@"positionX"];

    POPBasicAnimation *toViewPositionAnimation = [POPBasicAnimation animation];
    toViewPositionAnimation.property = viewOriginAnimatableProperty;
    toViewPositionAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(0, 0)];
    if (options == NSViewControllerTransitionNone) {
        toViewPositionAnimation.duration = 0.0;
    }
    toViewPositionAnimation.completionBlock = ^(POPAnimation *animation, BOOL finished) {
        [fromViewController.view removeFromSuperview];
        if (completion) completion();
    };
    [toViewController.view pop_addAnimation:toViewPositionAnimation forKey:@"positionX"];
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
    shadow.shadowColor = [[NSColor whiteColor] colorWithAlphaComponent:0.25];
    shadow.shadowOffset = CGSizeMake(0.0, -1.0);

    NSFont *font = [NSFont boldSystemFontOfSize:[NSFont systemFontSizeForControlSize:NSRegularControlSize]];
    NSColor *fontColor = [NSColor labelColor];

    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.alignment = NSCenterTextAlignment;

    NSDictionary *attrsDictionary = @{ NSShadowAttributeName : shadow, NSFontAttributeName : font, NSParagraphStyleAttributeName : paragraphStyle, NSForegroundColorAttributeName : fontColor };
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:button.title ?: @"" attributes:attrsDictionary];
    button.attributedTitle = attrString;
}

- (JEFPopoverContent)contentTypeForCurrentAccountState {
    BOOL linked = ([DBAccountManager sharedManager].linkedAccount != nil);
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
        window.ignoresMouseEvents = YES;
    }

    // Map point into global CG coordinates.
    NSRect globalRect = CGRectOffset(rect, CGRectGetMinX(view.window.frame), CGRectGetMinY(view.window.frame));

    // Get a list of online displays with bounds that include the specified point.
    NSScreen *selectedScreen;
    for (NSScreen *screen in [NSScreen screens]) {
        if (CGRectContainsPoint(screen.frame, globalRect.origin)) {
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
                RBKLog(@"Error fetching frames for poster frame image: %@", framesError);
            }
            NSURL *firstFrameURL = frames.firstObject;

            [JEFConverter convertFramesAtURL:framesURL completion:^(NSURL *gifURL) {
                [self.recordingsManager uploadNewRecordingWithGIFURL:gifURL posterFrameURL:firstFrameURL completion:^(JEFRecording *recording) {
                    [[Mixpanel sharedInstance] track:@"Create Recording"];
                    [[Mixpanel sharedInstance].people increment:@"Recordings" by:@1];
                }];

                // Really don't care about removeItemAtPath:error: failing since it's in a temp directory anyways
                [[NSFileManager defaultManager] removeItemAtPath:framesURL.path error:nil];
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
