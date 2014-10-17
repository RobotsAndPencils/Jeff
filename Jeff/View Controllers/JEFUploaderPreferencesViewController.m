//
//  JEFUploaderPreferencesViewController.m
//  Jeff
//
//  Created by Brandon on 2014-03-14.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFUploaderPreferencesViewController.h"

#import <Dropbox/Dropbox.h>
#import <ServiceManagement/ServiceManagement.h>
#import <MASShortcut/MASShortcutView.h>
#import <MASShortcut/MASShortcut.h>
#import <MASShortcut/MASShortcutView+UserDefaults.h>
#import "Mixpanel.h"
#import "Constants.h"


@interface JEFUploaderPreferencesViewController ()

@property (nonatomic, weak) IBOutlet NSButton *linkButton;
@property (nonatomic, weak) IBOutlet NSTextField *versionLabel;
@property (nonatomic, weak) IBOutlet MASShortcutView *recordScreenShortcutView;
@property (nonatomic, weak) IBOutlet MASShortcutView *recordSelectionShortcutView;
@property (nonatomic, strong) IBOutlet NSTextView *openSourceCreditTextView;
@property (nonatomic, strong) IBOutlet NSTextView *creditTextView;
@property (nonatomic, weak) IBOutlet NSButton *emailButton;
@property (nonatomic, weak) IBOutlet NSButton *tweetButton;

@end

@implementation JEFUploaderPreferencesViewController

- (void)loadView {
    [super loadView];

    // Initialize Dropbox link button
    __weak __typeof(self) weakSelf = self;
    [[DBAccountManager sharedManager] addObserver:self block:^(DBAccount *account) {
        weakSelf.dropboxLinked = account != nil;
        [weakSelf updateLinkButton];
    }];

    self.dropboxLinked = [[DBAccountManager sharedManager] linkedAccount] != nil;
    [self updateLinkButton];

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

    // Initialize rich text credit views
    [self setupTextView:self.openSourceCreditTextView withHTMLStringWithKey:@"PreferencesOpenSourceCreditsHTML"];
    [self setupTextView:self.creditTextView withHTMLStringWithKey:@"PreferencesCreditsHTML"];

    // Initialize version label
    NSString *version = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    NSString *buildNumber = [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];
    self.versionLabel.stringValue = [NSString stringWithFormat:@"You've got Jeff version %@ (Build %@)", version, buildNumber];
}


- (void)viewDidAppear {
    [super viewDidAppear];

    // Update these each time the view appears in case the user has changed the accounts that are set up
    NSSharingService *emailService = [NSSharingService sharingServiceNamed:NSSharingServiceNameComposeEmail];
    self.emailButton.enabled = emailService && [emailService canPerformWithItems:nil];

    NSSharingService *twitterService = [NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnTwitter];
    self.tweetButton.enabled = twitterService && [twitterService canPerformWithItems:nil];
}

- (void)dealloc {
    [[DBAccountManager sharedManager] removeObserver:self];
}

#pragma mark Actions

- (IBAction)toggleLinkDropbox:(id)sender {
    if ([[DBAccountManager sharedManager] linkedAccount]) {
        [[[DBAccountManager sharedManager] linkedAccount] unlink];
        [self updateLinkButton];
    } else {
        __weak __typeof(self) weakSelf = self;
        [[DBAccountManager sharedManager] linkFromWindow:self.view.window withCompletionBlock:^(DBAccount *account) {
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
    [twitterService performWithItems:nil];
}

#pragma mark Private

- (void)setupTextView:(NSTextView *)view withHTMLStringWithKey:(NSString *)key {
    NSString *htmlString = NSLocalizedString(key, nil);
    NSData *htmlData = [htmlString dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableAttributedString *attributedCredits = [[NSMutableAttributedString alloc] initWithHTML:htmlData documentAttributes:NULL];
    NSDictionary *attributes = @{ NSFontAttributeName : [NSFont systemFontOfSize:[NSFont systemFontSize]], NSForegroundColorAttributeName: [NSColor labelColor] };
    [attributedCredits addAttributes:attributes range:NSMakeRange(0, attributedCredits.string.length - 1)];
    view.linkTextAttributes = @{ NSForegroundColorAttributeName: [NSColor labelColor], NSCursorAttributeName: [NSCursor pointingHandCursor] };
    view.textStorage.attributedString = attributedCredits;

}

- (void)updateLinkButton {
    if ([[DBAccountManager sharedManager] linkedAccount]) {
        self.linkButton.title = @"Unlink Dropbox";
    } else {
        self.linkButton.title = @"Link Dropbox";
    }
}

@end
