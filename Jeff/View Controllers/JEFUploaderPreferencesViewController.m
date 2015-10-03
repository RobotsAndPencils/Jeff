//
//  JEFUploaderPreferencesViewController.m
//  Jeff
//
//  Created by Brandon on 2014-03-14.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFUploaderPreferencesViewController.h"

#import <Dropbox/Dropbox.h>
#import <MASShortcut/MASShortcutView.h>
#import <MASShortcut/MASShortcut.h>
#import <MASShortcut/MASShortcutView+UserDefaults.h>
#import "Mixpanel.h"
#import "Constants.h"
#import "JEFMouseEventButton.h"

@interface JEFUploaderPreferencesViewController ()

@property (nonatomic, weak) IBOutlet NSButton *linkButton;
@property (nonatomic, weak) IBOutlet NSTextField *versionLabel;
@property (nonatomic, weak) IBOutlet MASShortcutView *recordScreenShortcutView;
@property (nonatomic, weak) IBOutlet MASShortcutView *recordSelectionShortcutView;
@property (nonatomic, strong) IBOutlet NSTextView *creditTextView;
@property (nonatomic, weak) IBOutlet NSButton *emailButton;
@property (nonatomic, weak) IBOutlet NSButton *tweetButton;
@property (nonatomic, weak) IBOutlet NSTextField *dropboxLinkExplanationLabel;
@property (nonatomic, weak) IBOutlet JEFMouseEventButton *robotsAndPencilsButton;

@end

@implementation JEFUploaderPreferencesViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Initialize Dropbox link button
    __weak __typeof(self) weakSelf = self;
    [[DBAccountManager sharedManager] addObserver:self block:^(DBAccount *account) {
        [weakSelf updateLinkButton];
        [self updateLinkExplanationLabel];
    }];
    [self updateLinkButton];
    [self updateLinkExplanationLabel];

    self.robotsAndPencilsButton.mouseEnterHandler = ^(JEFMouseEventButton *button, NSEvent *theEvent) {
        if (button.isEnabled) {
            [[NSCursor pointingHandCursor] push];
        }
    };
    self.robotsAndPencilsButton.mouseExitHandler = ^(JEFMouseEventButton *button, NSEvent *theEvent) {
        if (button.isEnabled) {
            [NSCursor pop];
        }
    };

    // Initialize MASShortcut views
    self.recordScreenShortcutView.associatedUserDefaultsKey = JEFRecordScreenShortcutKey;
    self.recordSelectionShortcutView.associatedUserDefaultsKey = JEFRecordSelectionShortcutKey;
    self.recordScreenShortcutView.appearance = MASShortcutViewAppearanceTexturedRect;
    self.recordSelectionShortcutView.appearance = MASShortcutViewAppearanceTexturedRect;

    self.recordSelectionShortcutView.shortcutValueChange = ^(MASShortcutView *view) {
        NSString *keyCodeString = [view.shortcutValue.modifierFlagsString stringByAppendingString:view.shortcutValue.keyCodeString];
        if (!keyCodeString) return;
        [[Mixpanel sharedInstance] track:@"Change Shortcut" properties:@{ @"Name": @"Record Selection", @"Value": keyCodeString }];
    };
    self.recordScreenShortcutView.shortcutValueChange = ^(MASShortcutView *view) {
        NSString *keyCodeString = [view.shortcutValue.modifierFlagsString stringByAppendingString:view.shortcutValue.keyCodeString];
        if (!keyCodeString) return;
        [[Mixpanel sharedInstance] track:@"Change Shortcut" properties:@{ @"Name": @"Record Screen", @"Value": keyCodeString }];
    };

    // Initialize credit view
    self.creditTextView.string = NSLocalizedString(@"PreferencesCreditsHTML", nil);

    // Initialize version label
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *version = mainBundle.infoDictionary[@"CFBundleShortVersionString"];
    NSString *build = mainBundle.infoDictionary[@"CFBundleVersion"];

    self.versionLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"UserFacingVersionStringFormat", @"A string that takes the version and build number as strings to show to the user"), version, build];
}


