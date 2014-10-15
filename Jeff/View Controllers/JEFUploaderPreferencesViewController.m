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

@end

@implementation JEFUploaderPreferencesViewController

- (void)loadView {
    [super loadView];

    __weak __typeof(self) weakSelf = self;
    [[DBAccountManager sharedManager] addObserver:self block:^(DBAccount *account) {
        weakSelf.dropboxLinked = account != nil;
        [weakSelf updateLinkButton];
    }];
    
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

    NSString *htmlString = NSLocalizedString(@"PreferencesOpenSourceCreditsHTML", @"An HTML string containing open source credits");
    NSData *htmlData = [htmlString dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableAttributedString *attributedCredits = [[NSMutableAttributedString alloc] initWithHTML:htmlData documentAttributes:NULL];
    NSDictionary *attributes = @{ NSFontAttributeName : [NSFont systemFontOfSize:[NSFont systemFontSize]], NSForegroundColorAttributeName: [NSColor labelColor] };
    [attributedCredits addAttributes:attributes range:NSMakeRange(0, attributedCredits.string.length - 1)];
    self.openSourceCreditTextView.linkTextAttributes = @{ NSForegroundColorAttributeName: [NSColor labelColor], NSCursorAttributeName: [NSCursor pointingHandCursor] };
    self.openSourceCreditTextView.textStorage.attributedString = attributedCredits;

    self.dropboxLinked = [[DBAccountManager sharedManager] linkedAccount] != nil;
    [self updateLinkButton];
    
    NSString *version = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    NSString *buildNumber = [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];
    self.versionLabel.stringValue = [NSString stringWithFormat:@"You've got Jeff version %@ (Build %@)", version, buildNumber];
}

- (void)dealloc {
    [[DBAccountManager sharedManager] removeObserver:self];
}

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

- (void)updateLinkButton {
    if ([[DBAccountManager sharedManager] linkedAccount]) {
        self.linkButton.title = @"Unlink Dropbox";
    } else {
        self.linkButton.title = @"Link Dropbox";
    }
}

@end
