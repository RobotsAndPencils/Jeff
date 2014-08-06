//
//  JEFUploaderPreferencesViewController.m
//  Jeff
//
//  Created by Brandon on 2014-03-14.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFUploaderPreferencesViewController.h"

#import <DropboxOSX/DropboxOSX.h>
#import <ServiceManagement/ServiceManagement.h>
#import <MASShortcut/MASShortcutView.h>
#import <MASShortcut/MASShortcutView+UserDefaults.h>
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authHelperStateChangedNotification:) name:DBAuthHelperOSXStateChangedNotification object:[DBAuthHelperOSX sharedHelper]];
    
    self.recordScreenShortcutView.associatedUserDefaultsKey = JEFRecordScreenShortcutKey;
    self.recordSelectionShortcutView.associatedUserDefaultsKey = JEFRecordSelectionShortcutKey;
    self.recordScreenShortcutView.appearance = MASShortcutViewAppearanceTexturedRect;
    self.recordSelectionShortcutView.appearance = MASShortcutViewAppearanceTexturedRect;
    
    NSString *htmlString = NSLocalizedString(@"PreferencesOpenSourceCreditsHTML", @"An HTML string containing open source credits");
    NSData *htmlData = [htmlString dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableAttributedString *attributedCredits = [[NSMutableAttributedString alloc] initWithHTML:htmlData documentAttributes:NULL];
    NSDictionary *attributes = @{ NSFontAttributeName : [NSFont systemFontOfSize:[NSFont systemFontSize]], NSForegroundColorAttributeName: [NSColor labelColor] };
    [attributedCredits addAttributes:attributes range:NSMakeRange(0, attributedCredits.string.length - 1)];
    self.openSourceCreditTextView.linkTextAttributes = @{ NSForegroundColorAttributeName: [NSColor labelColor], NSCursorAttributeName: [NSCursor pointingHandCursor] };
    self.openSourceCreditTextView.textStorage.attributedString = attributedCredits;

    self.dropboxLinked = [[DBSession sharedSession] isLinked];
    [self updateLinkButton];
    
    NSString *version = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    NSString *buildNumber = [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];
    self.versionLabel.stringValue = [NSString stringWithFormat:@"You've got Jeff version %@ (Build %@)", version, buildNumber];
}

- (IBAction)toggleLinkDropbox:(id)sender {
    if ([[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] unlinkAll];
        [self updateLinkButton];
    } else {
        [[DBAuthHelperOSX sharedHelper] authenticate];
    }
}

- (void)updateLinkButton {
    if ([[DBSession sharedSession] isLinked]) {
        self.linkButton.title = @"Unlink Dropbox";
    } else {
        self.linkButton.title = @"Link Dropbox";
        self.linkButton.state = [[DBAuthHelperOSX sharedHelper] isLoading] ? NSOffState : NSOnState;
    }
}

- (void)authHelperStateChangedNotification:(NSNotification *)notification {
    self.dropboxLinked = [[DBSession sharedSession] isLinked];
    [self updateLinkButton];
}

@end