- (void)viewDidAppear {
    [super viewDidAppear];

    [self updateLinkButton];
    [self updateLinkExplanationLabel];

    // Update these each time the view appears in case the user has changed the accounts that are set up
    NSSharingService *emailService = [NSSharingService sharingServiceNamed:NSSharingServiceNameComposeEmail];
    self.emailButton.enabled = emailService && [emailService canPerformWithItems:nil];

    NSSharingService *twitterService = [NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnTwitter];
    self.tweetButton.enabled = twitterService && [twitterService canPerformWithItems:nil];

    // Prefer email contact when not in release mode
#if DEBUG || BETA
    self.tweetButton.enabled = NO;
#endif
}

- (void)dealloc {
    [[DBAccountManager sharedManager] removeObserver:self];
}

#pragma mark Actions

- (IBAction)toggleLinkDropbox:(id)sender {
    DBAccountManager *accountManager = [DBAccountManager sharedManager];
    if (accountManager.linkedAccount) {
        [accountManager.linkedAccount unlink];
        [self updateLinkButton];
        [self updateLinkExplanationLabel];
    } else {
        __weak __typeof(self) weakSelf = self;
        [accountManager linkFromWindow:self.view.window withCompletionBlock:^(DBAccount *account) {
            [weakSelf updateLinkButton];
        }];
    }
}

- (IBAction)toggleLaunchAtLogin:(id)sender {
    NSButton *checkButton = (NSButton *)sender;
    [[Mixpanel sharedInstance] track:@"Toggle Launch At Login" properties:@{ @"State": @(checkButton.state) }];
}

- (IBAction)sendEmail:(id)sender {
    NSSharingService *emailService = [NSSharingService sharingServiceNamed:NSSharingServiceNameComposeEmail];
    if (!emailService || ![emailService canPerformWithItems:nil]) return;

    emailService.recipients = @[ @"jefftheapp@robotsandpencils.com" ];
    [emailService performWithItems:@[]];
}

- (IBAction)sendTweet:(id)sender {
    NSSharingService *twitterService = [NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnTwitter];
    if (!twitterService || ![twitterService canPerformWithItems:nil]) return;

    twitterService.recipients = @[ @"jefftheapp" ];
    [twitterService performWithItems:@[]];
}

- (IBAction)openOpenSourceAcknowledgements:(id)sender {
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *version = mainBundle.infoDictionary[@"CFBundleShortVersionString"];
    NSString *build = mainBundle.infoDictionary[@"CFBundleVersion"];
    NSString *formattedVersionString = [NSString stringWithFormat:@"%@b%@", version, build];

    NSURL *acknowledgementsURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://robotsandpencils.com/jeff/acknowledgements/%@.html", formattedVersionString]];
    [[NSWorkspace sharedWorkspace] openURL:acknowledgementsURL];
}

- (IBAction)quit:(id)sender {
    [NSApp terminate:self];
}

- (IBAction)showFAQ:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://robotsandpencils.com/jeff#faq"]];
}

- (IBAction)openRobotsAndPencilsHomepage:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://robotsandpencils.com"]];
}

#pragma mark Private

- (void)updateLinkButton {
    if ([DBAccountManager sharedManager].linkedAccount) {
        self.linkButton.title = @"Unlink Dropbox";
    } else {
        self.linkButton.title = @"Link Dropbox";
    }
}

- (void)updateLinkExplanationLabel {
    if ([DBAccountManager sharedManager].linkedAccount) {
        self.dropboxLinkExplanationLabel.stringValue = NSLocalizedString(@"PreferencesDropboxExplanationUnlink", @"Explains what happens when you unlink your account");
    }
    else {
        self.dropboxLinkExplanationLabel.stringValue = NSLocalizedString(@"PreferencesDropboxExplanationLink", @"Explains what happens when you link your account");
    }
}

@end
